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
        guard let userId = input.participation?.userId else {
            throw NSError(domain: "TripService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ID user not found"])
        }
        
        guard let tripId = updatedTrip.id, let partId = input.participation?.id else {
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
        guard AuthService.shared.currentUserId != nil else {
            print("❌ Lỗi: Chưa đăng nhập, không lấy được OwnerId")
            return
        }
        
        // 1. Bộ dữ liệu chuẩn (Location - Country - Image đi kèm nhau)
        let destinations: [(loc: String, country: String, img: [String])] = [
            // MARK: - 1. Vietnam
            ("Ha Long Bay", "Vietnam", ["https://vietnam.travel/sites/default/files/inline-images/shutterstock_1218764578.jpg"]),
            ("Da Nang", "Vietnam", ["https://i0.wp.com/littlebirdietravel.com/wp-content/uploads/2025/07/hand-bridge-da-nang.jpg?fit=2048%2C1152&ssl=1"]),
            ("Hoi An", "Vietnam", ["https://blisshoian.com/wp-content/uploads/2024/08/hoi-an-dep.webp"]),
            ("Sa Pa", "Vietnam", ["https://statics.vinwonders.com/what-to-do-in-sapa-01_1690273137.jpg"]),
            ("Phu Quoc", "Vietnam", ["https://upload.wikimedia.org/wikipedia/commons/6/6e/Bai-sao-phu-quoc-tuonglamphotos.jpg"]),
            ("Ho Chi Minh City", "Vietnam", ["https://lesrivesexperience.com/wp-content/uploads/2018/11/sunset-on-saigon-river.jpg"]),

            // MARK: - 2. Japan
            ("Tokyo", "Japan", ["https://res.cloudinary.com/aenetworks/image/upload/c_fill,w_1200,h_630,g_auto/dpr_auto/f_auto/q_auto:eco/v1/gettyimages-1390815938"]),
            ("Kyoto", "Japan", ["https://www.pelago.com/img/destinations/kyoto/1129-0642_kyoto-xlarge.webp"]),
            ("Osaka", "Japan", ["https://hanotour.com.vn/upload_images/images/2024/09/13/ve-dep-sam-uat-cho-am-thuc-Osaka-Dotonbori.jpg"]),
            ("Hokkaido", "Japan", ["https://travelnation.co.uk/sites/default/files/900x600-japan-hokkaido-shikisei-hill-biei.jpg"]),
            ("Okinawa", "Japan", ["https://digital.ihg.com/is/image/ihg/intercontinental---ana-okinawa-6162599978-4x3"]),
            ("Nara", "Japan", ["https://dynamic-media-cdn.tripadvisor.com/media/photo-o/0b/35/6d/56/photo0jpg.jpg?w=900&h=500&s=1"]),

            // MARK: - 3. Italy
            ("Rome", "Italy", ["https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwWyq_eKnfHFkKRUUDfUE5AVSS-kYfHAg1Tg&s"]),
            ("Venice", "Italy", ["https://www.citalia.com/-/media/Bynder/Citalia-destinations/Italy/Cities/Venice/Venice-2023-Rialto-Bridge-001109-Hybris.jpg"]),
            ("Florence", "Italy", ["https://cdn.britannica.com/59/179059-050-62BD6102/Cathedral-of-Santa-Maria-del-Fiore-Florence.jpg"]),
            ("Milan", "Italy", ["https://cdn.britannica.com/32/20032-050-B0CF9E76/Shoppers-Galleria-Vittorio-Emanuele-II-Italy-Milan.jpg"]),
            ("Amalfi Coast", "Italy", ["https://images.squarespace-cdn.com/content/v1/62681a0c1b9b025bc7d3d1cb/1651418824279-V1KN3BLDV2LT7AVDQP3Y/52883b7e-ef20-438a-bc38-4859ca0246ba.jpg"]),
            ("Cinque Terre", "Italy", ["https://www.danflyingsolo.com/wp-content/uploads/2016/03/cinqueterreuntitled-.jpg"]),

            // MARK: - 4. France
            ("Paris", "France", ["https://res.cloudinary.com/dtljonz0f/image/upload/c_auto,ar_4:3,w_3840,g_auto/f_auto/q_auto/v1/shutterstock_2118458942_ss_non-editorial_jnjpwq?_a=BAVAZGGf0"]),
            ("Nice", "France", ["https://media.cntraveler.com/photos/6859a7a1c2a40c2029b58992/1:1/w_2059,h_2059,c_limit/062325-Nice-France-Lede-GettyImages-1248448159_1.jpg"]),
            ("Lyon", "France", ["https://dynamic-media-cdn.tripadvisor.com/media/photo-o/14/da/01/47/vieux-lyon.jpg?w=900&h=500&s=1"]),
            ("Bordeaux", "France", ["https://www.franceguide.info/wp-content/uploads/sites/18/bordeaux-place-de-la-bourse-hd.jpg"]),
            ("Marseille", "France", ["https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJiFtBMY5xtDjDkDquanqYBA7mv9Subwi3-w&s"]),
            ("Strasbourg", "France", ["https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR1E30rGkKl3JN5K_sA8mmoPv9oJrjNEXc7fQ&s"]),

            // MARK: - 5. USA
            ("New York", "United States", ["https://cdn.britannica.com/61/93061-050-99147DCE/Statue-of-Liberty-Island-New-York-Bay.jpg"]),
            ("Los Angeles", "United States", ["https://www.pelago.com/img/destinations/los-angeles/0619-0957_losangeles.jpg"]),
            ("San Francisco", "United States", ["https://www.visittheusa.com/sites/default/files/styles/hero_l/public/images/hero_media_image/2016-10/Getty_591648687_Brand_City_SanFrancisco_Hero_FinalCrop.jpg?h=dd3c63f2&itok=iAr8BYrW"]),
            ("Las Vegas", "United States", ["https://img.static-kl.com/transform/6b34090e-5450-4ab0-805c-7544a639f7ab/"]),
            ("Hawaii", "United States", ["https://cdn-jbbdp.nitrocdn.com/KCXzqUWDoupzlrsIQCTXrmGUEEWeTtuj/assets/images/optimized/rev-37e873b/www.eshores.co.uk/wp-content/uploads/2025/08/Papaoneone_Beach_Oahu.jpg"]),
            ("Miami", "United States", ["https://images.trvl-media.com/place/800070/9ea993d5-24cb-4fcb-86e9-ced4d9090113.jpg"])
        ]
        
        let tripRules = [
            "Please treat every member with absolute respect and kindness. Try to keep the group chat focused on important trip details to avoid unnecessary spamming or flooding the conversation with irrelevant messages.",
            
            "Value everyone's time by being strictly punctual for all scheduled meetups, departures, and activities. Late arrivals can cause unnecessary delays and might disrupt our carefully planned itinerary for the whole group.",
            
            "Financial transparency is key to a happy trip. Please ensure you upload all receipts immediately and track every shared expense within the app so we can settle debts fairly and quickly.",
            
            "To ensure our adventure runs smoothly, please take ownership of your assigned responsibilities. Completing your tasks on time helps the whole group relax and enjoy the experience without unnecessary stress or confusion.",
            
            "Let's promise to maintain a positive and supportive atmosphere throughout the journey. If conflicts arise, handle them with maturity, and always focus on creating unforgettable, happy, and stress-free memories together."
        ]
        
        let titles = ["Backpacking Adventure", "Food Tour", "Photography Expedition", "Relaxing Getaway", "Cultural Discovery"]
        let descriptions = [
            "Get ready for an absolutely unforgettable adventure! I am inviting you to join me as we explore hidden gems, capture stunning photos, and create memories that will stay with us forever.",
            
            "I am actively looking for fun, energetic, and open-minded travel buddies to explore the city with. Let's wander through the streets, find cool spots, and make the most of this trip.",
            
            "This destination has been at the very top of my bucket list for years. I simply can't wait to finally see it in person and share the excitement with fellow travelers.",
            
            "We are planning a budget-friendly journey perfect for backpackers. Expect delicious street food, cozy hostels, and smart spending, proving that you don't need a fortune to have a world-class experience.",
            
            "Our goal is to skip the tourist traps and truly experience local life together. We will eat where the locals eat, learn about their traditions, and immerse ourselves in the culture."
        ]
        let tripTypes: [TripType] = [.buddy, .localHost, .seekingLocal]
        let maxMembers = [2, 4, 6, 8, 10]
        let owners: [(id: String, name: String)] = [
            ("JdUmwWFq33Ucya1Up6fPTdnSKnv2", "Alex Nguyen"),
            ("KOKTvfCmNtcCGUyZLpPTmPcZBLK2", "An Le"),
            ("NSH713mAjBQeNGdCx9grfun9u3t1", "Van Nguyen"),
            ("pTQEG1Y8NrSXOTRz7XynckxQqUx1", "Lily White"),
            ("plubkGj48TSfAZONUlCcqrQu8sA3", "Anna Kim"),
            ("qoiuQ5l0H0gZ1N4V37mu8EC4HEJ2", "Jack Nguyen")
        ]
        
        print("🚀 Bắt đầu tạo 30 trips giả lập...")
        
        // 2. Vòng lặp tạo 30 cái
        for (index, dest) in destinations.enumerated() {
                    
            // Random dữ liệu bổ trợ
            let randomOwner = owners.randomElement()! // Random Owner từ danh sách
            let randomDays = Int.random(in: 1...60)
            let startDate = Calendar.current.date(byAdding: .day, value: randomDays, to: Date())!
            let dayIndex = Int.random(in: 4...10)
            
            let newTrip = Trip(
                id: nil, // createTrip sẽ tự sinh ID
                ownerId: randomOwner.id,     // Dùng ID random
                ownerName: randomOwner.name, // Dùng Name random tương ứng
                coverImage: dest.img,        // Ảnh đúng theo địa điểm
                title: "\(titles.randomElement()!) to \(dest.loc)",
                description: descriptions.randomElement()!,
                tripRule: tripRules.randomElement()!,
                location: dest.loc,          // Location cố định theo vòng lặp
                country: dest.country,       // Country cố định theo vòng lặp
                tripType: tripTypes.randomElement()!,
                status: .recruiting,
                members: [],
                pendingRequests: [],
                maxMember: maxMembers.randomElement()!,
                currentMember: 1,
                startTime: startDate,
                dayIndex: dayIndex,
                createdAt: nil,
                updatedAt: nil
            )
            
            do {
                // Gọi hàm createTrip xịn xò mình vừa viết lúc nãy
                _ = try await createTrip(trip: newTrip)
                print("✅ Đã tạo trip số \(index): \(dest.loc)")
            } catch {
                print("❌ Lỗi tạo trip \(index): \(error.localizedDescription)")
            }
        }
        
        print("🎉 HOÀN TẤT! Đã seed xong dữ liệu.")
    }
}
