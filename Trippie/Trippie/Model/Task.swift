//
//  Task.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseFirestore

struct Task: Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    
    var creatorId: String // ID người tạo ra task (để check quyền xoá)
    var userName: String
    var userAvatar: String
    var userRole: UserRole
    
    var editBy: String    // Tên người sửa cuối cùng
    
    var dayIndex: Int
    var time: String
    
    @ServerTimestamp var createdAt: Date? // Tự động lấy giờ server
    @ServerTimestamp var updatedAt: Date?
}
