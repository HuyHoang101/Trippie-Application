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
}
