//
//  AuthService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    // Key để lưu vào UserDefaults
    private let userDefaultsKey = "cached_user_id"
    private let userDefaultsName = "cached_user_name"
    private let userDefaultsAvatar = "cached_user_avatar"
    
    // --- 1. REGISTER ---
    func register(email: String, pass: String, name: String, phone: String? = nil) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: pass)
        let uid = authResult.user.uid
        
        let newUser = User(
            id: uid,
            avatarUrl: "",
            name: name,
            email: email,
            phone: phone ?? "",
            address: "",
            aboutMe: "New member of Trippie",
            rating: 0.0,
            ratingCount: 0,
            friendIds: [],
            fcmToken: "",
            createdAt: Date(), // Gán tạm local
            updatedAt: Date()
        )
        
        try db.collection("users").document(uid).setData(from: newUser)
        
        // Lưu UID vào cache sau khi đăng ký thành công
        saveUserToCache(uid: uid)
        saveUserNameToCache(name: name)
        
        return newUser
    }
    
    // --- 2. LOGIN ---
    func login(email: String, pass: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: pass)
        let user = try await UserService.shared.fetchUserById(id: result.user.uid)
        // Đăng nhập xong thì lưu ID vào cache ngay
        saveUserToCache(uid: result.user.uid)
        saveUserNameToCache(name: user.name)
        saveUserAvatarToCache(avatarUrl: user.avatarUrl)
    }
    
    // --- 3. LOGOUT ---
    func logout() throws {
        try Auth.auth().signOut()
        // Xoá sạch dấu vết trong cache khi logout
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsName)
        UserDefaults.standard.removeObject(forKey: userDefaultsAvatar)
    }
    
    // --- 4. CHECK USER (OPTIMIZED) ---
    // Hàm này sẽ trả về UID của user hiện tại
    var currentUserId: String? {
        // Ưu tiên 1: Check trong UserDefaults trước (Siêu nhanh)
        if let cachedId = UserDefaults.standard.string(forKey: userDefaultsKey) {
            return cachedId
        }
        
        // Ưu tiên 2: Nếu cache trống (app bị xoá/reinstall), check Firebase Auth
        if let firebaseUser = Auth.auth().currentUser {
            // Tiện tay lưu lại vào cache cho lần sau
            saveUserToCache(uid: firebaseUser.uid)
            return firebaseUser.uid
        }
        
        return nil
    }
    
    var currentUserName: String? {
        if let cacheName = UserDefaults.standard.string(forKey: userDefaultsName) {
            return cacheName
        }
        return nil
    }
    
    var currentUserAvatar: String? {
        if let cacheAvatar = UserDefaults.standard.string(forKey: userDefaultsAvatar) {
            return cacheAvatar
        }
        return nil
    }

    // --- PRIVATE HELPERS ---
    private func saveUserToCache(uid: String) {
        UserDefaults.standard.set(uid, forKey: userDefaultsKey)
    }
    private func saveUserNameToCache(name: String) {
        UserDefaults.standard.set(name, forKey: userDefaultsName)
    }
    private func saveUserAvatarToCache(avatarUrl: String) {
        UserDefaults.standard.set(avatarUrl, forKey: userDefaultsAvatar)
    }
}
