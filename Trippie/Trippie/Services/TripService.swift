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
        let allTrips = ownerTrips + memberTrips
        
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
    
    
    
    // MARK: - 1. CREATE TRIP (Input: TripWithStatus -> Output: TripWithStatus)
    func createTrip(input: TripWithStatus) async throws -> TripWithStatus {
        // 1. Tách Trip từ input ra để xử lý
        var newTrip = input.trip
        
        // 2. Tạo ID mới
        let newTripRef = db.collection("trips").document()
        let newId = newTripRef.documentID
        
        // 3. Gán ID và ngày tạo
        newTrip.id = newId
        newTrip.createdAt = Date() // Set giờ server (local)
        
        // 4. Lưu Trip
        try newTripRef.setData(from: newTrip)
        
        // 5. Xử lý Participation (Owner)
        var ownerPart = Participation(
            id: nil,
            userId: newTrip.ownerId,
            tripId: newId, // Link với ID vừa tạo
            personalStatus: .upcoming,
            role: .owner
        )
        
        // 6. Lưu Participation và lấy ID của nó (để trả về chuẩn nhất)
        let partRef = db.collection("participations").document()
        ownerPart.id = partRef.documentID // Gán ID cho participation luôn
        try partRef.setData(from: ownerPart)
        
        // 7. Trả về cục data hoàn chỉnh đã có ID
        return TripWithStatus(trip: newTrip, participation: ownerPart)
    }
    
    
    // MARK: - 2. UPDATE TRIP (Input: TripWithStatus -> Output: TripWithStatus)
    func updateTrip(input: TripWithStatus) async throws -> TripWithStatus {
        // 1. Check ID
        let trip = input.trip
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        // 2. Cập nhật Trip
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        // 3. Ghi đè lên Server
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        // 4. Trả về cục data đã update
        // Lưu ý: Participation thường không đổi khi edit thông tin chuyến đi, nên giữ nguyên từ input
        return TripWithStatus(trip: updatedTrip, participation: input.participation)
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
    
    
    // MARK: - 4. JOIN TRIP (ACCEPT MEMBER)
    // Input: UserId người xin vào, Trip hiện tại
    // Output: Trip mới đã cập nhật danh sách member
    func acceptJoinTrip(userId: String, trip: Trip) async throws -> Trip {
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        var updatedTrip = trip
        
        // 1. Logic thêm member
        if !updatedTrip.members.contains(userId) {
            updatedTrip.members.append(userId)
            updatedTrip.currentMember += 1
        }
        
        // 2. Logic check Full
        // Nếu số lượng hiện tại >= max -> Đổi trạng thái thành Full (nếu chưa hoàn thành)
        if updatedTrip.currentMember >= updatedTrip.maxMember && updatedTrip.status != .completed {
            updatedTrip.status = .full
        }
        
        // 3. Xoá khỏi danh sách chờ
        updatedTrip.pendingRequests.removeAll(where: { $0 == userId })
        
        // 4. Lưu Trip
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        // 5. Tạo Participation cho người vừa được duyệt
        let joinPart = Participation(
            id: nil,
            userId: userId,
            tripId: tripId,
            personalStatus: .upcoming,
            role: .member
        )
        // Fire & Forget (hoặc await nếu muốn chắc chắn 100%)
        try db.collection("participations").addDocument(from: joinPart)
        
        return updatedTrip
    }
    
    
    // MARK: - 5. DENY JOIN TRIP
    func denyJoinTrip(userId: String, trip: Trip) async throws -> Trip {
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        var updatedTrip = trip
        // Chỉ cần xoá khỏi pending list
        updatedTrip.pendingRequests.removeAll(where: { $0 == userId })
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        return updatedTrip
    }
    
    
    // MARK: - 6. KICK MEMBER
    func kickMemberInTrip(userId: String, trip: Trip) async throws -> Trip {
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        var updatedTrip = trip
        
        // 1. Xoá member và giảm count
        if updatedTrip.members.contains(userId) {
            updatedTrip.members.removeAll(where: { $0 == userId })
            updatedTrip.currentMember -= 1
        }
        
        // 2. Logic check trạng thái:
        // Đang FULL mà kick bớt người -> Trở về RECRUITING (để tuyển người khác)
        if updatedTrip.status == .full && updatedTrip.status != .completed {
            updatedTrip.status = .recruiting
        }
        
        // 3. Update Trip
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        // 4. Xoá Participation của người bị kick
        // Query tìm document participation của user đó trong trip này
        let partSnapshot = try await db.collection("participations")
            .whereField("tripId", isEqualTo: tripId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for doc in partSnapshot.documents {
            try await doc.reference.delete()
        }
        
        return updatedTrip
    }
    
    
    // MARK: - 7. COMPLETE TRIP
    func completedTrip(trip: Trip) async throws -> Trip {
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        var updatedTrip = trip
        updatedTrip.status = .completed
        
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        return updatedTrip
    }
    
    //MARK: - 8. UPDATE TRIP PERSONAL STATUS
    func changePersonalStatus(participation: Participation) async throws -> Participation {
        
        // 1. QUAN TRỌNG: Phải dùng ID của Participation (partId), KHÔNG PHẢI tripId
        guard let partId = participation.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Participation ID not found"])
        }
        
        // 2. Tạo reference đến đúng document đó
        let docRef = db.collection("participations").document(partId)
        
        // 3. Ghi đè (Merge)
        // Lưu ý: Chỉ cần update field status, nhưng setData merge sẽ tự lo việc đó
        try docRef.setData(from: participation, merge: true)
        
        // 4. Trả về chính object đó để ViewModel update UI
        return participation
    }
    
    // MARK: - 9. LEAVE TRIP (Rời khỏi chuyến đi)
    // Input: TripWithStatus (chứa thông tin user và trip hiện tại)
    // Output: Trip (đã cập nhật số lượng thành viên)
    func leaveTrip(input: TripWithStatus) async throws -> Trip {
        var updatedTrip = input.trip
        let userId = input.participation.userId
        
        guard let tripId = updatedTrip.id, let partId = input.participation.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ID not found"])
        }
        
        
        // 1. Xoá khỏi Members (Nếu đã là thành viên)
        if updatedTrip.members.contains(userId) {
            updatedTrip.members.removeAll { $0 == userId }
            updatedTrip.currentMember -= 1
            
            // Logic: Nếu đang FULL mà có người rời đi -> Quay về trạng thái tuyển thành viên
            if updatedTrip.status == .full {
                updatedTrip.status = .recruiting
            }
        }
        
        // 2. Update Trip lên Server
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        // 3. Xoá Participation tương ứng
        try await db.collection("participations").document(partId).delete()
        
        return updatedTrip
    }
    
    // MARK: - 10. CANCEL JOIN REQUEST (Huỷ xin vào khi đang Pending)
    // Input: TripId và UserId
    // Output: Trip (đã xoá tên khỏi pending)
    func cancelJoinRequest(tripId: String, userId: String) async throws -> Trip {
        
        // 1. Lấy dữ liệu Trip mới nhất về để đảm bảo tính toàn vẹn
        let docRef = db.collection("trips").document(tripId)
        let snapshot = try await docRef.getDocument()
        
        guard var trip = try? snapshot.data(as: Trip.self) else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])
        }
        
        // 2. Xoá user khỏi danh sách Pending
        if trip.pendingRequests.contains(userId) {
            trip.pendingRequests.removeAll { $0 == userId }
        } else {
            // Nếu server không có tên mình trong pending (có thể đã bị từ chối hoặc được duyệt rồi)
            // Thì cứ trả về trip hiện tại, không lỗi
            return trip
        }
        
        // 3. Lưu lại
        try docRef.setData(from: trip, merge: true)
        
        return trip
    }
}
