//
//  UserViewModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Foundation
import Combine

@MainActor
class UserViewModel {
    
    // MARK: - SINGLETON
    static let shared = UserViewModel()
    
    
    // MARK: - OUTPUT
    // Danh sách người dùng khác (Friends, Search results, Members of trip...)
    let profiles = CurrentValueSubject<[User], Never>([])
    
    // Profile của chính mình (Current User)
    let myProfiles = CurrentValueSubject<User?, Never>(nil)
    
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    
    // MARK: - PRIVATE PROPERTIES
    private let userService = UserService.shared
    private let authService = AuthService.shared // Cần auth để biết mình là ai
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - INIT
    private init() { }
    
    
    // MARK: - HELPER: CHECK FRIEND STATUS
    // Hàm check xem user này có phải bạn mình không
    func isMyFriend(userId: String) -> Bool {
        // 1. Nếu chưa load được profile của mình -> Mặc định false
        guard let me = myProfiles.value else {
            return false
        }
        
        // 2. Check xem id người kia có trong danh sách bạn bè của mình không
        return me.friendIds.contains(userId)
    }
    
    
    // MARK: - 1. FETCH MY PROFILE
    func fetchMyProfile() {
        guard let uid = authService.currentUserId else { return }
        
        self.loading.send(true)
        Task {
            do {
                let user = try await userService.fetchUserById(id: uid)
                self.myProfiles.send(user) // Update data của mình
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Fail to load profile: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 2. FETCH OTHER PROFILES
    func fetchUsers(ids: [String]) {
        if ids.isEmpty { return }
        
        self.loading.send(true)
        Task {
            do {
                let users = try await userService.fetchUsersByIds(ids: ids)
                self.profiles.send(users)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Fail to load list users: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 3. FRIEND ACTION (ADD / UNFRIEND)
    func toggleFriendship(targetUser: User) {
        guard let myId = authService.currentUserId,
              let targetId = targetUser.id,
              var myUser = myProfiles.value else { return }
        
        self.loading.send(true)
        
        // A. Xác định hành động (Nếu đã là bạn -> Unfriend, ngược lại -> Add)
        let isFriending = !isMyFriend(userId: targetId)
        
        Task {
            do {
                // 1. Gọi Service
                try await userService.updateFriendStatus(currentUserId: myId, targetUserId: targetId, isFriending: isFriending)
                
                // 2. UPDATE LOCAL (Optimistic UI) - Cập nhật ngay không cần load lại
                
                // --- Cập nhật MY PROFILE ---
                if isFriending {
                    myUser.friendIds.append(targetId)
                } else {
                    myUser.friendIds.removeAll { $0 == targetId }
                }
                self.myProfiles.send(myUser)
                
                // --- Cập nhật TARGET USER (trong list profiles) ---
                var currentProfiles = profiles.value
                if let index = currentProfiles.firstIndex(where: { $0.id == targetId }) {
                    var updatedTarget = currentProfiles[index]
                    if isFriending {
                        updatedTarget.friendIds.append(myId)
                    } else {
                        updatedTarget.friendIds.removeAll { $0 == myId }
                    }
                    currentProfiles[index] = updatedTarget
                    self.profiles.send(currentProfiles)
                }
                
                self.loading.send(false)
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Updated friendlist failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 4. RATING ACTIONS
    
    // A. Add Rating
    func addRating(rating: RatingFor) {
        self.loading.send(true)
        Task {
            do {
                try await userService.addRating(rating: rating)
                // Sau khi rate xong, cần fetch lại user đó để cập nhật điểm Rating Average mới nhất
                try await refreshSingleUserInList(userId: rating.otherUserId)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Rating failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    // B. Update Rating
    func updateRating(ratingId: String, newNum: Int, otherUserId: String) {
        self.loading.send(true)
        Task {
            do {
                try await userService.updateRating(ratingId: ratingId, newNum: newNum, otherUserId: otherUserId)
                try await refreshSingleUserInList(userId: otherUserId)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Updated Rating failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    // C. Delete Rating
    func deleteRating(ratingId: String, otherUserId: String) {
        self.loading.send(true)
        Task {
            do {
                try await userService.deleteRating(ratingId: ratingId, otherUserId: otherUserId)
                try await refreshSingleUserInList(userId: otherUserId)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Deleted Rating failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - HELPER: Refresh 1 User (Dùng sau khi Rate)
    // Hàm này giúp cập nhật lại số sao (Rating) của 1 user trong list mà không cần load lại cả list
    private func refreshSingleUserInList(userId: String) async throws {
        // 1. Lấy thông tin mới nhất từ Server (đã được tính toán Average mới)
        let updatedUser = try await userService.fetchUserById(id: userId)
        
        // 2. Thay thế vào danh sách profiles hiện tại
        var currentProfiles = profiles.value
        if let index = currentProfiles.firstIndex(where: { $0.id == userId }) {
            currentProfiles[index] = updatedUser
            self.profiles.send(currentProfiles)
        }
        
        // 3. (Optional) Nếu user đó trùng với MyProfile (trường hợp tự sướng?) thì update luôn
        if let myId = myProfiles.value?.id, myId == userId {
            self.myProfiles.send(updatedUser)
        }
    }
}
