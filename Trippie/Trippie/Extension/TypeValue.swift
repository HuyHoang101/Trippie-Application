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


extension String {
    // Kiểm tra xem chuỗi có chứa ít nhất 1 emoji không
    var containsEmoji: Bool {
        return unicodeScalars.contains { $0.isEmoji }
    }

    // KIỂM TRA CHÍNH: Chuỗi CHỈ chứa emoji, không chứa chữ hay số
    var isPureEmoji: Bool {
        guard !isEmpty else { return false }
        return unicodeScalars.allSatisfy { $0.isEmoji || $0.isEmojiModifier }
    }
}

extension UnicodeScalar {
    // Kiểm tra scalar có thuộc dải mã của Emoji không
    var isEmoji: Bool {
        switch value {
        case 0x1F600...0x1F64F, // Emoticons
             0x1F300...0x1F5FF, // Misc Symbols and Pictographs
             0x1F680...0x1F6FF, // Transport and Map
             0x1F1E6...0x1F1FF, // Regional Flags
             0x2600...0x26FF,   // Misc Symbols
             0x2700...0x27BF,   // Dingbats
             0xFE00...0xFE0F,   // Variation Selectors
             0x1F900...0x1F9FF: // Supplemental Symbols and Pictographs
            return true
        default:
            return false
        }
    }

    var isEmojiModifier: Bool {
        return value >= 0x1F3FB && value <= 0x1F3FF // Màu da...
    }
}

extension Date {
    func toNotificationFormat() -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        if calendar.isDateInToday(self) {
            return timeFormatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday \(timeFormatter.string(from: self))"
        } else {
            let fullFormatter = DateFormatter()
            fullFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            return fullFormatter.string(from: self)
        }
    }
}
