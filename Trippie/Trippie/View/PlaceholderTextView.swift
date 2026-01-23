//
//  PlaceholderTextView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit

class PlaceholderTextView: UITextView {
    
    var placeholder: String? {
        didSet {
            // Khi set placeholder thì gán text luôn nếu đang rỗng
            if text.isEmpty {
                text = placeholder
                textColor = .lightGray
            }
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupObservers()
    }
    
    private func setupObservers() {
        // Lắng nghe sự kiện Bắt đầu gõ và Kết thúc gõ
        NotificationCenter.default.addObserver(self, selector: #selector(handleBeginEditing), name: UITextView.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEndEditing), name: UITextView.textDidEndEditingNotification, object: self)
    }
    
    @objc private func handleBeginEditing() {
        // Nếu text đang là placeholder và màu xám -> Xóa đi, đổi màu chữ về màu đen
        if text == placeholder && textColor == .lightGray {
            text = ""
            textColor = .label // Màu chữ chính thức
        }
    }
    
    @objc private func handleEndEditing() {
        // Nếu gõ xong mà rỗng -> Hiện lại placeholder và đổi màu xám
        if text.isEmpty {
            text = placeholder
            textColor = .lightGray
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
