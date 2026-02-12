//
//  TrippieLoadingView2.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//
import UIKit

class TrippieLoadingView2: UIView {
    private let progressLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayer() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 20, startAngle: 0, endAngle: CGFloat.pi * 1.5, clockwise: true)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.systemBlue.cgColor // Màu giống ảnh của cậu
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 4
        progressLayer.lineCap = .round
        progressLayer.position = center
        
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
}
