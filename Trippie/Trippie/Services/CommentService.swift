//
//  CommentService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Foundation
import FirebaseFirestore

class CommentService {
    static let shared = CommentService()
    private let db = Firestore.firestore()
    
    // Biến lưu con trỏ phân trang (Pagination)
    private var lastDocumentSnapshot: DocumentSnapshot?
    
    // Listener quản lý
    private var listenerRegistration: ListenerRegistration?
    
    // MARK: - 1. REALTIME LISTENER (20 TIN MỚI NHẤT)
    func listenToLatestComments(tripId: String, completion: @escaping ([Comment]) -> Void) {
        // Query: Lấy 20 tin MỚI NHẤT (DESC)
        let query = db.collection("trips").document(tripId).collection("comments")
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
        
        listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Lỗi listening: \(error?.localizedDescription ?? "N/A")")
                return
            }
            
            // Lưu con trỏ document cuối cùng để dùng cho Load More
            if let lastDoc = snapshot.documents.last {
                self.lastDocumentSnapshot = lastDoc
            }
            
            // Convert data
            let comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
            
            // Trả về background thread, ViewModel sẽ lo việc dispatch main
            completion(comments)
        }
    }
    
    // MARK: - 2. LOAD MORE (PAGINATION)
    func fetchOlderComments(tripId: String) async throws -> [Comment] {
        guard let lastDoc = lastDocumentSnapshot else {
            return [] // Hết dữ liệu hoặc chưa load lần đầu
        }
        
        // Query: Lấy tiếp 20 tin sau cái cuối cùng đang có
        let query = db.collection("trips").document(tripId).collection("comments")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: 20)
        
        let snapshot = try await query.getDocuments()
        
        // Cập nhật con trỏ mới
        if let newLastDoc = snapshot.documents.last {
            self.lastDocumentSnapshot = newLastDoc
        }
        
        let olderComments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
        return olderComments
    }
    
    // MARK: - 3. SEND COMMENT
    func sendComment(tripId: String, comment: Comment) async throws {
        let collectionRef = db.collection("trips").document(tripId).collection("comments")
        try collectionRef.addDocument(from: comment)
    }
    
    // MARK: - 4. EDIT COMMENT
    func editComment(tripId: String, comment: Comment) async throws {
        guard let commentId = comment.id else { return }
        
        var updatedComment = comment
        updatedComment.updatedAt = Date()
        
        try db.collection("trips").document(tripId)
            .collection("comments").document(commentId)
            .setData(from: updatedComment, merge: true)
    }
    
    // MARK: - 5. SOFT DELETE
    func softDeleteComment(tripId: String, commentId: String) async throws {
        let docRef = db.collection("trips").document(tripId)
            .collection("comments").document(commentId)
        
        // Chỉ update message về rỗng, giữ lại document
        try await docRef.updateData([
            "message": "",
            "mediaUrls": [],
            "updatedAt": Date()
        ])
    }
    
    // MARK: - CLEANUP
    func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        lastDocumentSnapshot = nil
    }
}
