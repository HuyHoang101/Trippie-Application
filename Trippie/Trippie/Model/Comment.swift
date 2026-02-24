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
    
    var imageUrls: [String]
    var videoUrl: String
    var videoThumbnail: String
    var message: String
    var isDeleted: Bool?
    
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    var isEdit: Bool {
        guard let created = createdAt, let updated = updatedAt else {
            return false
        }
        return created < updated
    }
}
