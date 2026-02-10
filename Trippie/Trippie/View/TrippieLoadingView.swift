//
//  TrippieLoadingView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Lottie

class TrippieLoadingView: UIView {
    
    private var isAnimating = false
    
    var isBus: Bool = true
    
    // MARK: - UI COMPONENTS
    
    //1. LABEL LOADING
    private lazy var letterViews: [UILabel] = []
    private lazy var dotViews: [UIView] = []
    
    private let letterStack = UIStackView.customStack(axis: .horizontal, alignment: .bottom, distribution: .fill, stackSpacing: 1)
    
    private let dotStack = UIStackView.customStack(axis: .horizontal, alignment: .bottom, distribution: .fill, stackSpacing: 4)
    
    private let busAnimationView: LottieAnimationView = {
        let lottie = LottieAnimationView(name: "bus_loading")
        lottie.loopMode = .loop
        lottie.contentMode = .scaleAspectFit
        lottie.translatesAutoresizingMaskIntoConstraints = false
        return lottie
    }()
    
    private let mainStack = UIStackView.customStack(axis: .vertical, alignment: .center, distribution: .fill, stackSpacing: 0)
    
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required  init?(coder: NSCoder) {
        fatalError()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        
        let text = "Loading"
        
        let font = AppTheme.Font.mainMedium(size: 14)
        
        for char in text {
            let label = UILabel.customLabel(text: String(char), font: font, textColor: .white)
            
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOffset = CGSize(width: 0, height: 2)
            label.layer.shadowRadius = 3
            label.layer.shadowOpacity = 0.5
            label.layer.masksToBounds = false
            
            letterStack.addArrangedSubview(label)
            letterViews.append(label)
        }
        
        for _ in 0...2 {
            let dot = UIView()
            dot.backgroundColor = .white
            dot.layer.cornerRadius = 1.7
            
            dot.layer.shadowColor = UIColor.black.cgColor
            dot.layer.shadowOffset = CGSize(width: 0, height: 1)
            dot.layer.shadowRadius = 2
            dot.layer.shadowOpacity = 0.4
            
            dotStack.addArrangedSubview(dot)
            dotViews.append(dot)
            
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 3.4).isActive = true
            dot.heightAnchor.constraint(equalTo: dot.widthAnchor).isActive = true
        }
        
        let textRowStack = UIStackView(arrangedSubviews: [letterStack, dotStack])
        textRowStack.axis = .horizontal
        textRowStack.spacing = 4 // Khoảng cách giữa chữ 'g' và dấu chấm đầu tiên
        textRowStack.alignment = .bottom
        
        mainStack.addArrangedSubview(textRowStack)
        mainStack.addArrangedSubview(busAnimationView)
        
        addSubview(mainStack)
        
        if isBus {
            busAnimationView.isHidden = false
        } else {
            busAnimationView.isHidden = true
        }
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
                        
            // Xe bus rộng 1/4 màn hình
            busAnimationView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.2),
            busAnimationView.heightAnchor.constraint(equalTo: busAnimationView.widthAnchor)
        ])
    }
    
    
    // MARK: - ANIMATION WAVE
    func start() {
        if isAnimating { return } // Tránh gọi chồng chéo
        isAnimating = true
        busAnimationView.play()
        animateWave()
    }
    
    private func animateWave() {
            guard isAnimating else { return }
            
            let allItems: [UIView] = letterViews + dotViews
            let totalDuration = 0.2 // Thời gian nhảy lên
            let waveInterval = 0.1  // Độ trễ giữa các chữ
            let pauseDuration = 0.3 // Thời gian nghỉ giữa các đợt sóng
            
            // Tính tổng thời gian để cả hàng hoàn thành việc nhảy lên và xuống
            // = (Delay của thằng cuối cùng) + (Thời gian nhảy lên + xuống)
            let totalWaveTime = (Double(allItems.count - 1) * waveInterval) + totalDuration
            
            for (index, item) in allItems.enumerated() {
                let delay = Double(index) * waveInterval
                
                // 1. Animation nhảy lên
                UIView.animate(withDuration: totalDuration / 2, // Lên nhanh
                               delay: delay,
                               options: [.curveEaseOut], // Lên chậm dần
                               animations: {
                    item.transform = CGAffineTransform(translationX: 0, y: -6)
                }) { _ in
                    // 2. Animation rơi xuống (Completion của nhảy lên)
                    UIView.animate(withDuration: totalDuration / 2, // Xuống nhanh
                                   delay: 0,
                                   options: [.curveEaseIn], // Xuống nhanh dần
                                   animations: {
                        item.transform = .identity // Về vị trí cũ
                    }, completion: nil)
                }
            }
            
            // 3. Đệ quy: Chờ hết sóng + thời gian nghỉ -> Chạy lại
            DispatchQueue.main.asyncAfter(deadline: .now() + totalWaveTime + pauseDuration) { [weak self] in
                // Kiểm tra lại cờ isAnimating phòng trường hợp view đã bị ẩn trong lúc chờ
                guard let self = self, self.isAnimating else { return }
                self.animateWave() // <--- GỌI LẠI CHÍNH NÓ
            }
        }

    func stop() {
        isAnimating = false
        busAnimationView.stop()
        layer.removeAllAnimations()
        // Reset vị trí
        (letterViews + dotViews).forEach { $0.transform = .identity }
    }
}
