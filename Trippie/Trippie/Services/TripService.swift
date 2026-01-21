//
//  TripService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

class TripService {
    static let shared = TripService()
    private let db = Firestore.firestore()
    
    
    // MARK: - FETCH TRIPS FEEDING BOARD
    func fetchTripForFeedingList(tripType: TripType? = nil, country: String? = nil, searchText: String? = nil) async throws -> [Trip] {
        let now = Date()
        
        // 1. Get trip in future
        var query: Query = db.collection("trips").whereField("startTime", isGreaterThan: now)
        
        // 2. FILTER: TripType
        if let type = tripType {
            query = query.whereField("tripType", isEqualTo: type.rawValue)
        }
        
        // 3. FILTER: Location
        if let c = country, !c.isEmpty {
            query = query.whereField("country", isEqualTo: c)
        }
        
        // 4. Async
        let snapshot = try await query.getDocuments()
        
        // 5. DECODE -> model Trip
        var trips = snapshot.documents.compactMap { doc -> Trip? in
            return try? doc.data(as: Trip.self)
        }
        
        // 6. CLIENT-SIDE FILTER
        trips = trips.filter { trip in
            let isValidStatus = (trip.status != .completed)
            
            // B. Logic Search Text
            // search title location country
            var matchesSearch = true
            if let text = searchText, !text.isEmpty {
                let queryText = text.lowercased()
                matchesSearch = trip.title.lowercased().contains(queryText) ||
                trip.location.lowercased().contains(queryText) ||
                trip.country.lowercased().contains(queryText)
            }
            
            return isValidStatus && matchesSearch
        }
        
        // 7. SORT: Latest trip
        return trips.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - FETCH MY TRIPS (JOIN TABLE)
    func fetchMyTrips(userId: String) async throws -> [TripWithStatus] {
        
        // BƯỚC 1: Lấy danh sách Participation về trước
        // (Để tí nữa biết Trip nào là Ongoing, cái nào Completed...)
        let partSnapshot = try await db.collection("participations")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let myParticipations = partSnapshot.documents.compactMap { try? $0.data(as: Participation.self) }
        
        
        // BƯỚC 2: Lấy Trip (Chia làm 2 luồng tìm kiếm)
        
        // Luồng A: Tìm trip mình làm Chủ (Owner)
        let ownerSnapshot = try await db.collection("trips")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments()
        let ownerTrips = ownerSnapshot.documents.compactMap { try? $0.data(as: Trip.self) }
        
        // Luồng B: Tìm trip mình là Thành viên (nằm trong mảng members)
        let memberSnapshot = try await db.collection("trips")
            .whereField("members", arrayContains: userId)
            .getDocuments()
        let memberTrips = memberSnapshot.documents.compactMap { try? $0.data(as: Trip.self) }
        
        
        // BƯỚC 3: Gộp Trips lại và Xóa trùng
        // (Phòng trường hợp data lỗi: Mình vừa là Owner vừa có tên trong Member)
        var allTrips = ownerTrips + memberTrips
        
        // Mẹo xoá trùng Trip theo ID đơn giản:
        // Gom vào Dictionary theo ID, rồi lấy value ra
        let uniqueTrips = Array(Dictionary(grouping: allTrips, by: { $0.id }).values.compactMap { $0.first })
        
        
        // BƯỚC 4: Ghép "Trip" + "Status" lại với nhau
        var results: [TripWithStatus] = []
        
        for trip in uniqueTrips {
            // Tìm xem trip này ứng với cái Participation nào ở Bước 1
            if let matchPart = myParticipations.first(where: { $0.tripId == trip.id }) {
                
                // Ghép lại thành cục dữ liệu hoàn chỉnh
                let item = TripWithStatus(trip: trip, participation: matchPart)
                results.append(item)
            }
        }
        
        // Sắp xếp: Trip nào mới nhất lên đầu
        return results.sorted { $0.trip.startTime < $1.trip.startTime }
    }
    
    
    
    //MARK: - 1. CREATE TRIP ( Trip + Participation Owner)
    func createTrip(trip: Trip) async throws {
        // A. Tạo Document Reference mới (để lấy ID trước)
        let newTripRef = db.collection("trips").document()
        let newId = newTripRef.documentID
        
        // B. Copy trip cũ và gán ID mới vào
        var newTrip = trip
        newTrip.id = newId
        newTrip.createdAt = Date() // Gán ngày tạo local tạm thời
        
        // C. Lưu Trip lên Server
        try newTripRef.setData(from: newTrip)
        
        // D. QUAN TRỌNG: Tạo Participation cho Owner
        // Để nó hiện trong danh sách "My Trips"
        let ownerPart = Participation(
            id: nil,
            userId: trip.ownerId,
            tripId: newId,
            personalStatus: PersonalStatus.upcoming,
            role: UserRole.owner
        )
        
        // Lưu Participation
        try db.collection("participations").addDocument(from: ownerPart)
    }
    
    
    
    //MARK: - 2. UPDATE TRIP
    func updateTrip(trip: Trip) async throws {
        guard let tripId = trip.id else { return }
        
        // Cập nhật field updatedAt để server biết
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        // Ghi đè dữ liệu mới vào ID cũ
        // merge: true -> Chỉ update những field có thay đổi (An toàn hơn)
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
    }
    
    
    
    //MARK: - 3. DELETE TRIP (Xoá Trip + Xoá lun Participation)
    func deleteTrip(tripId: String) async throws {
        // A. Xoá Trip chính
        try await db.collection("trips").document(tripId).delete()
        
        // B. Dọn dẹp: Xoá tất cả Participation liên quan đến Trip này
        let partSnapshot = try await db.collection("participations")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments()
        
        // Duyệt qua và xoá từng cái
        for doc in partSnapshot.documents {
            try await doc.reference.delete()
        }
    }
    
    
    //MARK: - 4. JOIN TRIP (CREATE PARTICIPATION)
    func acceptJoinTrip(userId: String, trip: Trip) async throws {
        guard let tripId = trip.id else {return}
        
        var updatedTrip = trip
        updatedTrip.members.append(userId)
        updatedTrip.currentMember += 1
        if updatedTrip.currentMember == updatedTrip.maxMember && updatedTrip.status != TripStatus.completed {
            updatedTrip.status = TripStatus.full
        }
        updatedTrip.pendingRequests.removeAll(where: {$0 == userId})
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        let joinPart = Participation(
            id: nil,
            userId: userId,
            tripId: tripId,
            personalStatus: PersonalStatus.upcoming,
            role: UserRole.member
        )
        
        try db.collection("participations").addDocument(from: joinPart)
    }
    
    
    //MARK: - 5. DENY JOIN TRIP (DELETE USERID IN PENDING-REQUESTS)
    func denyJoinTrip(userId: String, trip: Trip) async throws {
        guard let tripId = trip.id else {return}
        
        var updatedTrip = trip
        updatedTrip.pendingRequests.removeAll(where: {$0 == userId})
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
    }
    
    
    //MARK: - 6. KICK MEMBER FROM TRIP (DELETE PARTICIPATION)
    func kickMemberInTrip(userId: String, trip: Trip) async throws {
        guard let tripId = trip.id else {return}
        
        var updatedTrip = trip
        updatedTrip.members.removeAll(where: {$0 == userId})
        updatedTrip.currentMember -= 1
        if updatedTrip.currentMember == updatedTrip.maxMember && updatedTrip.status != TripStatus.completed {
            updatedTrip.status = TripStatus.recruiting
        }
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        let partSnapshot = try await db.collection("participations")
            .whereField("tripId", isEqualTo: tripId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for doc in partSnapshot.documents {
            try await doc.reference.delete()
        }
    }
    
    
    //MARK: - 7. TAKE TRIP DOWN FORM FEED LIST
    func completedTrip(trip: Trip) async throws {
        guard let tripId = trip.id else {return}
        
        var updatedTrip = trip
        updatedTrip.status = TripStatus.completed
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
    }
}
