//
//  TrippieImageView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit

// 1. Tạo cache toàn cục (nằm ngoài class) để dùng chung cho mọi ảnh
private let globalImageCache = NSCache<NSString, UIImage>()

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
            let radius = min(bounds.width, bounds.height) / 2
            imageView.layer.cornerRadius = radius
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
        
        self.imageView.image = placeholder
        self.imageView.contentMode = .center // Icon để giữa cho đẹp
        
        // 3. Kiểm tra URL hợp lệ
        guard let urlString = url, let validUrl = URL(string: urlString) else { return }
        
        // 4. KIỂM TRA CACHE: Nếu có ảnh rồi thì lấy ra dùng luôn
        if let cachedImage = globalImageCache.object(forKey: urlString as NSString) {
            self.imageView.image = cachedImage
            self.imageView.contentMode = .scaleAspectFill
            return
        }
        
        // 5. TẢI ẢNH (Background Thread)
        currentTask = URLSession.shared.dataTask(with: validUrl) { [weak self] data, response, error in
            
            // Nếu lỗi hoặc bị cancel thì dừng
            if let error = error {
                // print("❌ Lỗi tải: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let downloadedImage = UIImage(data: data) else { return }
            
            // Lưu vào Cache để lần sau dùng lại
            globalImageCache.setObject(downloadedImage, forKey: urlString as NSString)
            
            // 6. Cập nhật UI (Main Thread)
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Chuyển mode về fill để ảnh đẹp
                self.imageView.contentMode = .scaleAspectFill
                
                // Hiệu ứng hiện ảnh mượt mà (Fade in)
                UIView.transition(with: self.imageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    self.imageView.image = downloadedImage
                }, completion: nil)
            }
        }
        
        // Bắt đầu tải
        currentTask?.resume()
    }
    
    // Hàm set ảnh local
    func setLocalImage(name: String) {
        imageView.image = UIImage(named: name)
        imageView.contentMode = .scaleAspectFill
    }
}
