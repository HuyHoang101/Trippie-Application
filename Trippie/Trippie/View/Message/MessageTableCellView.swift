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
    private let dateLabel = UILabel.customLabel(text: "Mon, when 12:00", font: .systemFont(ofSize: 15), textColor: .secondaryLabel)
    private let dateStack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
    
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
        let spacer1 = UIView()
        let spacer2 = UIView()
        spacer1.translatesAutoresizingMaskIntoConstraints = false
        spacer2.translatesAutoresizingMaskIntoConstraints = false
        spacer1.backgroundColor = .secondaryLabel
        spacer2.backgroundColor = .secondaryLabel
        spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor).isActive = true
        spacer1.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        spacer2.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        contentView.addSubview(bubbleView)
        contentView.addSubview(dateStack)
        dateStack.addArrangedSubview(spacer1)
        dateStack.addArrangedSubview(dateLabel)
        dateLabel.addSubview(spacer2)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Neo bubbleView vào ContentView của Cell
            // Chừa padding trên dưới để các tin nhắn không dính sát nhau
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            dateStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dateStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 24)
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
        let isDate = comment.userId.isEmpty
        if isDate {
            bubbleView.isHidden = true
            dateStack.isHidden = false
            let date = comment.createdAt ?? Date()
            let calendar = Calendar.current
            let now = Date()
            let df = DateFormatter()

            // 1. Kiểm tra xem có cùng tuần không (cùng tuần của năm)
            if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                df.dateFormat = "EEE, HH:mm" // Ví dụ: Mon, 12:32
            }
            // 2. Kiểm tra xem có cùng năm không
            else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
                df.dateFormat = "MMM d, HH:mm" // Ví dụ: Oct 20, 12:32
            }
            // 3. Khác năm (năm trước, năm sau...)
            else {
                df.dateFormat = "MMM d yyyy, HH:mm" // Ví dụ: Oct 20 2023, 12:32
            }

            let dateStr = df.string(from: date)
            dateLabel.text = dateStr
        } else {
            dateStack.isHidden = true
            bubbleView.isHidden = false
        }
    }
    
    // Reset cell khi tái sử dụng để tránh lỗi hiển thị sai data cũ
    override func prepareForReuse() {
        super.prepareForReuse()
        onPlayVideoCallback = nil
        onPreviewImagesCallback = nil
    }
}
