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
    @Published var uploadedUrls: [String] = []
    
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    
    //MARK: - PROPERTY
    private let imageService = MediaService.shared
    
    
    // MARK: - LOGIC
    func uploadImages(_ imagesData: [Data], folder: String = "trips") {
        guard !imagesData.isEmpty else { return }
        
        loading.send(true)
        var tempUrls: [String] = [] // Mảng tạm để hứng link
        
        Task {
            do {
                // Dùng TaskGroup để upload song song (Nhanh gấp N lần)
                try await withThrowingTaskGroup(of: String.self) { group in
                    for imageData in imagesData {
                        group.addTask {
                            // Gọi lại logic upload đơn lẻ, nhưng chờ kết quả
                            return try await self.uploadSingleImage(imageData, folder: folder)
                        }
                    }
                    
                    // Gom kết quả khi từng task hoàn thành
                    for try await url in group {
                        tempUrls.append(url)
                    }
                }
                
                // Sau khi TẤT CẢ đã xong
                self.uploadedUrls = tempUrls
                //print("DEBUG: Đã upload xong toàn bộ: \(self.uploadedUrls)")
                
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
                            //print("Delete file failed \(url): \(error)")
                        }
                    }
                }
            }
            self.uploadedUrls = []
            self.loading.send(false)
        }
    }
    
    
    // MARK: - Helper: Logic Upload Đơn
    private func uploadSingleImage(_ imageData: Data, folder: String) async throws -> String {
        let fileName = "\(folder)/\(UUID().uuidString).jpg"
        
        return try await imageService.uploadMedia(
            data: imageData,
            path: fileName,
            contentType: "image/jpeg"
        )
    }
}
