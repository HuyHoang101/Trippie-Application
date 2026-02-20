//
//  ChatStateManager.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 20/2/26.
//

import Foundation

class ChatStateManager {
    static let shared = ChatStateManager()
    
    // Dùng Set lưu ID phòng chat cho nhẹ và tìm kiếm siêu tốc
    private var activeTripIds: Set<String> = []
    
    private init() {}
    
    func startListening(tripId: String) {
        activeTripIds.insert(tripId)
        print("🟢 Đã bật chặn thông báo rác cho trip: \(tripId)")
    }
    
    func stopListening(tripId: String) {
        activeTripIds.remove(tripId)
        print("🔴 Đã tắt chặn thông báo cho trip: \(tripId)")
    }
    
    func isListening(to tripId: String) -> Bool {
        return activeTripIds.contains(tripId)
    }
}
