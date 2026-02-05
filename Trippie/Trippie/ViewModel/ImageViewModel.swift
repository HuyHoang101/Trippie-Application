//
//  Untitled.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Combine
import UIKit

@MainActor
class ImageViewModel {
    static let shared = ImageViewModel()
    
    @Published var uploadedUrls: [String] = []
    
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    
    //MARK: - PROPERTY
    private let imageService = MediaService.shared
    
    
    // MARK: - LOGIC
    func uploadImages(_ images: [UIImage], folder: String = "trips") {
        guard !images.isEmpty else { return }
        
        loading.send(true)
        var tempUrls: [String] = [] // Mảng tạm để hứng link
        
        Task {
            do {
                // Dùng TaskGroup để upload song song (Nhanh gấp N lần)
                try await withThrowingTaskGroup(of: String.self) { group in
                    for image in images {
                        group.addTask {
                            // Gọi lại logic upload đơn lẻ, nhưng chờ kết quả
                            return try await self.uploadSingleImage(image, folder: folder)
                        }
                    }
                    
                    // Gom kết quả khi từng task hoàn thành
                    for try await url in group {
                        tempUrls.append(url)
                    }
                }
                
                // Sau khi TẤT CẢ đã xong
                self.uploadedUrls = tempUrls
                print("DEBUG: Đã upload xong toàn bộ: \(self.uploadedUrls)")
                
            } catch {
                self.errorMessage.send("Lỗi upload batch: \(error.localizedDescription)")
            }
            
            self.loading.send(false)
        }
    }
    
    func deleteAllImages() {
        guard !uploadedUrls.isEmpty else { return }
        
        loading.send(true)
        let urlsToDelete = self.uploadedUrls
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urlsToDelete {
                    group.addTask {
                        do {
                            try await self.imageService.deleteMedia(url: url)
                        } catch {
                            print("Delete file failed \(url): \(error)")
                        }
                    }
                }
            }
            self.uploadedUrls = []
            print("DEBUG: Đã xóa toàn bộ ảnh")
            self.loading.send(false)
        }
    }
    
    
    // MARK: - Helper: Logic Upload Đơn
    private func uploadSingleImage(_ image: UIImage, folder: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot process image data"])
        }
        
        let fileName = "\(folder)/\(UUID().uuidString).jpg"
        
        return try await imageService.uploadMedia(
            data: imageData,
            path: fileName,
            contentType: "image/jpeg"
        )
    }
}
