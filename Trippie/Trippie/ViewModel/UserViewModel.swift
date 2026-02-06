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
    let friendProfiles = CurrentValueSubject<[User], Never>([])
    let allUsers = CurrentValueSubject<[User], Never>([])
    
    // Profile của chính mình (Current User)
    let myProfile = CurrentValueSubject<User?, Never>(nil)
    let editingProfile = CurrentValueSubject<User?, Never>(nil)
    let editingRating = CurrentValueSubject<RatingFor?, Never>(nil)
    
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
        guard let me = myProfile.value else {
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
                self.myProfile.send(user) // Update data của mình
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Fail to load profile: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 2. FETCH OTHER PROFILES
    func fetchUsers(ids: [String], isFriend: Bool) {
        if ids.isEmpty { return }
        
        self.loading.send(true)
        Task {
            do {
                let users = try await userService.fetchUsersByIds(ids: ids)
                if isFriend {
                    self.friendProfiles.send(users)
                } else {
                    self.profiles.send(users)
                }
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
              var myUser = myProfile.value else { return }
        
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
                self.myProfile.send(myUser)
                
                // --- Cập nhật TARGET USER (trong list profiles) ---
                self.profiles.send(updateFriendStatus(in: profiles.value, targetId: targetId, myId: myId, isFriending: isFriending))
                self.allUsers.send(updateFriendStatus(in: allUsers.value, targetId: targetId, myId: myId, isFriending: isFriending))
                var currentFriendList = self.friendProfiles.value
                if isFriending {
                    currentFriendList.append(targetUser)
                } else {
                    currentFriendList.removeAll(where: {$0.id == targetId})
                }
                self.friendProfiles.send(currentFriendList)
                self.loading.send(false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": isFriending ? "Follow Successfully!" : "UnFollow Successfully!",
                            "isSuccess": true
                        ]
                    )
                }
                
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Updated friendlist failed: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Action failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
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
                NotificationCenter.default.post(
                    name: .showGlobalToast,
                    object: nil,
                    userInfo: [
                        "message": "Rating successfully",
                        "isSuccess": true
                    ]
                )
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Rating failed: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Action failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
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
                NotificationCenter.default.post(
                    name: .showGlobalToast,
                    object: nil,
                    userInfo: [
                        "message": "Update rating successfully",
                        "isSuccess": true
                    ]
                )
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Updated Rating failed: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Action failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Delete rating successfully",
                            "isSuccess": true
                        ]
                    )
                }
            } catch {
                self.loading.send(false)
                self.errorMessage.send("Deleted Rating failed: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Action failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
            }
        }
    }
    
    // D. Checking Ratting
    func checkRating(otherId: String) {
        Task {
            do {
                let result = try await userService.fetchMyRating(myId: AuthService.shared.currentUserId!, otherUserId: otherId)
                editingRating.send(result)
            }
        }
    }
    
    // MARK: - 5. UPDATE PROFILE
    func editProfile(user: User) {
        self.loading.send(true)
        
        Task {
            do {
                let result = try await userService.updateInfor(user: user)
                self.myProfile.send(result)
                self.loading.send(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Update Profile Successfully!",
                            "isSuccess": true
                        ]
                    )
                }
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Update Profile failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
            }
        }
    }
    
    // MARK: - 6 UPDATE AVATAR PROFILE
    func updateAvatar(avatarUrl: String) {
        self.loading.send(true)
        
        Task {
            do {
                let result = try await userService.updateAvatar(id: self.myProfile.value?.id ?? "", url: avatarUrl)
                self.myProfile.send(result)
                self.loading.send(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Update Profile Avatar Successfully!",
                            "isSuccess": true
                        ]
                    )
                }
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Update Profile Avatar failed: \(error.localizedDescription)",
                            "isSuccess": false
                        ]
                    )
                }
            }
        }
    }
    
    // MARK: - ALL USER
    func fetchAlluser() {
        self.loading.send(true)
        Task {
            do {
                let resutl = try await userService.fetchAllUser()
                allUsers.send(resutl)
                loading.send(false)
            } catch {
                loading.send(false)
                errorMessage.send(error.localizedDescription)
                print("false")
            }
        }
    }
    
    
    // MARK: - HELPER: Refresh 1 User (Dùng sau khi Rate)
    // Hàm này giúp cập nhật lại số sao (Rating) của 1 user trong list mà không cần load lại cả list
    private func refreshSingleUserInList(userId: String) async throws {
        // 1. Lấy thông tin mới nhất từ Server (đã được tính toán Average mới)
        let updatedUser = try await userService.fetchUserById(id: userId)
        
        // 2. Cập nhập vào tất cả danh sách
        updateUserInSubject(subject: profiles, updatedUser: updatedUser)
        updateUserInSubject(subject: friendProfiles, updatedUser: updatedUser)
        updateUserInSubject(subject: allUsers, updatedUser: updatedUser)
        
        // 3. (Optional) Nếu user đó trùng với MyProfile (trường hợp tự sướng?) thì update luôn
        if let myId = myProfile.value?.id, myId == userId {
            self.myProfile.send(updatedUser)
        }
    }
    
    private func updateUserInSubject(subject: CurrentValueSubject<[User], Never>, updatedUser: User) {
        var currentList = subject.value
        
        // Chỉ cập nhật nếu tìm thấy user đó trong danh sách (dựa vào ID)
        if let index = currentList.firstIndex(where: { $0.id == updatedUser.id }) {
            currentList[index] = updatedUser // Thay thế object cũ bằng object mới fetch về
            subject.send(currentList)        // Bắn tín hiệu để UI reload
        }
    }
    
    //MARK: - HELPER: UPDATE FRIEND STATUS
    private func updateFriendStatus(in list: [User], targetId: String, myId: String, isFriending: Bool) -> [User] {
        var mutableList = list
        // Tìm xem User này có trong list không
        if let index = mutableList.firstIndex(where: { $0.id == targetId }) {
            var user = mutableList[index]
            
            // Update logic
            if isFriending {
                // Chỉ append nếu chưa có (tránh trùng lặp)
                if !user.friendIds.contains(myId) {
                    user.friendIds.append(myId)
                }
            } else {
                user.friendIds.removeAll { $0 == myId }
            }
            mutableList[index] = user
        }
        return mutableList
    }
}
