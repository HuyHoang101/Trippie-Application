//
//  Extension.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//
import Foundation

// Helper để cắt mảng thành các phần nhỏ
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension String {
    func toSentenceCase() -> String {
        // 1. Thay thế "_" bằng " "
        let spacedString = self.replacingOccurrences(of: "_", with: " ")
        
        // 2. Viết hoa chữ cái đầu tiên và giữ nguyên phần còn lại
        return spacedString.prefix(1).capitalized + spacedString.dropFirst().lowercased()
    }
}
