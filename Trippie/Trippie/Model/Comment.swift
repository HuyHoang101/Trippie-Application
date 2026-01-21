//
//  Comment.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

struct Comment: Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userAvatar: String
    var role: UserRole
    
    var mediaUrls: [String]
    var message: String
    
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    var isEdit: Bool {
        guard let created = createdAt, let updated = updatedAt else {
            return false
        }
        return created < updated
    }
}
