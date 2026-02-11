//
//  ImageUltils.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/10/26.
//

import UIKit

struct ImageUtils {
    static func downsample(imageData: Data, maxDimension: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else { return nil }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
    
    static func downsampleToData(imageData: Data, maxDimension: CGFloat, compressionQuality: CGFloat = 0.7) -> Data? {
        // 1. Tận dụng logic của hàm trên để lấy ảnh UIImage đã resize
        guard let resizedImage = downsample(imageData: imageData, maxDimension: maxDimension) else { return nil }
        
        // 2. Nén ngay lập tức thành Data
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
}
