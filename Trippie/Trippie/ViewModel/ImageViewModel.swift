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
    @Published var VideoThumbnail: String = ""
    @Published var videoUrl: String = ""
    
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
        
        loading.send(true)
        let urlsToDelete = self.uploadedUrls + [self.videoUrl, self.VideoThumbnail]
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urlsToDelete {
                    group.addTask {
                        do {
                            try await self.imageService.deleteMedia(url: url)
                            //print("Delete file success \(url)")
                        } catch {
                            //print("Delete file failed \(url): \(error)")
                        }
                    }
                }
            }
            self.uploadedUrls = []
            self.videoUrl = ""
            self.VideoThumbnail = ""
            self.loading.send(false)
        }
    }
    
    func UploadVideo(fileUrl: URL, thumbnailData: Data, folder: String = "chats") {
        self.loading.send(true)
        
        Task {
            do {
                // Sử dụng TaskGroup để chạy song song
                try await withThrowingTaskGroup(of: (String, String).self) { group in
                    
                    group.addTask {
                        let videoPath = "\(folder)/video_\(UUID().uuidString).mp4"
                        let url = try await self.imageService.uploadVideo(fileURL: fileUrl, path: videoPath)
                        return ("video", url)
                    }
                    
                    group.addTask {
                        let url = try await self.uploadSingleImage(thumbnailData, folder: folder)
                        return ("thumb", url)
                    }
                    
                    // Thu thập kết quả trả về
                    for try await (type, url) in group {
                        if type != "video" {
                            self.VideoThumbnail = url
                        } else {
                            self.videoUrl = url
                        }
                    }
                }
            } catch {
                self.errorMessage.send("Upload video failed: \(error.localizedDescription)")
            }
            
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
