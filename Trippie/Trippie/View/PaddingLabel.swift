//
//  PaddingLabel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

class PaddingLabel: UILabel {
    var topInset: CGFloat = 5
    var bottomInset: CGFloat = 5
    var leftInset: CGFloat = 10
    var rightInset: CGFloat = 10
    var isCircle: Bool = true

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
    
    override var bounds: CGRect {
        didSet {
            // Ép Label phải trừ đi padding trái/phải khi tính toán số dòng
            let preferredWidth = bounds.width - (leftInset + rightInset)
            if preferredMaxLayoutWidth != preferredWidth {
                preferredMaxLayoutWidth = preferredWidth
            }
        }
    }

    // Tự động bo tròn khi layout thay đổi
    override func layoutSubviews() {
        super.layoutSubviews()
        // CornerRadius Full (Hình viên thuốc)
        if isCircle {
            self.layer.cornerRadius = self.bounds.height / 2
        } else {
            self.layer.cornerRadius = 12
        }
    }
}
