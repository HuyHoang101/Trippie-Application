//
//  AnimatedButton.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

class AnimatedButton: UIButton {
    
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
}
