//
//  MediaService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/2/26.
//

import FirebaseStorage

class MediaService {
    static let shared = MediaService()
    
    private let storage = Storage.storage().reference()
        
    // MARK: - 1. Upload Function
    /// Trả về link (URL String) sau khi upload thành công
    func uploadMedia(data: Data, path: String, contentType: String) async throws -> String {
        let fileRef = storage.child(path)
        
        // Thiết lập metadata để Firebase hiểu đây là ảnh hay video
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        // Thực hiện upload
        _ = try await fileRef.putDataAsync(data, metadata: metadata)
        
        // Lấy link download
        let downloadURL = try await fileRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - 2. Delete Function
    /// Xóa file dựa trên Link URL
    func deleteMedia(url: String) async throws {
        // Firebase hỗ trợ tạo reference trực tiếp từ link URL cực tiện
        let fileRef = Storage.storage().reference(forURL: url)
        try await fileRef.delete()
    }
}
