//
//  MessageBubbleView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//

import UIKit
import SDWebImage

class MessageBubbleView: UIView {
    
    var onVideoTapped: (() -> Void)?
    var onImageTapped: (() -> Void)?
    
    private let chatLabel = UILabel()
    private let bubbleWrapper = UIView()
    
    private let nameLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 11), textColor: .secondaryLabel)
    private let avatar = TrippieImageView(style: .circle, isShadow: false, borderColor: .authBackground2.withAlphaComponent(0.4))
    
    // Stack này bây giờ CHỈ dùng để chứa Tên, Hình và Video
    private let mainStack = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 4)
    
    private let images = ImageAttachmentView()
    private let video = VideoAttachmentView()
    
    // Các dây kéo Trái/Phải cho cụm Hình + Tên
    private var mainStackLeading: NSLayoutConstraint!
    private var mainStackTrailing: NSLayoutConstraint!
    
    // Các dây kéo Trái/Phải độc lập cho Bong Bóng
    private var bubbleLeading: NSLayoutConstraint!
    private var bubbleTrailing: NSLayoutConstraint!
    
    // Dây ép chiều cao bong bóng về 0 khi gửi ảnh/video
    private var bubbleHeightZero: NSLayoutConstraint!
    
    // Padding cho chữ
    private var bubbleTopConstraint: NSLayoutConstraint!
    private var bubbleBottomConstraint: NSLayoutConstraint!
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBubble()
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    //MARK: - SETUP BUBBLE
    private func setupBubble() {
        chatLabel.font = .systemFont(ofSize: 15)
        chatLabel.numberOfLines = 0
        chatLabel.lineBreakMode = .byWordWrapping
        chatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleWrapper.layer.cornerRadius = 16
        bubbleWrapper.clipsToBounds = true
        bubbleWrapper.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleWrapper.addSubview(chatLabel)
        
        bubbleTopConstraint = chatLabel.topAnchor.constraint(equalTo: bubbleWrapper.topAnchor, constant: 8)
        bubbleLeadingConstraint = chatLabel.leadingAnchor.constraint(equalTo: bubbleWrapper.leadingAnchor, constant: 12)
        
        bubbleBottomConstraint = chatLabel.bottomAnchor.constraint(equalTo: bubbleWrapper.bottomAnchor, constant: -8)
        bubbleBottomConstraint.priority = .init(999)
        
        bubbleTrailingConstraint = chatLabel.trailingAnchor.constraint(equalTo: bubbleWrapper.trailingAnchor, constant: -12)
        bubbleTrailingConstraint.priority = .init(999)
        
        NSLayoutConstraint.activate([
            bubbleTopConstraint,
            bubbleLeadingConstraint,
            bubbleBottomConstraint,
            bubbleTrailingConstraint
        ])
        
        // Chuẩn bị dây thòng lọng ép chiều cao về 0 (Mặc định tắt)
        bubbleHeightZero = bubbleWrapper.heightAnchor.constraint(equalToConstant: 0)
    }
    
    private func setupUI() {
        addSubview(avatar)
        addSubview(mainStack)
        addSubview(bubbleWrapper) // ✅ Lôi bong bóng ra, nằm độc lập ngang hàng với Stack
        
        mainStack.addArrangedSubview(nameLabel)
        mainStack.addArrangedSubview(images)
        mainStack.addArrangedSubview(video)
        
        avatar.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // --- 1. GẮN CỐ ĐỊNH TRỤC DỌC ---
        NSLayoutConstraint.activate([
            avatar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            avatar.widthAnchor.constraint(equalToConstant: 40),
            avatar.heightAnchor.constraint(equalToConstant: 40),
            
            // Stack nằm trên
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            
            // Bong bóng nằm dưới Stack, đẩy xuống đáy Cell
            bubbleWrapper.topAnchor.constraint(equalTo: mainStack.bottomAnchor, constant: 2),
            bubbleWrapper.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1)
        ])
        
        // --- 2. CHUẨN BỊ DÂY KÉO TRỤC NGANG ĐỘC LẬP ---
        mainStackLeading = mainStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 6)
        mainStackTrailing = mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        
        bubbleLeading = bubbleWrapper.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 6)
        bubbleTrailing = bubbleWrapper.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        
        // Giới hạn an toàn chống tràn viền (Cái này tự động khoá bong bóng không cho dãn qua màn hình)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            
            bubbleWrapper.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
            bubbleWrapper.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12)
        ])
    }
    
    func configure(comment: Comment, isHideAvatar: Bool, isHideName: Bool) {
        guard let id = AuthService.shared.currentUserId else { return }
        
        let isOwner = id == comment.userId
        let cleanText = comment.message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isOwner {
            bubbleWrapper.backgroundColor = .authBackground2
            chatLabel.textColor = .white
            avatar.isHidden = true
            nameLabel.textAlignment = .right
            
            // Cả Stack và Bong Bóng đều dính sát lề PHẢI
            mainStackLeading.isActive = false
            mainStackTrailing.isActive = true
            
            bubbleLeading.isActive = false
            bubbleTrailing.isActive = true
        } else {
            bubbleWrapper.backgroundColor = .systemGray6
            chatLabel.textColor = .label
            avatar.isHidden = false
            nameLabel.textAlignment = .left
            
            // Cả Stack và Bong Bóng đều dính sát lề TRÁI (sau avatar)
            mainStackTrailing.isActive = false
            mainStackLeading.isActive = true
            
            bubbleTrailing.isActive = false
            bubbleLeading.isActive = true
        }
        
        nameLabel.text = comment.userName
        chatLabel.text = cleanText
        avatar.setImage(url: comment.userAvatar, placeholderSystemName: "person.fill", pixel: 350)
        
        let isVideo = !comment.videoUrl.isEmpty
        let hasNoText = cleanText.isEmpty
        
        if isVideo {
            images.isHidden = true
            video.isHidden = false
            video.configure(videoThumbnail: comment.videoThumbnail)
            
            // Ẩn bong bóng và bóp chết chiều cao của nó
            bubbleWrapper.isHidden = true
            bubbleHeightZero.isActive = true
        } else {
            images.isHidden = false
            video.isHidden = true
            images.configure(urls: comment.imageUrls)
            
            if hasNoText {
                // Nếu gửi ảnh không kèm chữ -> Ẩn bong bóng và bóp chiều cao
                bubbleWrapper.isHidden = true
                bubbleHeightZero.isActive = true
            } else {
                // Có chữ -> Hiện bong bóng, nhả dây ép chiều cao ra
                bubbleWrapper.isHidden = false
                bubbleHeightZero.isActive = false
            }
        }
        
        avatar.layer.opacity = isHideAvatar ? 0 : 1
        nameLabel.isHidden = isHideName
        
        setupEmoji(comment.message.isPureEmoji, isOwner: isOwner)
    }
    
    private func setupEmoji(_ isemo: Bool, isOwner: Bool) {
        if isemo {
            chatLabel.font = .systemFont(ofSize: 40)
            bubbleWrapper.backgroundColor = .clear
            
            bubbleTopConstraint.constant = -5.2
            bubbleBottomConstraint.constant = 5.2
            bubbleLeadingConstraint.constant = 0
            bubbleTrailingConstraint.constant = 0
        } else {
            chatLabel.font = .systemFont(ofSize: 15)
            bubbleWrapper.backgroundColor = isOwner ? .authBackground2 : .systemGray6
            
            bubbleTopConstraint.constant = 8
            bubbleBottomConstraint.constant = -8
            bubbleLeadingConstraint.constant = 12
            bubbleTrailingConstraint.constant = -12
        }
    }
    
    private func setupActions() {
        video.onTap = { [weak self] in self?.onVideoTapped?() }
        images.onTapImage = { [weak self] in self?.onImageTapped?() }
    }
    
    func resetState() {
        chatLabel.text = nil
        nameLabel.text = nil
        images.isHidden = true
        video.isHidden = true
        bubbleWrapper.isHidden = false
        bubbleHeightZero.isActive = false // Phải reset luôn cái dây ép chiều cao
    }
}

