//
//  TrippieImageView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
class GlobalCacheForApplication {
    // 1. Tạo cache toàn cục (nằm ngoài class) để dùng chung cho mọi ảnh
    static let globalImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
            // giới hạn 200MB (1024 * 1024 * 200)
            cache.totalCostLimit = 200 * 1024 * 1024
            return cache
    }()
    
    private static var allKeys = Set<NSString>()

    static func cacheImage(_ image: UIImage, for url: String, cost: Int) {
        let key = url as NSString
        globalImageCache.setObject(image, forKey: key, cost: cost)
        allKeys.insert(key)
    }
    
    // Hàm lấy ảnh từ cache (cập nhật lại Set nếu ảnh bị hệ thống tự xóa)
    static func getCachedImage(for url: String) -> UIImage? {
        let key = url as NSString
        guard let image = globalImageCache.object(forKey: key) else {
            allKeys.remove(key) // Nếu cache tự xóa thì ta cũng xóa key
            return nil
        }
        return image
    }
    
    static func clearAllCache() {
        globalImageCache.removeAllObjects()
        allKeys.removeAll()
    }
    
    static func calculateCurrentCacheSize() -> Double {
        var totalBytes = 0
        let keys = allKeys // Tạo bản sao để tránh lỗi crash khi thay đổi mảng lúc đang lặp
        
        for key in keys {
            if let image = globalImageCache.object(forKey: key) {
                let bytesPerPixel = 4
                // 💡 Quan trọng: Phải nhân với scale^2 vì ảnh Retina chiếm nhiều RAM hơn
                let sizeInBytes = Int(image.size.width * image.size.height * image.scale * image.scale) * bytesPerPixel
                totalBytes += sizeInBytes
            } else {
                // Nếu ảnh không còn trong NSCache, dọn dẹp luôn cái key này cho sạch
                allKeys.remove(key)
            }
        }
        return Double(totalBytes) / (1024 * 1024)
    }
}

class TrippieImageView: UIView {
    
    // MARK: - SUBVIEW
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill // Mặc định fill đầy
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        // Màu mặc định cho icon placeholder (màu xám nhạt cho tinh tế)
        iv.tintColor = .systemGray4
        return iv
    }()
    
    // MARK: - PROPERTIES
    private var style: TrippieImageStyle = .circle
    
    // Biến lưu task tải ảnh hiện tại (để có thể cancel)
    private var currentTask: URLSessionDataTask?
    
    // MARK: - INIT
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
    
    // MARK: - SETUP
    private func setupLayout() {
        self.backgroundColor = .clear
        
        // Add ảnh vào trong view container
        addSubview(imageView)
        
        // Pin 4 cạnh của ảnh dính chặt vào Container
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    private func configureStyle(isShadow: Bool, borderColor: UIColor?) {
        // 1. Setup Border
        if let border = borderColor {
            imageView.layer.borderWidth = 1.5
            imageView.layer.borderColor = border.cgColor
        }
        
        // 2. Setup Shadow
        if isShadow {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.2
            self.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.layer.shadowRadius = 6
            self.clipsToBounds = false
        }
    }
    
    // MARK: - LIFECYCLE (Xử lý bo tròn động)
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
    
    // MARK: - PUBLIC METHOD (LOAD ẢNH NATIVE)
    
    func setImage(url: String?, placeholderSystemName: String = "photo.on.rectangle.angled") {
        // 1. Hủy task cũ đang chạy (nếu có) để tránh nhảy ảnh lung tung
        currentTask?.cancel()
        
        // 2. Setup Placeholder (System Icon)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .light)
        let placeholder = UIImage(systemName: placeholderSystemName, withConfiguration: config)
        
        // 2.1. Đặt ảnh placeholder
        self.imageView.image = placeholder

        // 2.2. Chỉnh màu cho icon (SF Symbol) thành màu xám đậm
        self.imageView.tintColor = .systemGray5.withAlphaComponent(0.25)

        // 2.3. Đặt màu nền cho ImageView
        // Cậu dùng .systemGray6 hoặc tự pha màu gray đậm một chút
        self.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        self.clipsToBounds = true

        // 2.4. Căn giữa icon
        self.imageView.contentMode = .scaleAspectFit
        
        // 3. Kiểm tra URL hợp lệ
        self.imageView.backgroundColor = .white
        self.backgroundColor = .clear
        self.clipsToBounds = false
        guard let urlString = url, let validUrl = URL(string: urlString) else { return }
        
        // 4. KIỂM TRA CACHE: Nếu có ảnh rồi thì lấy ra dùng luôn
        if let cachedImage = GlobalCacheForApplication.globalImageCache.object(forKey: urlString as NSString) {
            self.imageView.image = cachedImage
            self.imageView.contentMode = .scaleAspectFill
            return
        }
        
        // 5. TẢI ẢNH và down size
        currentTask = URLSession.shared.dataTask(with: validUrl) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else { return }
                
                // --- TÍNH TOÁN KÍCH THƯỚC CỐ ĐỊNH (FIXED SIZE) ---
                
                let screenWidth = UIScreen.main.bounds.width
                let targetWidth = screenWidth - 40 // Trừ hao padding an toàn
                let scale = UIScreen.main.scale
                
                // Đây là con số Max Pixel (cạnh lớn nhất của ảnh sẽ không vượt quá số này)
                let maxDimension = targetWidth * scale
                
                // --- DOWNSAMPLE ---
                guard let downsampledImage = ImageUtils.downsample(imageData: data, maxDimension: maxDimension) else { return }
                
                // --- LƯU CACHE ---
                // Tính cost chuẩn xác
                let cost = Int(downsampledImage.size.width * downsampledImage.size.height * 4)
                GlobalCacheForApplication.cacheImage(downsampledImage, for: urlString, cost: cost)
                
                DispatchQueue.main.async {
                    self.imageView.contentMode = .scaleAspectFill
                    // Animation hiện ảnh
                    UIView.transition(with: self.imageView,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                        self.imageView.image = downsampledImage
                    }, completion: nil)
                }
            }
            currentTask?.resume()
    }
    
    // Hàm set ảnh local
    func setLocalImage(name: String) {
        imageView.image = UIImage(named: name)
        imageView.contentMode = .scaleAspectFill
    }
}
