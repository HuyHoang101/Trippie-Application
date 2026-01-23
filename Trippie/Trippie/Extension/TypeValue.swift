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
