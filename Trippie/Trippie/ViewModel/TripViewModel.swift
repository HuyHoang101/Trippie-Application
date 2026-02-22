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
    @Published var tripForFilter = [Trip]()
    
    // MARK: - OUTPUT (Bindings)
    let singleTrip = CurrentValueSubject<Trip?, Never>(nil)
    let singleMyTrip = CurrentValueSubject<TripWithStatus?, Never>(nil)
    let trips = CurrentValueSubject<[Trip], Never>([])
    let randomTrips = CurrentValueSubject<[Trip], Never>([])
    let myTrips = CurrentValueSubject<[TripWithStatus], Never>([])
    let filteredMyTrips = CurrentValueSubject<[TripWithStatus], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    let successMessage = PassthroughSubject<String, Never>()
    let editingTrip = CurrentValueSubject<TripWithStatus?, Never>(nil)
    let didTapChange = PassthroughSubject<String, Never>()
    
    // MARK: - INPUT (FILTER & SEARCH)
    let searchTextMyTrip = CurrentValueSubject<String?, Never>(nil)
    let titleFilter = CurrentValueSubject<String?, Never>(nil)
    
    // MARK: - PRIVATE PROPERTIES
    private let authService = AuthService.shared
    private let tripService = TripService.shared
    private var cancellable = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        pipe()
    }
    
    // MARK: - SINGLE TRIP
    func fetchTripById(tripId: String) {
        loading.send(true)
        Task {
            do {
                let result = try await tripService.getTripById(tripId: tripId)
                singleTrip.send(result)
                self.loading.send(false)
            } catch {
                self.errorMessage.send(error.localizedDescription)
                self.loading.send(false)
            }
        }
    }
    
    // MARK: - SINGLE MY TRIP
    func fetchMyTripById(tripId: String) {
        loading.send(true)
        Task {
            do {
                let result = try await tripService.getMyTripById(tripId: tripId)
                singleMyTrip.send(result)
                self.loading.send(false)
            } catch {
                self.errorMessage.send(error.localizedDescription)
                self.loading.send(false)
            }
        }
    }
    
    // MARK: - 1. FETCH FEED (Đã thêm Delay tối thiểu 0.3s)
    func fetchTripForFeedTable() {
        self.loading.send(true)
        let startTime = Date() // 1. Bấm giờ
        
        Task {
            do {
                let result = try await tripService.fetchTripForFeedingList()
                
                
                await waitMinTime(startTime: startTime)
                
                trips.send(result)
                randomTrips.send(result.shuffled())
                self.loading.send(false)
                
            } catch {
                await waitMinTime(startTime: startTime) // Đợi cả khi lỗi để tránh nháy màn hình
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 2. FETCH MY TRIPS (Đã thêm Delay tối thiểu 0.3s)
    func fetchMyTrips() {
        self.loading.send(true)
        let startTime = Date() // 1. Bấm giờ
        
        Task {
            do {
                if let userId = authService.currentUserId {
                    let result = try await tripService.fetchMyTrips(userId: userId)
                    
                    // 2. Đợi đủ thời gian
                    await waitMinTime(startTime: startTime)
                    
                    myTrips.send(result)
                    self.loading.send(false)
                } else {
                    self.loading.send(false)
                }
            } catch {
                await waitMinTime(startTime: startTime)
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 3. HANDLE SAVE (CREATE OR EDIT)
    func handleSave(trip: Trip) {
        self.loading.send(true)
        Task {
            do {
                if let _ = editingTrip.value {
                    // --- CASE: UPDATE ---
                    let result = try await tripService.updateTrip(trip: trip)
                   
                    self.updateLocalLists(updatedTrip: result.trip)
                    self.successMessage.send("Update Trip Successfully!")
                   
                } else {
                    // --- CASE: CREATE ---
                    let result = try await tripService.createTrip(trip: trip)
                    var currentTrips = self.myTrips.value
                    currentTrips.insert(result, at: 0)
                    self.myTrips.send(currentTrips)
                    self.updateLocalLists(updatedTrip: result.trip)
                    self.successMessage.send("Create Trip Successfully!")
                }
              
                self.loading.send(false)
                self.editingTrip.send(nil)
              
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Save failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 4. DELETE TRIP
    func deleteTrip(tripId: String) {
        self.loading.send(true)
        
        Task {
            do {
                try await tripService.deleteTrip(tripId: tripId)
              
                var currentMyTrips = myTrips.value
                if currentMyTrips.contains(where: { $0.trip.id == tripId }) {
                    currentMyTrips.removeAll { $0.trip.id == tripId }
                    myTrips.send(currentMyTrips)
                }
              
                var currentFeedTrips = trips.value
                if currentFeedTrips.contains(where: { $0.id == tripId }) {
                    currentFeedTrips.removeAll { $0.id == tripId }
                    trips.send(currentFeedTrips)
                }
                
                self.didTapChange.send(tripId)
              
                self.loading.send(false)
              
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - HELPER (Private)
    private func updateLocalLists(updatedTrip: Trip) {
        var currentMyTrips = myTrips.value
        if let index = currentMyTrips.firstIndex(where: { $0.trip.id == updatedTrip.id }) {
            currentMyTrips[index].trip = updatedTrip
            myTrips.send(currentMyTrips)
        }
       
        var currentFeedTrips = trips.value
        if let index = currentFeedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
            currentFeedTrips[index] = updatedTrip
            trips.send(currentFeedTrips)
        } else {
            currentFeedTrips.insert(updatedTrip, at: 0)
            trips.send(currentFeedTrips)
        }
        
        didTapChange.send(updatedTrip.id!)
    }

    // MARK: - 5. MEMBER MANAGEMENT ACTIONS
    func acceptJoinRequest(userId: String, trip: Trip) {
        self.loading.send(true)
        guard let id = trip.id else { return }
        Task {
            do {
                let updatedTrip = try await tripService.acceptJoinTrip(userId: userId, tripId: id)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.successMessage.send("Accept member successfully!")
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Accept failed: \(error.localizedDescription)")
            }
        }
    }
    
    func denyJoinRequest(userId: String, trip: Trip) {
        guard let id = trip.id else { return }
        self.loading.send(true)
        Task {
            do {
                let updatedTrip = try await tripService.denyJoinTrip(userId: userId, tripId: id)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.successMessage.send("Deny member successfully!")
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func kickMember(userId: String, trip: Trip) {
        guard let id = trip.id else { return }
        self.loading.send(true)
        Task {
            do {
                let updatedTrip = try await tripService.kickMemberInTrip(userId: userId, tripId: id)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.successMessage.send("Kick member successfully!")
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 6. UPDATE PERSONAL STATUS
    func updatePersonalStatus(participation: Participation) {
        self.loading.send(true)
       
        Task {
            do {
                let result = try await tripService.changePersonalStatus(participation: participation)
                var currentList = myTrips.value
               
                if let resultId = result.id {
                    if let index = currentList.firstIndex(where: { item in
                        return item.participation?.id == resultId
                    }) {
                        currentList[index].participation = result
                        myTrips.send(currentList)
                        didTapChange.send(result.tripId)
                    }
                }
                self.successMessage.send("Update personal status successfully!")
                self.loading.send(false)
              
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Cập nhật trạng thái thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - LEAVE TRIP
    func leaveTrip(trip: Trip) {
        self.loading.send(true)
        guard let id = trip.id else { return }
        Task {
            do {
                let updatedTrip = try await tripService.leaveTrip(tripId: id)
              
                var currentMyTrips = myTrips.value
                currentMyTrips.removeAll(where: {$0.trip.id == updatedTrip.id})
               
                var currentFeedTrips = trips.value
                if let index = currentFeedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
                    currentFeedTrips[index] = updatedTrip
                    trips.send(currentFeedTrips)
                }
                
                didTapChange.send(updatedTrip.id!)
                self.successMessage.send("Leave trip successfully!")
                self.loading.send(false)
              
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Leave team failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CANCEL REQUEST
    func cancelJoinRequest(trip: Trip) {
        guard let tripId = trip.id else { return }
       
        self.loading.send(true)
       
        Task {
            do {
                let updatedTrip = try await tripService.cancelJoinRequest(tripId: tripId)
              
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.loading.send(false)
              
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Cancel request failed: \(error.localizedDescription)")
            }
        }
    }
    
    //MARK: - JOIN TRIP
    func joinTrip(trip: Trip) {
        self.loading.send(true)
        guard let id = trip.id else { return }
        Task {
            do {
                let updatedTrip = try await tripService.joinTrip(tripId: id)
                
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.successMessage.send("Send join request successfully!")
              
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    
    //MARK: - PIPE
    private func pipe(){
        Publishers.CombineLatest(myTrips, searchTextMyTrip)
                .map { (trips, searchText) -> [TripWithStatus] in
                    // Nếu không có chữ gì để search -> Trả về y nguyên mảng gốc
                    guard let text = searchText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                        return trips
                    }
                    
                    let query = text.lowercased()
                    
                    // Lọc mảng gốc và trả về mảng mới
                    return trips.filter { item in
                        // Chú ý: Cậu thay item.title, item.country cho đúng với Model thực tế nhé
                        let titleMatch = item.trip.title.lowercased().contains(query)
                        let countryMatch = item.trip.country.lowercased().contains(query)
                        let locationMatch = item.trip.location.lowercased().contains(query)
                        
                        return titleMatch || countryMatch || locationMatch
                    }
                }
                .sink { [weak self] result in
                    // Đẩy data đã lọc ra cho biến mới
                    self?.filteredMyTrips.send(result)
                }
                .store(in: &cancellable)

        // Filter Local
        Publishers.CombineLatest(randomTrips, titleFilter)
            .removeDuplicates { prev, current in
                let isArraySame = prev.0.map { $0.id } == current.0.map { $0.id }
                let isStringSame = prev.1 == current.1
                return isArraySame && isStringSame
            }
            .map { (allTrips, filter) -> [Trip] in
               
                switch filter {
                case "Earliest":
                    return allTrips.sorted { $0.startTime < $1.startTime }
                case "Vietnam":
                    return allTrips.filter { $0.country == "Vietnam" }
                default:
                    return allTrips.shuffled()
                }
            }
            .assign(to: &$tripForFilter)
        errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Failed: \(error)",
                            "isSuccess": false
                        ]
                    )
                }
            }
            .store(in: &cancellable)
        successMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { success in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "\(success)",
                            "isSuccess": true
                        ]
                    )
                }
            }
            .store(in: &cancellable)
    }
    
    // MARK: - PRIVATE HELPER (DELAY)
    private func waitMinTime(startTime: Date, minDuration: Double = 1) async {
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minDuration {
            // Nếu chạy nhanh quá (ví dụ 0.05s) -> Ngủ thêm (1.0 - 0.05 = 0.95s)
            let leftTime = minDuration - elapsed
            try? await Task.sleep(nanoseconds: UInt64(leftTime * 1_000_000_000))
        }
    }
}
