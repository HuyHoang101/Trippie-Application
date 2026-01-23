//
//  TripModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Foundation
import Combine

@MainActor
class TripViewModel {
    
    // MARK: - SINGLETON
    static let shared = TripViewModel()
    
    
    // MARK: - OUTPUT (Bindings)
    let trips = CurrentValueSubject<[Trip], Never>([])
    let myTrips = CurrentValueSubject<[TripWithStatus], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    let editingTrip = CurrentValueSubject<TripWithStatus?, Never>(nil)
    
    // MARK: - INPUT (FILTER & SEARCH)
    let searchText = CurrentValueSubject<String?, Never>(nil)
    let country = CurrentValueSubject<String?, Never>(nil)
    let tripType = CurrentValueSubject<TripType?, Never>(nil)
    
    // MARK: - PRIVATE PROPERTIES
    private let authService = AuthService.shared
    private let tripService = TripService.shared
    private let cancellable = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        
    }
    
    // MARK: - Action (Logic)
    
    
    
    // MARK: - 1. FETCH FEED
    func fetchTripForFeedTable() {
        self.loading.send(true)
        Task {
            do {
                let result  = try await tripService.fetchTripForFeedingList(tripType: tripType.value, country: country.value, searchText: searchText.value)
                trips.send(result)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 2. FETCH MY TRIPS
    func fetchMyTrips() {
        self.loading.send(true)
        Task {
            do {
                if let userId = authService.currentUserId {
                    let result = try await tripService.fetchMyTrips(userId: userId)
                    myTrips.send(result)
                    self.loading.send(false)
                } else {
                    self.loading.send(false)
                }
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 3. HANDLE SAVE (CREATE OR EDIT)
    func handleSave(tripWithStatus: TripWithStatus) {
        self.loading.send(true)
        Task {
            do {
                if let _ = editingTrip.value {
                    // --- CASE: UPDATE ---
                    let result = try await tripService.updateTrip(input: tripWithStatus)
                    
                    // A. Cập nhật MyTrips (Nếu có thì thay thế)
                    var currentMyTrips = myTrips.value
                    if let index = currentMyTrips.firstIndex(where: { $0.trip.id == result.trip.id }) {
                        currentMyTrips[index] = result
                        myTrips.send(currentMyTrips)
                    }
                    
                    // B. Cập nhật Feed Trips (Nếu có thì thay thế)
                    // Lưu ý: Feed dùng [Trip], result trả về [TripWithStatus] -> Lấy .trip
                    var currentFeedTrips = trips.value
                    if let index = currentFeedTrips.firstIndex(where: { $0.id == result.trip.id }) {
                        currentFeedTrips[index] = result.trip
                        trips.send(currentFeedTrips)
                    }
                    
                } else {
                    // --- CASE: CREATE ---
                    let result = try await tripService.createTrip(input: tripWithStatus)
                    
                    // A. Thêm vào đầu danh sách MyTrips
                    var currentMyTrips = myTrips.value
                    currentMyTrips.insert(result, at: 0)
                    myTrips.send(currentMyTrips)
                    
                    // B. Thêm vào đầu Feed (Tùy logic, thường tạo xong sẽ hiện lên feed luôn)
                    var currentFeedTrips = trips.value
                    currentFeedTrips.insert(result.trip, at: 0)
                    trips.send(currentFeedTrips)
                }
                
                // Thành công -> Tắt loading và reset trạng thái edit
                self.loading.send(false)
                self.editingTrip.send(nil)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Lưu thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 4. DELETE TRIP
    func deleteTrip(tripId: String) {
        self.loading.send(true)
        
        Task {
            do {
                // Gọi service xoá trên server trước
                try await tripService.deleteTrip(tripId: tripId)
                
                // A. Xoá khỏi MyTrips (Nếu có)
                var currentMyTrips = myTrips.value
                if currentMyTrips.contains(where: { $0.trip.id == tripId }) {
                    currentMyTrips.removeAll { $0.trip.id == tripId }
                    myTrips.send(currentMyTrips)
                }
                
                // B. Xoá khỏi Feed (Nếu có)
                var currentFeedTrips = trips.value
                if currentFeedTrips.contains(where: { $0.id == tripId }) {
                    currentFeedTrips.removeAll { $0.id == tripId }
                    trips.send(currentFeedTrips)
                }
                
                self.loading.send(false)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - HELPER (Private)
    // Hàm này dùng chung để cập nhật Trip trong cả 2 list (Feed & MyTrips)
    private func updateLocalLists(updatedTrip: Trip) {
        // 1. Cập nhật MyTrips (Nếu có trong list)
        var currentMyTrips = myTrips.value
        if let index = currentMyTrips.firstIndex(where: { $0.trip.id == updatedTrip.id }) {
            currentMyTrips[index].trip = updatedTrip
            myTrips.send(currentMyTrips)
        }
        
        // 2. Cập nhật Feed (Nếu có trong list)
        var currentFeedTrips = trips.value
        if let index = currentFeedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
            currentFeedTrips[index] = updatedTrip
            trips.send(currentFeedTrips)
        }
    }

    // MARK: - 5. MEMBER MANAGEMENT ACTIONS
    
    // A. DUYỆT THÀNH VIÊN (Update cả 2 list)
    func acceptJoinRequest(userId: String, trip: Trip) {
        self.loading.send(true)
        Task {
            do {
                // Gọi Service -> Nhận về Trip mới (đã thêm member, đổi status...)
                let updatedTrip = try await tripService.acceptJoinTrip(userId: userId, trip: trip)
                
                // Update UI ngay lập tức
                self.updateLocalLists(updatedTrip: updatedTrip)
                
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Duyệt thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // B. TỪ CHỐI THÀNH VIÊN (Update cả 2 list)
    func denyJoinRequest(userId: String, trip: Trip) {
        self.loading.send(true)
        Task {
            do {
                let updatedTrip = try await tripService.denyJoinTrip(userId: userId, trip: trip)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Lỗi: \(error.localizedDescription)")
            }
        }
    }
    
    // C. MỜI RA KHỎI NHÓM / KICK (Update cả 2 list)
    func kickMember(userId: String, trip: Trip) {
        self.loading.send(true)
        Task {
            do {
                let updatedTrip = try await tripService.kickMemberInTrip(userId: userId, trip: trip)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Xoá thành viên thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 6. UPDATE PERSONAL STATUS
    
    // Chỉ cập nhật MyTrips (vì Status cá nhân không hiển thị trên Feed chung)
    func updatePersonalStatus(participation: Participation) {
        self.loading.send(true)
        
        Task {
            do {
                // 1. Gọi Service
                let result = try await tripService.changePersonalStatus(participation: participation)
                
                // 2. Cập nhật vào list MyTrips
                var currentList = myTrips.value
                
                // Tìm đúng cái TripWithStatus sở hữu participationId này để update
                if let resultId = result.id {
                    // 2. Dùng 'item in' thay vì '$0' để trình biên dịch hiểu rõ kiểu dữ liệu
                    // So sánh: (String?) == (String) -> Swift tự hiểu
                    if let index = currentList.firstIndex(where: { item in
                        return item.participation.id == resultId
                    }) {
                        currentList[index].participation = result
                        myTrips.send(currentList)
                    }
                }
                
                self.loading.send(false)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Cập nhật trạng thái thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - LEAVE TRIP
    func leaveTrip(tripWithStatus: TripWithStatus) {
        self.loading.send(true)
        
        Task {
            do {
                // 1. Gọi Service -> Nhận về Trip đã update info
                let updatedTrip = try await tripService.leaveTrip(input: tripWithStatus)
                
                // 2. Xử lý logic UI
                
                // A. Với MyTrips: Rời rồi thì xoá khỏi danh sách của tôi
                var currentMyTrips = myTrips.value
                // Tìm đúng cái item có tripId đó để xoá
                if let index = currentMyTrips.firstIndex(where: { $0.trip.id == updatedTrip.id }) {
                    currentMyTrips.remove(at: index)
                    myTrips.send(currentMyTrips)
                }
                
                // B. Với Feed: Chuyến đi vẫn còn đó, chỉ cập nhật số lượng member
                var currentFeedTrips = trips.value
                if let index = currentFeedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
                    currentFeedTrips[index] = updatedTrip
                    trips.send(currentFeedTrips)
                }
                
                self.loading.send(false)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Leave team failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CANCEL REQUEST
    func cancelJoinRequest(trip: Trip) {
        guard let userId = authService.currentUserId, let tripId = trip.id else { return }
        
        self.loading.send(true)
        
        Task {
            do {
                // 1. Gọi Service
                let updatedTrip = try await tripService.cancelJoinRequest(tripId: tripId, userId: userId)
                
                // 2. Update UI (Chỉ cần update Feed vì Pending chưa có trong MyTrips)
                var currentFeedTrips = trips.value
                if let index = currentFeedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
                    currentFeedTrips[index] = updatedTrip
                    trips.send(currentFeedTrips)
                }
                
                self.loading.send(false)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Huỷ yêu cầu thất bại: \(error.localizedDescription)")
            }
        }
    }
}
