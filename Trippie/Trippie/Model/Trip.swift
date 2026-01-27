//
//  Trip.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

struct Trip: Codable { // Thêm Codable
    @DocumentID var id: String? // Tự lấy ID document
    var ownerId: String
    var ownerName: String
    var coverImage: String
    var title: String
    var description: String
    var tripRule: String?
    var location: String
    var country: String
    
    var tripType: TripType
    var status: TripStatus
    
    var members: [String]
    var pendingRequests: [String]
    var maxMember: Int
    var currentMember: Int
    
    
    var startTime: Date
    var dayIndex: Int
    
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    
    var isExpired: Bool {
        return startTime < Date()
    }
}
