//
//  UserService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    // MARK: - 1. FETCH USER BY ID
    func fetchUserById(id: String) async throws -> User {
        let snapshot = try await db.collection("users").document(id).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    // MARK: - 2. FETCH LIST USERS (SIMPLE FETCH ALL)
    func fetchUsersByIds(ids: [String]) async throws -> [User] {
        if ids.isEmpty { return [] }
        
        // 1. Fetch ALL users from DB (Simple approach)
        let snapshot = try await db.collection("users").getDocuments()
        let allUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        
        // 2. Filter manually in Swift
        // Only keep users whose ID is in the requested 'ids' list
        let filteredUsers = allUsers.filter { user in
            guard let uid = user.id else { return false }
            return ids.contains(uid)
        }
        
        return filteredUsers
    }
    
    // MARK: - 3. FRIENDSHIP (ADD/REMOVE)
    func updateFriendStatus(currentUserId: String, targetUserId: String, isFriending: Bool) async throws {
        let batch = db.batch()
        
        let currentUserRef = db.collection("users").document(currentUserId)
        let targetUserRef = db.collection("users").document(targetUserId)
        
        if isFriending {
            // Add Friend
            batch.updateData(["friendIds": FieldValue.arrayUnion([targetUserId])], forDocument: currentUserRef)
            batch.updateData(["friendIds": FieldValue.arrayUnion([currentUserId])], forDocument: targetUserRef)
        } else {
            // Unfriend
            batch.updateData(["friendIds": FieldValue.arrayRemove([targetUserId])], forDocument: currentUserRef)
            batch.updateData(["friendIds": FieldValue.arrayRemove([currentUserId])], forDocument: targetUserRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - 4. RATING SYSTEM (TRANSACTIONS)
    
    // A. ADD RATING
    func addRating(rating: RatingFor) async throws {
        let ratingRef = db.collection("ratings").document()
        let userRef = db.collection("users").document(rating.otherUserId)
        
        // Transaction to calculate average safely
        _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let userDoc = try transaction.getDocument(userRef)
                guard let user = try? userDoc.data(as: User.self) else { return nil }
                
                // Math: Calculate new average
                let oldTotal = user.rating * Double(user.ratingCount)
                let newCount = user.ratingCount + 1
                let newTotal = oldTotal + Double(rating.num)
                let newAvg = newTotal / Double(newCount)
                
                // Write
                try transaction.setData(from: rating, forDocument: ratingRef)
                transaction.updateData(["rating": newAvg, "ratingCount": newCount], forDocument: userRef)
                
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        })
    }
    
    // B. UPDATE RATING
    func updateRating(ratingId: String, newNum: Int, otherUserId: String) async throws {
        let ratingRef = db.collection("ratings").document(ratingId)
        let userRef = db.collection("users").document(otherUserId)
        
        _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let userDoc = try transaction.getDocument(userRef)
                let ratingDoc = try transaction.getDocument(ratingRef)
                
                guard let user = try? userDoc.data(as: User.self),
                      let oldRating = try? ratingDoc.data(as: RatingFor.self) else { return nil }
                
                // Math: Adjust average
                let currentTotal = user.rating * Double(user.ratingCount)
                let newTotal = currentTotal - Double(oldRating.num) + Double(newNum)
                let newAvg = newTotal / Double(user.ratingCount)
                
                // Write
                transaction.updateData(["num": newNum], forDocument: ratingRef)
                transaction.updateData(["rating": newAvg], forDocument: userRef)
                
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        })
    }
    
    // C. DELETE RATING
    func deleteRating(ratingId: String, otherUserId: String) async throws {
        let ratingRef = db.collection("ratings").document(ratingId)
        let userRef = db.collection("users").document(otherUserId)
        
        _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            do {
                let userDoc = try transaction.getDocument(userRef)
                let ratingDoc = try transaction.getDocument(ratingRef)
                
                guard let user = try? userDoc.data(as: User.self),
                      let oldRating = try? ratingDoc.data(as: RatingFor.self) else { return nil }
                
                // Math: Remove score from average
                let currentTotal = user.rating * Double(user.ratingCount)
                let newTotal = currentTotal - Double(oldRating.num)
                let newCount = user.ratingCount - 1
                let newAvg = newCount > 0 ? (newTotal / Double(newCount)) : 0.0
                
                // Write
                transaction.deleteDocument(ratingRef)
                transaction.updateData(["rating": newAvg, "ratingCount": newCount], forDocument: userRef)
                
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        })
    }
    
    // MARK: - 5. CHECK MY RATING
    func fetchMyRating(myId: String, otherUserId: String) async throws -> RatingFor? {
        let snapshot = try await db.collection("ratings")
            .whereField("userId", isEqualTo: myId)
            .whereField("otherUserId", isEqualTo: otherUserId)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: RatingFor.self)
    }
}
