//
//  MessageTableCellView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//


import UIKit

class MessageTableViewCell: UITableViewCell {
    
    static let identifier = "MessageTableViewCell"
    
    // MARK: - 1. CALLBACKS (Truyền từ Cell ra ViewController)
    var onPlayVideoCallback: (() -> Void)?
    var onPreviewImagesCallback: (() -> Void)?
    
    // MARK: - UI COMPONENTS
    // Nhúng cái View custom của cậu vào đây
    private let bubbleView = MessageBubbleView()
    
    // MARK: - INIT
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - SETUP
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none // Chat không nên có màu xám khi click
        
        contentView.addSubview(bubbleView)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Neo bubbleView vào ContentView của Cell
            // Chừa padding trên dưới để các tin nhắn không dính sát nhau
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
        
        // MARK: - 2. ACTION BINDING (Quan trọng nhất)
        // Hứng sự kiện từ BubbleView -> Bắn ra ngoài Cell
        
        bubbleView.onVideoTapped = { [weak self] in
            self?.onPlayVideoCallback?()
        }
        
        bubbleView.onImageTapped = { [weak self] in
            self?.onPreviewImagesCallback?()
        }
    }
    
    // MARK: - CONFIGURE
    func configure(comment: Comment, isHideAvatar: Bool, isHideName: Bool) {
        bubbleView.configure(comment: comment, isHideAvatar: isHideAvatar, isHideName: isHideName)
        guard let id = AuthService.shared.currentUserId else {
            return
        }
        let isOwner = id == comment.userId
        if isOwner {
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        } else {
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        }
    }
    
    // Reset cell khi tái sử dụng để tránh lỗi hiển thị sai data cũ
    override func prepareForReuse() {
        super.prepareForReuse()
        onPlayVideoCallback = nil
        onPreviewImagesCallback = nil
    }
}
