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
        
        return newUser
    }
    
    // --- 2. LOGIN ---
    func login(email: String, pass: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: pass)
        
        // Đăng nhập xong thì lưu ID vào cache ngay
        saveUserToCache(uid: result.user.uid)
    }
    
    // --- 3. LOGOUT ---
    func logout() throws {
        try Auth.auth().signOut()
        // Xoá sạch dấu vết trong cache khi logout
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
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

    // --- PRIVATE HELPERS ---
    private func saveUserToCache(uid: String) {
        UserDefaults.standard.set(uid, forKey: userDefaultsKey)
    }
}
