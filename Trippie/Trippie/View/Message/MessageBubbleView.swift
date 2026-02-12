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
    
    
    private let chatBubble = PaddingLabel()
    private let nameLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 10), textColor: .secondaryLabel)
    private let avatar = TrippieImageView(style: .circle, isShadow: false, borderColor: .authBackground2.withAlphaComponent(0.4))
    private let mainStack = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 4)
    
    private let images = ImageAttachmentView()
    private let video = VideoAttachmentView()
    
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBubble()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    //MARK: - SETUP BUBBLE
    private func setupBubble() {
        chatBubble.topInset = 10
        chatBubble.bottomInset = 10
        chatBubble.leftInset = 10
        chatBubble.rightInset = 10
        chatBubble.isCircle = false
        chatBubble.font = .systemFont(ofSize: 13)
        chatBubble.translatesAutoresizingMaskIntoConstraints = false
        chatBubble.clipsToBounds = true
        chatBubble.numberOfLines = 0
    }
    
    private func setupUI() {
        addSubview(mainStack)
        addSubview(avatar)
        
        mainStack.addArrangedSubview(nameLabel)
        mainStack.addArrangedSubview(images)
        mainStack.addArrangedSubview(video)
        mainStack.addArrangedSubview(chatBubble)
        
        avatar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            avatar.widthAnchor.constraint(equalToConstant: 46),
            avatar.heightAnchor.constraint(equalToConstant: 46),
            
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 12),
        ])
        if let container = self.superview {
            mainStack.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.75).isActive = true
        }
    }
    
    func configure(comment: Comment, isHideAvatar: Bool, isHideName: Bool) {
        guard let id = AuthService.shared.currentUserId else {
            return
        }
        
        let isOwner = id == comment.userId
        if isOwner {
            chatBubble.backgroundColor = .authBackground2
            chatBubble.textColor = .white
            avatar.isHidden = true
            nameLabel.textAlignment = .right
        } else {
            chatBubble.backgroundColor = .systemGray6
            chatBubble.textColor = .label
            avatar.isHidden = false
            nameLabel.textAlignment = .left
        }
        nameLabel.text = comment.userName
        chatBubble.textAlignment = .justified
        chatBubble.text = comment.message
        avatar.setImage(url: comment.userAvatar, placeholderSystemName: "person.fill", pixel: 350)
        
        let isVideo = !comment.videoUrl.isEmpty
        if isVideo {
            chatBubble.isHidden = true
            images.isHidden = true
            video.isHidden = false
            video.configure(videoThumbnail: comment.videoThumbnail)
        } else {
            chatBubble.isHidden = false
            images.isHidden = false
            video.isHidden = true
            images.configure(urls: comment.imageUrls)
        }
        
        if isHideAvatar {
            avatar.layer.opacity = 0
        } else {
            avatar.layer.opacity = 1
        }
        
        if isHideName {
            nameLabel.isHidden = true
        } else {
            nameLabel.isHidden = false
        }
    }
    
    private func setupActions() {
        // 1. Nối dây từ Video View -> Callback của Bubble
        video.onTap = { [weak self] in
            guard let self = self else { return }
            // Kiểm tra xem có link video không rồi bắn ra ngoài
            self.onVideoTapped?()
        }
        
        // 2. Nối dây từ Image View -> Callback của Bubble
        images.onTapImage = { [weak self] in
            guard let self = self else { return }
            // Bắn danh sách ảnh và vị trí ảnh được chọn ra ngoài
            self.onImageTapped?()
        }
    }
}


// MARK: - COMPONENT IMAGE VIEW
class ImageAttachmentView: UIView {
    
    var onTapImage: (() -> Void)?
    
    private let stackView = UIStackView.customStack(axis: .horizontal, alignment: .bottom, distribution: .fill, stackSpacing: 2)
        
    private let img1 = TrippieImageView(style: .rounded(radius: 0, corners: nil), isShadow: false)
    private let img2 = TrippieImageView(style: .rounded(radius: 0, corners: nil), isShadow: false)
        
    private let countLabel = UILabel.boxStyle(text: "+0", font: .systemFont(ofSize: 20), background: .black.withAlphaComponent(0.4), textColor: .white)
    
    override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(img1)
        stackView.addArrangedSubview(img2)
        stackView.addArrangedSubview(countLabel)
        let spacer = UIView()
        stackView.addArrangedSubview(spacer)
        
        img1.translatesAutoresizingMaskIntoConstraints = false
        img2.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            img1.widthAnchor.constraint(equalToConstant: 70),
            img1.heightAnchor.constraint(equalToConstant: 70),
            img2.widthAnchor.constraint(equalToConstant: 70),
            img2.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func didTapView() {
        onTapImage?()
    }
    
    func configure(urls: [String]) {
        let count = urls.count
        // Reset trạng thái
        self.isHidden = false
        img1.isHidden = true
        img2.isHidden = true
        countLabel.isHidden = true
        
        // Cập nhật Constraint đễ giữ UI đẹp (Optional: cậu có thể dùng width constant)
        
        switch count {
        case 0:
            self.isHidden = true
            
        case 1:
            img1.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
            
        case 2:
            img1.isHidden = false
            img2.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
            img2.setImage(url: urls[1], pixel: 300)
            
        default: // > 2 ảnh
            img1.isHidden = false
            img2.isHidden = false
            img1.setImage(url: urls[0], pixel: 300)
            img2.setImage(url: urls[1], pixel: 300)
            
            countLabel.isHidden = false
            countLabel.text = "  +\(count - 2)"
        }
    }
}


// MARK: - 2. CUSTOM VIEW: VIDEO BUBBLE (Hiển thị Play Button)
class VideoAttachmentView: UIView {
    
    var onTap: (() -> Void)?
    
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .black // Nền đen trong lúc chờ load ảnh
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
        iv.tintColor = .white
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
        guard let url = URL(string: videoThumbnail) else {
            thumbnailImageView.image = nil
            return
        }
        // Dùng thư viện SDWebImage của cậu để load và cache ảnh
        thumbnailImageView.sd_setImage(with: url, placeholderImage: nil)
    }
    
    @objc private func didTap() {
        onTap?()
    }
}
