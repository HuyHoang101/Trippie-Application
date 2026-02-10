//
//  Extension.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//
import Foundation
import PhotosUI
import UIKit

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

extension PHPickerResult {
    // Hàm này tự động load ảnh VÀ resize luôn, trả về ảnh đã nhỏ gọn
    func loadResizedImage(targetSize: CGFloat = 1024) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    guard let originalImage = image as? UIImage else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // 🟢 RESIZE NGAY TẠI ĐÂY (Dùng hàm trong ImageUtils tớ gửi bài trước)
                    // Chuyển sang data để downsample rồi chuyển lại image
                    if let data = originalImage.jpegData(compressionQuality: 1.0),
                       let resized = ImageUtils.downsample(imageData: data, maxDimension: targetSize) {
                        continuation.resume(returning: resized)
                    } else {
                        // Fallback nếu resize lỗi thì lấy ảnh gốc (hoặc nil tuỳ cậu)
                        continuation.resume(returning: originalImage)
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
