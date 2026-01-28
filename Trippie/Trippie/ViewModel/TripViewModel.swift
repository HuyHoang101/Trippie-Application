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
    let trips = CurrentValueSubject<[Trip], Never>([])
    let randomTrips = CurrentValueSubject<[Trip], Never>([])
    let myTrips = CurrentValueSubject<[TripWithStatus], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    let editingTrip = CurrentValueSubject<TripWithStatus?, Never>(nil)
    
    // MARK: - INPUT (FILTER & SEARCH)
    let searchText = CurrentValueSubject<String?, Never>(nil)
    let country = CurrentValueSubject<String?, Never>(nil)
    let tripType = CurrentValueSubject<TripType?, Never>(nil)
    let titleFilter = CurrentValueSubject<String?, Never>(nil)
    
    // MARK: - PRIVATE PROPERTIES
    private let authService = AuthService.shared
    private let tripService = TripService.shared
    private var cancellable = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        pipe()
    }
    
    // MARK: - 1. FETCH FEED (Đã thêm Delay tối thiểu 0.3s)
    func fetchTripForFeedTable() {
        self.loading.send(true)
        let startTime = Date() // 1. Bấm giờ
        
        Task {
            do {
                let result = try await tripService.fetchTripForFeedingList(tripType: tripType.value, country: country.value, searchText: searchText.value)
                
                // 2. Đợi cho đủ 0.3s nếu API trả về quá nhanh
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
                   
                    // A. Cập nhật MyTrips
                    var currentMyTrips = myTrips.value
                    if let index = currentMyTrips.firstIndex(where: { $0.trip.id == result.trip.id }) {
                        currentMyTrips[index] = result
                        myTrips.send(currentMyTrips)
                    }
                   
                    // B. Cập nhật Feed Trips
                    var currentFeedTrips = trips.value
                    if let index = currentFeedTrips.firstIndex(where: { $0.id == result.trip.id }) {
                        currentFeedTrips[index] = result.trip
                        trips.send(currentFeedTrips)
                    }
                   
                } else {
                    // --- CASE: CREATE ---
                    let result = try await tripService.createTrip(trip: trip)
                   
                    // A. Thêm vào đầu MyTrips
                    var currentMyTrips = myTrips.value
                    currentMyTrips.insert(result, at: 0)
                    myTrips.send(currentMyTrips)
                   
                    // B. Thêm vào đầu Feed
                    var currentFeedTrips = trips.value
                    currentFeedTrips.insert(result.trip, at: 0)
                    trips.send(currentFeedTrips)
                }
              
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
        }
    }

    // MARK: - 5. MEMBER MANAGEMENT ACTIONS
    func acceptJoinRequest(userId: String, trip: Trip) {
        self.loading.send(true)
        Task {
            do {
                let updatedTrip = try await tripService.acceptJoinTrip(userId: userId, trip: trip)
                self.updateLocalLists(updatedTrip: updatedTrip)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Duyệt thất bại: \(error.localizedDescription)")
            }
        }
    }
    
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
    func updatePersonalStatus(participation: Participation) {
        self.loading.send(true)
       
        Task {
            do {
                let result = try await tripService.changePersonalStatus(participation: participation)
                var currentList = myTrips.value
               
                if let resultId = result.id {
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
                let updatedTrip = try await tripService.leaveTrip(input: tripWithStatus)
              
                var currentMyTrips = myTrips.value
                if let index = currentMyTrips.firstIndex(where: { $0.trip.id == updatedTrip.id }) {
                    currentMyTrips.remove(at: index)
                    myTrips.send(currentMyTrips)
                }
              
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
                let updatedTrip = try await tripService.cancelJoinRequest(tripId: tripId, userId: userId)
              
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
    
    
    //MARK: - PIPE
    private func pipe(){
        Publishers.CombineLatest3(searchText, country, tripType)
                .dropFirst()
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .removeDuplicates { $0 == $1 }
                .sink { [weak self] (text, country, type) in
                    self?.fetchTripForFeedTable()
                }
                .store(in: &cancellable)

            // Luồng 2: Filter Local
            Publishers.CombineLatest(randomTrips, titleFilter)
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
