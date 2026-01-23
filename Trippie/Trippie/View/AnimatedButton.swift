//
//  AnimatedButton.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

class AnimatedButton: UIButton {
    
    // Biến cờ để biết nút này có phải là nút tròn không
    var isCircle: Bool = false
    
    // Override lại trạng thái highlighted để làm animation
    // Khi người dùng chạm vào (true) -> Thu nhỏ
    // Khi thả tay ra (false) -> Phóng to lại
    override var isHighlighted: Bool {
        didSet {
            let scale: CGFloat = isHighlighted ? 0.92 : 1.0
            
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                usingSpringWithDamping: 0.8, // Hiệu ứng lò xo nhẹ
                initialSpringVelocity: 0.5,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: {
                    self.transform = CGAffineTransform(scaleX: scale, y: scale)
                    // self.alpha = self.isHighlighted ? 0.8 : 1.0
                }, completion: nil
            )
        }
    }
    
    // Override layoutSubviews để luôn đảm bảo nút tròn xoe nếu là isCircle
    override func layoutSubviews() {
        super.layoutSubviews()
        if isCircle {
            self.layer.cornerRadius = self.bounds.height / 2
        }
    }
}
