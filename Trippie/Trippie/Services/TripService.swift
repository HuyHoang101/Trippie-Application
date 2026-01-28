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
    
    
    
    // MARK: - 1. CREATE TRIP (Input: Trip -> Output: TripWithStatus)
    func createTrip(trip: Trip) async throws -> TripWithStatus {
        // 1. Copy trip đầu vào ra biến mới để sửa đổi (vì struct là value type)
        var newTrip = trip
        
        // 2. Tạo Reference và ID mới cho Trip
        let newTripRef = db.collection("trips").document()
        let newTripId = newTripRef.documentID
        
        // 3. Gán các thông tin hệ thống (ID, Time)
        newTrip.id = newTripId
        newTrip.createdAt = Date() // Gán giờ local để UI hiện ngay lập tức
        newTrip.updatedAt = Date()
        
        // 4. Lưu Trip lên Firestore
        try newTripRef.setData(from: newTrip)
        
        // 5. Tự động tạo Participation cho người tạo (Owner)
        var ownerParticipation = Participation(
            id: nil, // ID sẽ được gán ở bước sau
            userId: newTrip.ownerId,
            tripId: newTripId, // Link với ID trip vừa tạo
            personalStatus: .upcoming, // Mặc định là sắp diễn ra
            role: .owner // Vai trò chắc chắn là Owner
        )
        
        // 6. Lưu Participation lên Firestore
        let partRef = db.collection("participations").document()
        ownerParticipation.id = partRef.documentID // Gán ID để trả về object đầy đủ
        try partRef.setData(from: ownerParticipation)
        
        // 7. Gói lại thành TripWithStatus để trả về cho UI dùng luôn
        return TripWithStatus(trip: newTrip, participation: ownerParticipation)
    }
    
    
    // MARK: - 2. UPDATE TRIP (Input: Trip -> Output: TripWithStatus)
    func updateTrip(trip: Trip) async throws -> TripWithStatus {
        // 1. Kiểm tra ID chuyến đi (Bắt buộc phải có để update)
        guard let tripId = trip.id else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip ID not found"])
        }
        
        // 2. Cập nhật thời gian sửa đổi
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        // 3. Ghi đè dữ liệu mới lên Server (Merge = true để chỉ update trường thay đổi nếu cần)
        try db.collection("trips").document(tripId).setData(from: updatedTrip, merge: true)
        
        // 4. LẤY PARTICIPATION CỦA OWNER (Bước quan trọng)
        
        let snapshot = try await db.collection("participations")
            .whereField("tripId", isEqualTo: tripId)
            .whereField("userId", isEqualTo: updatedTrip.ownerId)
            .limit(to: 1) // Chỉ lấy 1 cái duy nhất
            .getDocuments()
        
        guard let participationDoc = snapshot.documents.first,
              let ownerParticipation = try? participationDoc.data(as: Participation.self) else {
            // Trường hợp hiếm: Trip tồn tại mà không tìm thấy Owner Participation -> Báo lỗi
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Owner Participation not found"])
        }
        
        // 5. Ghép lại và trả về
        return TripWithStatus(trip: updatedTrip, participation: ownerParticipation)
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
    
    // MARK: - SEED DATA GENERATOR
    func seedTrips() async {
        guard let ownerId = AuthService.shared.currentUserId else {
            print("❌ Lỗi: Chưa đăng nhập, không lấy được OwnerId")
            return
        }
        
        // 1. Bộ dữ liệu chuẩn (Location - Country - Image đi kèm nhau)
        let destinations: [(loc: String, country: String, img: String)] = [
            ("Ha Long Bay", "Vietnam", "https://images.vietnamtourism.gov.vn/en/images/2023/cnn5.jpg"),
            ("Kyoto", "Japan", "https://www.pelago.com/img/destinations/kyoto/1129-0642_kyoto-xlarge.webp"),
            ("Paris", "France", "https://res.klook.com/image/upload/fl_lossy.progressive,q_60/Mobile/City/swox6wjsl5ndvkv5jvum.jpg"),
            ("Bali", "Indonesia", "https://trieuhaotravel.vn/Uploads/images/Ulun_Danu.jpg"),
            ("Santorini", "Greece", "https://sothebysrealty.gr/wp-content/uploads/2016/11/Santorini-sunset-at-dawn-Greece-Sothebys-International-Realty.jpg"),
            ("New York", "USA", "https://i.natgeofe.com/k/5b396b5e-59e7-43a6-9448-708125549aa1/new-york-statue-of-liberty.jpg"),
            ("Rome", "Italy", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwWyq_eKnfHFkKRUUDfUE5AVSS-kYfHAg1Tg&s"),
            ("Seoul", "South Korea", "https://www.agoda.com/wp-content/uploads/2024/08/Namsan-Tower-during-autumn-in-Seoul-South-Korea-1244x700.jpg"),
            ("Phuket", "Thailand", "https://www.aleenta.com/wp-content/uploads/Phi-Phi-Islands-Day-Trip.jpg"),
            ("Sydney", "Australia", "https://cdn.sydneycitytour.com.au/wp-content/uploads/2024/10/Sydney-Opera-House.png")
        ]
        
        let tripRules = [
            "Respect one another and avoid spamming in the group chat.",
            "Be punctual for all scheduled group activities.",
            "Share and track all expenses transparently through the app.",
            "Complete assigned tasks on time to keep the trip on track.",
            "Positive vibes only—let's support each other and have fun!"
        ]
        
        let titles = ["Backpacking Adventure", "Food Tour", "Photography Expedition", "Relaxing Getaway", "Cultural Discovery"]
        let descriptions = ["Join me for an amazing trip!", "Looking for buddies to explore.", "Can't wait to see this place.", "A budget-friendly journey.", "Experience local life together."]
        let tripTypes: [TripType] = [.buddy, .localHost, .seekingLocal]
        let maxMembers = [2, 4, 6, 8, 10]
        
        print("🚀 Bắt đầu tạo 30 trips giả lập...")
        
        // 2. Vòng lặp tạo 30 cái
        for i in 1...30 {
            // Random dữ liệu
            let dest = destinations.randomElement()!
            let randomDays = Int.random(in: 1...60) // Ngày bắt đầu từ mai đến 2 tháng sau
            let startDate = Calendar.current.date(byAdding: .day, value: randomDays, to: Date())!
            let dayIndex = Int.random(in: 4...10)
            
            let newTrip = Trip(
                id: nil, // createTrip sẽ tự sinh ID
                ownerId: ownerId,
                ownerName: "Alex Nguyen",
                coverImage: dest.img,
                title: "\(titles.randomElement()!) to \(dest.loc) #\(i)",
                description: descriptions.randomElement()!,
                tripRule: tripRules.randomElement()!,
                location: dest.loc,
                country: dest.country,
                tripType: tripTypes.randomElement()!,
                status: .recruiting,
                members: [],
                pendingRequests: [],
                maxMember: maxMembers.randomElement()!,
                currentMember: 1,
                startTime: startDate,
                dayIndex: dayIndex,
                createdAt: nil, // Server lo
                updatedAt: nil
            )
            
            do {
                // Gọi hàm createTrip xịn xò mình vừa viết lúc nãy
                _ = try await createTrip(trip: newTrip)
                print("✅ Đã tạo trip số \(i): \(dest.loc)")
            } catch {
                print("❌ Lỗi tạo trip \(i): \(error.localizedDescription)")
            }
        }
        
        print("🎉 HOÀN TẤT! Đã seed xong dữ liệu.")
    }
}
