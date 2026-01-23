//
//  TrippieImageView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit
import SDWebImage

class TrippieImageView: UIView {
    
    // MARK: - SUBVIEW
    // Đây là cái ảnh thật sự
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill // Luôn fill đầy khung
        iv.clipsToBounds = true // Cắt những phần thừa ra ngoài bo góc
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - PROPERTIES
    private var style: TrippieImageStyle = .circle
    
    
    
    // MARK: - INIT
    // Init mặc định (dùng trong code)
    init(style: TrippieImageStyle, isShadow: Bool = false, borderColor: UIColor? = nil) {
        self.style = style
        super.init(frame: .zero)
        setupLayout()
        configureStyle(isShadow: isShadow, borderColor: borderColor)
    }
    
    // Init bắt buộc (nếu dùng storyboard - ít dùng)
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
        // 1. Setup Border (Gắn vào imageView bên trong)
        if let border = borderColor {
            imageView.layer.borderWidth = 1.5 // Độ dày viền
            imageView.layer.borderColor = border.cgColor
        }
        
        // 2. Setup Shadow (Gắn vào Container bên ngoài - SELF)
        // Lưu ý: Container phải clipsToBounds = false thì mới thấy bóng
        if isShadow {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.2 // Độ đậm bóng
            self.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.layer.shadowRadius = 6
            self.clipsToBounds = false
        }
    }
    
    // MARK: - LIFECYCLE (Xử lý bo tròn động)
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Tính toán bo góc mỗi khi layout thay đổi kích thước
        switch style {
        case .circle:
            // Lấy cạnh ngắn nhất chia đôi để đảm bảo luôn tròn
            let radius = min(bounds.width, bounds.height) / 2
            imageView.layer.cornerRadius = radius
            
            // Nếu có bóng, update shadow path để bóng cũng tròn theo
            if layer.shadowOpacity > 0 {
                layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
            }
            
        case .rounded(let radius, let corners):
            imageView.layer.cornerRadius = radius
            
            // Nếu có chỉ định góc cụ thể (ví dụ chỉ bo 2 góc trên)
            if let specificCorners = corners {
                imageView.layer.maskedCorners = specificCorners
            }
            
            // Update shadow path hình chữ nhật bo góc
            if layer.shadowOpacity > 0 {
                layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
            }
        }
    }
    
    // MARK: - PUBLIC METHOD (LOAD ẢNH)
    func setImage(url: String?, placeholder: String = "placeholder_img") {
        guard let urlString = url, let validUrl = URL(string: urlString) else {
            imageView.image = UIImage(named: placeholder)
            return
        }
        
        // Dùng SDWebImage load ảnh
        imageView.sd_setImage(with: validUrl, placeholderImage: UIImage(named: placeholder), options: [.scaleDownLargeImages])
    }
    
    // Hàm set ảnh thường (nếu có dùng local)
    func setLocalImage(name: String) {
        imageView.image = UIImage(named: name)
    }
}
