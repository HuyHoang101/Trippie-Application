//
//  Notification.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 20/2/26.
//

import Foundation
import FirebaseFirestore

struct NotificationItem: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let body: String
    let type: String
    let tripId: String
    var isRead: Bool
    @ServerTimestamp var createdAt: Date?
}
