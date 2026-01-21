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
    
    // --- 1. REGISTER (Async/Await) ---
    func register(email: String, pass: String, name: String) async throws -> User {
        
        // Step 1: Create account
        let authResult = try await Auth.auth().createUser(withEmail: email, password: pass)
        let uid = authResult.user.uid
        
        // Step 2: create profile
        let newUser = User(
            id: uid,
            avatarUrl: "",
            name: name,
            email: email,
            phone: "",
            address: "",
            aboutMe: "New member of Trippie",
            rating: 0.0,
            ratingCount: 0,
            friendIds: [],
            fcmToken: "",
            createdAt: nil, // Server auto fill
            updatedAt: nil
        )
        
        // Step 3: save user profile
        try db.collection("users").document(uid).setData(from: newUser)
        return newUser
    }
    
    // --- 2. LOGIN (Async/Await) ---
    func login(email: String, pass: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: pass)
    }
    
    // --- 3. LOGOUT ---
    func logout() throws {
        try Auth.auth().signOut()
    }
    
    // --- 4. CHECK USER ---
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
}
