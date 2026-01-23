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

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
    
    // Tự động bo tròn khi layout thay đổi
    override func layoutSubviews() {
        super.layoutSubviews()
        // CornerRadius Full (Hình viên thuốc)
        self.layer.cornerRadius = self.bounds.height / 2
    }
}
