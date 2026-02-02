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
    @Published var url: String? = nil
    
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    
    //MARK: - PROPERTY
    private let imageService = MediaService.shared
    
    
    // MARK: - LOGIC
    func uploadImage(_ image: UIImage, folder: String) {
        // 1. Chuyển đổi sang Data (Ưu tiên JPEG cho ảnh để nhẹ dung lượng)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage.send("Can not solve image data.")
            return
        }
        
        // 2. Bật trạng thái Loading
        loading.send(true)
        
        Task {
            do {
                let fileName = "\(folder)/\(UUID().uuidString).jpg"
                
                // 3. Thực hiện upload qua Service
                let downloadUrl = try await imageService.uploadMedia(
                    data: imageData,
                    path: fileName,
                    contentType: "image/jpeg"
                )
                
                // 4. Cập nhật kết quả thành công
                self.url = downloadUrl
                print("DEBUG: Upload thành công: \(downloadUrl)")
                
            } catch {
                // 5. Xử lý lỗi
                self.errorMessage.send("Lỗi upload: \(error.localizedDescription)")
            }
            
            // 6. Tắt Loading dù thành công hay thất bại
            self.loading.send(false)
        }
    }
    
    func deleteImage(_ imageUrl: String) {
        loading.send(true)
        
        Task {
            do {
                try await imageService.deleteMedia(url: imageUrl)
                loading.send(false)
            } catch {
                loading.send(false)
                errorMessage.send(error.localizedDescription)
            }
        }
    }
}
