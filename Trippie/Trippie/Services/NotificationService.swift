//
//  NotificationService.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 20/2/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    
    // Trả về tuple gồm danh sách và con trỏ cuối cùng
    func fetchNotifications(lastDocument: DocumentSnapshot? = nil) async throws -> (notifications: [NotificationItem], lastDoc: DocumentSnapshot?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please login first."])
        }
        
        var query = db.collection("users").document(userId).collection("notifications")
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
        
        // Nếu có con trỏ thì lấy tiếp từ đó
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        let notifications = snapshot.documents.compactMap { try? $0.data(as: NotificationItem.self) }
        
        return (notifications, snapshot.documents.last)
    }
    
    func updateRead(id: String) async throws -> NotificationItem {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please login first."])
        }
        
        let docRef = db.collection("users").document(userId).collection("notifications").document(id)
        
        // 1. Cập nhật cờ isRead trên Firebase
        try await docRef.updateData(["isRead": true])
        
        // 2. Kéo data mới nhất về và trả ra ngoài
        let snapshot = try await docRef.getDocument()
        guard let updatedNotification = try? snapshot.data(as: NotificationItem.self) else {
            throw NSError(domain: "Data", code: 404, userInfo: [NSLocalizedDescriptionKey: "Notification not found."])
        }
        
        return updatedNotification
    }
}
