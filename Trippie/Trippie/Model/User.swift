//
//  user.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

struct User: Codable {
    @DocumentID var id: String?
    
    var avatarUrl: String
    var name: String
    
    var email: String
    var phone: String
    var address: String
    var aboutMe: String
    
    var rating: Double
    var ratingCount: Int
    
    var friendIds: [String]
    
    var fcmToken: String
    
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
