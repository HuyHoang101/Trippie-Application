//
//  TrippieImageView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit

// MARK: - GLOBAL CACHE (Thread-Safe)
class GlobalCacheForApplication {
    
    // 1. Dùng NSLock để bảo vệ biến allKeys khi nhiều luồng truy cập cùng lúc
    private static let lock = NSLock()
    
    static let globalImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 200 * 1024 * 1024 // 200MB
        return cache
    }()
    
    // Set không phải là thread-safe, bắt buộc phải dùng Lock
    private static var allKeys = Set<NSString>()

    static func cacheImage(_ image: UIImage, for url: String, cost: Int) {
        let key = url as NSString
        globalImageCache.setObject(image, forKey: key, cost: cost)
        
        // Lock trước khi ghi vào Set
        lock.lock()
        allKeys.insert(key)
        lock.unlock()
    }
    
    static func getCachedImage(for url: String) -> UIImage? {
        let key = url as NSString
        // Kiểm tra nhanh, nếu có trả về luôn
        if let image = globalImageCache.object(forKey: key) {
            return image
        }
        
        // Nếu không có trong cache (đã bị evict), xóa key khỏi Set cho đồng bộ
        // (Cần lock vì remove cũng là ghi đổi dữ liệu)
        lock.lock()
        if allKeys.contains(key) {
            allKeys.remove(key)
        }
        lock.unlock()
        
        return nil
    }
    
    static func clearAllCache() {
        globalImageCache.removeAllObjects()
        lock.lock()
        allKeys.removeAll()
        lock.unlock()
    }
    
    // Tính toán size cũng cần Lock để tránh crash khi đang for-loop mà mảng bị thay đổi
    static func calculateCurrentCacheSize() -> Double {
        var totalBytes = 0
        
        lock.lock()
        let keysSnapshot = allKeys // Tạo bản sao snapshot trong vùng an toàn
        lock.unlock()
        
        for key in keysSnapshot {
            if let image = globalImageCache.object(forKey: key) {
                let bytesPerPixel = 4
                let sizeInBytes = Int(image.size.width * image.size.height * image.scale * image.scale) * bytesPerPixel
                totalBytes += sizeInBytes
            } else {
                // Dọn dẹp key rác (cần lock lại khi remove)
                lock.lock()
                allKeys.remove(key)
                lock.unlock()
            }
        }
        return Double(totalBytes) / (1024 * 1024)
    }
}

// MARK: - IMAGE VIEW
class TrippieImageView: UIView {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .systemGray4
        return iv
    }()
    
    private var style: TrippieImageStyle = .circle
    private var currentTask: URLSessionDataTask?
    
    // 💡 QUAN TRỌNG: Lưu URL hiện tại để so sánh khi tải xong
    private var currentURLString: String?
    
    init(style: TrippieImageStyle, isShadow: Bool = false, borderColor: UIColor? = nil) {
        self.style = style
        super.init(frame: .zero)
        setupLayout()
        configureStyle(isShadow: isShadow, borderColor: borderColor)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    private func setupLayout() {
        self.backgroundColor = .clear
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func configureStyle(isShadow: Bool, borderColor: UIColor?) {
        if let border = borderColor {
            imageView.layer.borderWidth = 1.5
            imageView.layer.borderColor = border.cgColor
        }
        if isShadow {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.2
            self.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.layer.shadowRadius = 6
            self.clipsToBounds = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch style {
        case .circle:
            let radius = bounds.width / 2
            imageView.layer.cornerRadius = radius
            self.layer.cornerRadius = radius
            if layer.shadowOpacity > 0 {
                layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
            }
        case .rounded(let radius, let corners):
            imageView.layer.cornerRadius = radius
            if let specificCorners = corners {
                imageView.layer.maskedCorners = specificCorners
            }
            if layer.shadowOpacity > 0 {
                layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
            }
        }
    }
    
    // MARK: - LOGIC LOAD ẢNH
    func setImage(url: String?, placeholderSystemName: String = "photo.on.rectangle.angled", pixel: CGFloat = 1024) {
        // 1. Hủy task cũ ngay lập tức
        currentTask?.cancel()
        
        // 2. Lưu lại URL mới nhất mà view này CẦN hiển thị
        currentURLString = url
        
        // 3. Validate URL
        guard let urlString = url, !urlString.isEmpty, let validUrl = URL(string: urlString) else {
            self.setPlaceholderImmediately(name: placeholderSystemName)
            return
        }
        
        // 4. CHECK CACHE (Dùng hàm getCachedImage đã sửa ở trên)
        if let cachedImage = GlobalCacheForApplication.getCachedImage(for: urlString) {
            self.imageView.image = cachedImage
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.backgroundColor = .white
            return
        }
        
        // 5. Nếu chưa có cache -> Set Placeholder NGAY LẬP TỨC (không dùng async để tránh nháy)
        self.setPlaceholderImmediately(name: placeholderSystemName)
        
        // 6. Tải ảnh
        let request = URLRequest(url: validUrl, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Nếu lỗi hoặc không có data
            guard let data = data, error == nil else {
                return // Giữ nguyên placeholder
            }
            
            // Xử lý Downsample trên Background Thread
            DispatchQueue.global(qos: .userInitiated).async {
                guard let downsampledImage = ImageUtils.downsample(imageData: data, maxDimension: pixel) else { return }
                
                // Lưu cache (Thread-safe)
                let cost = Int(downsampledImage.size.width * downsampledImage.size.height * 4)
                GlobalCacheForApplication.cacheImage(downsampledImage, for: urlString, cost: cost)
                
                // Về Main Thread để hiển thị
                DispatchQueue.main.async {
                    // 💡 CỰC KỲ QUAN TRỌNG: Kiểm tra xem Cell này còn cần URL này không?
                    // Nếu người dùng đã lướt đi chỗ khác (currentURLString đã thay đổi), thì bỏ qua ảnh này.
                    if self.currentURLString == urlString {
                        self.imageView.contentMode = .scaleAspectFill
                        self.imageView.backgroundColor = .white
                        
                        UIView.transition(with: self.imageView,
                                          duration: 0.25,
                                          options: .transitionCrossDissolve,
                                          animations: {
                            self.imageView.image = downsampledImage
                        }, completion: nil)
                    }
                }
            }
        }
        currentTask?.resume()
    }
    
    func setLocalImage(name: String) {
        currentURLString = nil // Reset URL string để tránh xung đột
        imageView.image = UIImage(named: name)
        imageView.contentMode = .scaleAspectFill
    }
    
    // Hàm set placeholder không cần async để tránh delay 1 frame
    private func setPlaceholderImmediately(name: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .light)
        let placeholder = UIImage(systemName: name, withConfiguration: config)
        
        self.imageView.image = placeholder
        self.imageView.tintColor = .systemGray5.withAlphaComponent(0.25)
        self.imageView.backgroundColor = .white // Hoặc .systemGray6
        self.imageView.contentMode = .scaleAspectFit
    }
}
