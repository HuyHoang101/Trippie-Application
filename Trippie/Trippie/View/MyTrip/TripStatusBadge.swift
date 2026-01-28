//
//  TripStatusBadge.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//

import UIKit

class TripStatusBadge: UIView {
    
    // MARK: - UI Elements
    private let label = UILabel()
    private let shimmerLayer = CAGradientLayer()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Cập nhật frame cho layer animation khi view thay đổi kích thước
        shimmerLayer.frame = bounds
        layer.cornerRadius = bounds.height / 2 // Bo tròn dạng viên thuốc (Capsule)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        self.clipsToBounds = true // Để animation không bị tràn ra ngoài viên thuốc
        
        // Setup Label
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        // Setup Shimmer Layer (Lớp ánh sáng)
        shimmerLayer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        shimmerLayer.locations = [0.0, 0.5, 1.0]
        // Xoay nghiêng 1 chút cho đẹp (chéo 45 độ)
        shimmerLayer.startPoint = CGPoint(x: 0.0, y: 0.4)
        shimmerLayer.endPoint = CGPoint(x: 1.0, y: 0.6)
        layer.addSublayer(shimmerLayer)
        
        // Constraints cho Label (Padding)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Configuration
    func configure(status: PersonalStatus) {
        
        label.text = status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        
        // 2. Set Background Color
        switch status {
        case .upcoming:
            backgroundColor = #colorLiteral(red: 0.09362520865, green: 0.6473980029, blue: 0.9686274529, alpha: 1)
        case .onGoing:
            backgroundColor = #colorLiteral(red: 1, green: 0.8977437231, blue: 0, alpha: 1)
        case .completed:
            backgroundColor = #colorLiteral(red: 0.2097581099, green: 0.9218901801, blue: 0, alpha: 1)
        case .cancel:
            backgroundColor = #colorLiteral(red: 0.9793856906, green: 0.239348192, blue: 0.005527625329, alpha: 1)
        }
        
        // 3. Start Animation
        startShimmerAnimation()
    }
    
    private func startShimmerAnimation() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 2.0 // Thời gian chạy 1 vòng
        animation.repeatCount = .infinity // Lặp vô hạn
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        shimmerLayer.add(animation, forKey: "shimmerEffect")
    }
}
