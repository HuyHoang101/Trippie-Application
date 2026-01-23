//
//  ChatInputTextView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine // Import cái này

protocol ChatInputDelegate: AnyObject {
    func inputTextViewDidContentSizeChange(_ textView: ChatInputTextView)
}

class ChatInputTextView: UITextView {
    
    // MARK: - PROPERTIES
    weak var heightConstraint: NSLayoutConstraint?
    weak var chatDelegate: ChatInputDelegate?
    
    private let maxLines: CGFloat = 4
    private let minHeight: CGFloat = 40
    private var cancellables = Set<AnyCancellable>() // Túi chứa rác Combine
    
    // Placeholder binding
    var placeholder: String? {
        didSet {
            // Setup lần đầu
            if text.isEmpty {
                text = placeholder
                textColor = .lightGray
            }
        }
    }
    
    // MARK: - INIT
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupUI()
        setupBinding()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupBinding()
    }
    
    // MARK: - SETUP
    private func setupUI() {
        self.isScrollEnabled = false
        self.font = UIFont.systemFont(ofSize: 16)
        self.backgroundColor = .clear
        self.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        self.layer.cornerRadius = 18
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    // MARK: - BINDING (Thay thế NotificationCenter)
    private func setupBinding() {
        
        // 1. Lắng nghe text thay đổi (UITextView.textDidChangeNotification)
        // Dùng Combine Publisher của NotificationCenter nhưng viết gọn theo kiểu reactive
        NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: self)
            .compactMap { $0.object as? UITextView } // Đảm bảo đúng là view này
            .sink { [weak self] _ in
                self?.handleTextChange()
            }
            .store(in: &cancellables)
        
        // 2. Lắng nghe Begin Editing (Để xoá Placeholder)
        NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.text == self.placeholder && self.textColor == .lightGray {
                    self.text = ""
                    self.textColor = .label // Màu chữ chính
                }
            }
            .store(in: &cancellables)
        
        // 3. Lắng nghe End Editing (Để hiện lại Placeholder)
        NotificationCenter.default.publisher(for: UITextView.textDidEndEditingNotification, object: self)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.text.isEmpty {
                    self.text = self.placeholder
                    self.textColor = .lightGray
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - LOGIC
    private func handleTextChange() {
        guard let font = self.font else { return }
        
        // Tính toán chiều cao
        let maxHeight = (font.lineHeight * maxLines) + textContainerInset.top + textContainerInset.bottom
        let sizeToFit = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let newSize = self.sizeThatFits(sizeToFit)
        
        // Xử lý Constraints
        if newSize.height >= maxHeight {
            if !isScrollEnabled {
                isScrollEnabled = true
                updateHeightConstraint(constant: maxHeight)
            }
        } else {
            if isScrollEnabled {
                isScrollEnabled = false
            }
            updateHeightConstraint(constant: max(newSize.height, minHeight))
        }
    }
    
    private func updateHeightConstraint(constant: CGFloat) {
        if heightConstraint?.constant != constant {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                self.heightConstraint?.constant = constant
                self.superview?.layoutIfNeeded()
                self.chatDelegate?.inputTextViewDidContentSizeChange(self)
            }
        }
    }
}
