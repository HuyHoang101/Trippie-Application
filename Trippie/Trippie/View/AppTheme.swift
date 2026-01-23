//
//  AppTheme.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import UIKit

struct AppTheme {
    
    // MARK: - COLORS
    // Tớ tạo các biến static để gọi cho gọn, đỡ phải gõ string nhiều lần dễ sai
    static var authBg1: UIColor { return UIColor(named: "AuthBackground1") ?? .systemBlue }
    static var authBg2: UIColor { return UIColor(named: "AuthBackground2") ?? .systemTeal }
    static var contentBg: UIColor { return UIColor(named: "Background") ?? .white } // CCE0FF
    static var darkBg: UIColor { return UIColor(named: "DarkModeBackground") ?? .black }
    
    
    // MARK: - 1. MAIN AUTH BACKGROUND
    // Logic: Light Mode -> Gradient (Tím -> Xanh) | Dark Mode -> Màu DarkModeBackground
    static func applyAuthBackground(to view: UIView) {
        
        // Bước 1: Dọn dẹp layer cũ (để tránh bị chồng layer khi xoay màn hình hoặc đổi theme)
        view.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        // Bước 2: Kiểm tra Dark Mode
        if view.traitCollection.userInterfaceStyle == .dark {
            // --- DARK MODE ---

            view.backgroundColor = darkBg
        } else {
            // --- LIGHT MODE ---
            
            view.backgroundColor = .clear
            
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                authBg1.cgColor, // BB8EFF
                authBg2.cgColor  // 8BB9FF
            ]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // Giữa trên
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)   // Giữa dưới
            gradientLayer.frame = view.bounds
            
            // Chèn layer gradient xuống dưới cùng
            view.layer.insertSublayer(gradientLayer, at: 0)
        }
    }
    
    // MARK: - 2. FADE BACKGROUND (Glass Effect)
    // Logic: White -> White -> Background (CCE0FF - 0.1)
    static func applyFadeBackground(to view: UIView) {
        view.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        
        let bottomColor = contentBg.withAlphaComponent(0.1)
        
        gradientLayer.colors = [
            UIColor.white.cgColor,                          // 0%
            UIColor.white.cgColor,                          // 50%
            bottomColor.cgColor                             // 100%
        ]
        
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}


extension AppTheme {
    struct Font {
        static func mainBlack(size: CGFloat) -> UIFont {
            return UIFont(name: "Montserrat-Black", size: size) ?? .systemFont(ofSize: size, weight: .heavy)
        }
        
        static func mainBold(size: CGFloat) -> UIFont {
            return UIFont(name: "Montserrat-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
        }
        
        static func mainMedium(size: CGFloat) -> UIFont {
            return UIFont(name: "Montserrat-Medium", size: size) ?? .systemFont(ofSize: size, weight: .medium)
        }
        static func mainRegular(size: CGFloat) -> UIFont {
            return UIFont(name: "Montserrat-Regular", size: size) ?? .systemFont(ofSize: size, weight: .regular)
        }
    }
}