// MARK: - COMPONENT IMAGE VIEW
class ImageAttachmentView: UIView {
    var onTapImage: (() -> Void)?
    private let stackView = UIStackView.customStack(axis: .horizontal, alignment: .bottom, distribution: .fill, stackSpacing: 2)
    private let img1 = TrippieImageView(style: .rounded(radius: 0, corners: nil), isShadow: false)
    private let img2 = TrippieImageView(style: .rounded(radius: 0, corners: nil), isShadow: false)
    private let countLabel = UILabel.boxStyle(text: "+0", font: .systemFont(ofSize: 14), background: .black.withAlphaComponent(0.15), textColor: .white)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
        
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        addSubview(stackView)
        countLabel.layer.borderColor = UIColor.clear.cgColor
        stackView.addArrangedSubview(img1)
        stackView.addArrangedSubview(img2)
        stackView.addArrangedSubview(countLabel)
        let spacer = UIView()
        stackView.addArrangedSubview(spacer)
        
        img1.translatesAutoresizingMaskIntoConstraints = false
        img2.translatesAutoresizingMaskIntoConstraints = false
        
        // ✅ FIX: Hạ Priority của toàn bộ Constraint kích thước cứng xuống 999
        let bottom = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottom.priority = .init(999)
        let trailing = stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        trailing.priority = .init(999)
        
        let w1 = img1.widthAnchor.constraint(equalToConstant: 70)
        w1.priority = .init(999)
        let h1 = img1.heightAnchor.constraint(equalToConstant: 70)
        h1.priority = .init(999)
        
        let w2 = img2.widthAnchor.constraint(equalToConstant: 70)
        w2.priority = .init(999)
        let h2 = img2.heightAnchor.constraint(equalToConstant: 70)
        h2.priority = .init(999)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottom, trailing,
            w1, h1, w2, h2
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func didTapView() { onTapImage?() }
    
    func configure(urls: [String]) {
        // ... (Giữ nguyên logic cũ của cậu ở đây)
        let count = urls.count
        self.isHidden = false
        img1.isHidden = true
        img2.isHidden = true
        countLabel.isHidden = true
        
        switch count {
        case 0: self.isHidden = true
        case 1:
            img1.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
        case 2:
            img1.isHidden = false
            img2.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
            img2.setImage(url: urls[1], pixel: 300)
        default:
            img1.isHidden = false
            img2.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
            img2.setImage(url: urls[1], pixel: 300)
            countLabel.isHidden = false
            countLabel.text = "+\(count - 2) "
        }
    }
}

// MARK: - CUSTOM VIEW: VIDEO BUBBLE
class VideoAttachmentView: UIView {
    var onTap: (() -> Void)?
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .black
        iv.clipsToBounds = true
        return iv
    }()
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()
    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        iv.tintColor = .white.withAlphaComponent(0.9)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(playIcon)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            playIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 50),
            playIcon.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    func configure(videoThumbnail: String) {
        thumbnailImageView.backgroundColor = .black
        
        guard let url = URL(string: videoThumbnail) else {
            thumbnailImageView.image = nil
            return
        }
        
        thumbnailImageView.sd_setImage(with: url, placeholderImage: nil)
    }
    
    @objc private func didTap() {
        onTap?()
    }
}
