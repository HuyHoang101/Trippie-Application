//
//  ChatInputTextView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

// Protocol để báo ra ngoài khi chiều cao thay đổi (để view cha update layout)
protocol ChatInputViewDelegate: AnyObject {
    func chatInputViewDidContentSizeChange(_ chatInputView: ChatInputView)
}

class ChatInputView: UIView {
    
    // MARK: - PUBLISHERS & DELEGATES
    let isTypingPublisher = PassthroughSubject<Bool, Never>()
    weak var delegate: ChatInputViewDelegate?
    
    // MARK: - CONFIGURATION
    private let maxHeight: CGFloat = 92 // Chiều cao tối đa (Cậu set cứng ở đây hoặc truyền vào)
    private let minHeight: CGFloat = 40
    
    // MARK: - UI COMPONENTS
    // 1. ScrollView bên ngoài: Giới hạn vùng nhìn
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true // Luôn hiện thanh scroll nếu cần
        sv.showsHorizontalScrollIndicator = false
        sv.layer.cornerRadius = 18
        sv.backgroundColor = .clear
        return sv
    }()
    
    // 2. TextView bên trong: Tự giãn full chiều cao nội dung
    // Private để không ai chọc vào đổi lung tung
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.isScrollEnabled = false // QUAN TRỌNG: Tắt scroll để nó tự giãn
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        tv.delegate = self // Tự lắng nghe chính mình
        return tv
    }()
    
    // 1. Thêm Label làm Placeholder (Nằm đè lên TextView)
    private let placeholderLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Type a message..."
        lb.font = UIFont.systemFont(ofSize: 16)
        lb.textColor = .lightGray
        lb.backgroundColor = .clear
        lb.isUserInteractionEnabled = false // Để tap xuyên qua vào TextView
        return lb
    }()
    
    // MARK: - INTERNAL STATE
    private var cancellables = Set<AnyCancellable>()
    private var heightConstraint: NSLayoutConstraint?
    
    // Wrapper properties để bên ngoài dùng giống hệt TextView cũ
    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            textViewDidChange(textView) // Trigger tính toán lại
            checkPlaceholder()
        }
    }
    
    var placeholder: String? {
        didSet { checkPlaceholder() }
    }
    
    var isEditable: Bool {
        get { textView.isEditable }
        set { textView.isEditable = newValue }
    }
    
    // MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupBinding()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupBinding()
    }
    
    // MARK: - SETUP UI
    private func setupUI() {
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        addSubview(scrollView)
        scrollView.addSubview(textView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        
        // 1. Layout ScrollView full View cha
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor,constant: 3),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,constant: 15),
            placeholderLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
        ])
        
        // 2. Layout TextView full ScrollView (Content Layout Guide)
        // Quan trọng: Width của TextView phải bằng Width của ScrollView (Frame Layout Guide)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            
            textView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        // 3. Set constraint chiều cao cho chính View này (Wrapper)
        // Mặc định ban đầu là minHeight
        heightConstraint = self.heightAnchor.constraint(equalToConstant: minHeight)
        heightConstraint?.isActive = true
    }
    
    // MARK: - BINDING
    private func setupBinding() {
        // Typing logic (Giống hệt code cũ của cậu)
        let textChangeStream = NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: textView)
            .map { _ in true }
            .share()

        textChangeStream
            .sink { [weak self] isTyping in self?.isTypingPublisher.send(isTyping) }
            .store(in: &cancellables)

        textChangeStream
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main)
            .map { _ in false }
            .sink { [weak self] isTyping in self?.isTypingPublisher.send(isTyping) }
            .store(in: &cancellables)
    }
    
    // MARK: - LOGIC SCROLL & HEIGHT
    private func updateHeight() {
        // Tính chiều cao thực tế của TextView
        let size = textView.sizeThatFits(CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude))
        
        // Logic: Chiều cao của View = Min(Nội dung, MaxHeight)
        // Tức là: Nó sẽ lớn dần theo nội dung, nhưng không bao giờ vượt quá 100
        let targetHeight = min(max(size.height, minHeight), maxHeight)
        
        if heightConstraint?.constant != targetHeight {
            heightConstraint?.constant = targetHeight
            
            // Báo ra ngoài để StackView cha layout lại
            delegate?.chatInputViewDidContentSizeChange(self)
            
            // Layout ngay để animation mượt
            self.layoutIfNeeded()
        }
        
        // Scroll Logic: Nếu nội dung > chiều cao hiển thị -> Scroll xuống con trỏ
        scrollToCaret()
    }
    
    private func scrollToCaret() {
        // Lấy vị trí của con trỏ chuột (Caret)
        if let selectedRange = textView.selectedTextRange {
            var caretRect = textView.caretRect(for: selectedRange.start)
            
            // Cộng thêm chút padding để nhìn thoáng hơn
            caretRect.size.height += 10
            
            // Bảo ScrollView cuộn đến đúng chỗ đó
            scrollView.scrollRectToVisible(caretRect, animated: false)
        }
    }
    
    // MARK: - PLACEHOLDER LOGIC
    private func checkPlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - TEXTVIEW DELEGATE
extension ChatInputView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateHeight()
        checkPlaceholder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder && textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholder
            textView.textColor = .lightGray
        }
    }
}
