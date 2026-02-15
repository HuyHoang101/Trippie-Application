//
//  TrippieLoadingView2.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//
import UIKit

class TrippieLoadingView2: UIView {
    private let progressLayer = CAShapeLayer()
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopAnimation()
            } else {
                startAnimation()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        // Bán kính tự động theo chiều rộng của view
        let circularPath = UIBezierPath(arcCenter: .zero, radius: (bounds.width / 2) - 4, startAngle: 0, endAngle: CGFloat.pi * 1.5, clockwise: true)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.position = center
    }
    
    private func setupLayer() {
        progressLayer.strokeColor = UIColor.authBackground2.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        
        layer.addSublayer(progressLayer)
        startAnimation()
    }
    
    private func startAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1
        rotation.repeatCount = .infinity
        progressLayer.add(rotation, forKey: "spin")
    }
    
    // ✅ 3. Thêm hàm Stop để xóa animation khi ẩn (tiết kiệm CPU)
    private func stopAnimation() {
        progressLayer.removeAllAnimations()
    }
}
