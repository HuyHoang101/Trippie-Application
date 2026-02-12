//
//  MediaService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/2/26.
//

import FirebaseStorage
import AVKit

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
        guard url.contains("firebasestorage.googleapis.com") || url.hasPrefix("gs://") else {
            return
        }
        // Firebase hỗ trợ tạo reference trực tiếp từ link URL cực tiện
        let fileRef = Storage.storage().reference(forURL: url)
        try await fileRef.delete()
    }
    
    
    func uploadVideo(fileURL: URL, path: String) async throws -> String {
        let asset = AVAsset(url: fileURL)
        
        // 1. Cấu hình Export Session để nén về 720p
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
            throw NSError(domain: "MediaService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không thể khởi tạo ExportSession"])
        }
        
        // Tạo đường dẫn tạm thời để lưu video đã nén
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 2. Thực hiện nén
        await exportSession.export()
        
        if exportSession.status == .completed {
            // 3. Đọc dữ liệu video đã nén
            let videoData = try Data(contentsOf: outputURL)
            
            // 4. Upload lên Firebase dùng hàm uploadMedia có sẵn của cậu
            let downloadURL = try await uploadMedia(data: videoData, path: path, contentType: "video/mp4")
            
            // Dọn dẹp file tạm sau khi xong
            try? FileManager.default.removeItem(at: outputURL)
            
            return downloadURL
        } else {
            throw exportSession.error ?? NSError(domain: "MediaService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nén video thất bại"])
        }
    }
}
