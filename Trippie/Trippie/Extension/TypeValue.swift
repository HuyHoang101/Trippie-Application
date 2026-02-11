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
    func loadResizedImage(targetSize: CGFloat = 1024) async -> Data? {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    guard let originalImage = image as? UIImage,
                          // Chuyển sang Data gốc để chuẩn bị xử lý
                          let originalData = originalImage.jpegData(compressionQuality: 1.0) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Resize và Nén
                    // Nếu thành công thì trả về data đã tối ưu, nếu lỗi thì trả về data gốc (đã nén nhẹ)
                    if let optimizedData = ImageUtils.downsampleToData(imageData: originalData, maxDimension: targetSize, compressionQuality: 0.7) {
                        continuation.resume(returning: optimizedData)
                    } else {
                        // Fallback: Nén ảnh gốc 0.7 nếu downsample thất bại
                        continuation.resume(returning: originalImage.jpegData(compressionQuality: 0.7))
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
