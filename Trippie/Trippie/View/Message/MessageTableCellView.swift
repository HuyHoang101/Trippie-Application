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
    
    private var bubbleLeadingConstraint: NSLayoutConstraint!
    private var bubbleTrailingConstraint: NSLayoutConstraint!
    
    private var bubbleTopConstraint: NSLayoutConstraint!
    private var bubbleBottomConstraint: NSLayoutConstraint!
    private var dateTopConstraint: NSLayoutConstraint!
    private var dateBottomConstraint: NSLayoutConstraint!
    
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
        
        contentView.addSubview(bubbleView)
        contentView.addSubview(dateStack)
        dateStack.addArrangedSubview(spacer1)
        dateStack.addArrangedSubview(dateLabel)
        dateStack.addArrangedSubview(spacer2)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        bubbleTopConstraint = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor)
        bubbleBottomConstraint = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                
        dateTopConstraint = dateStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
        dateBottomConstraint = dateStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        NSLayoutConstraint.activate([
            
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            dateStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dateStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor),
            spacer1.heightAnchor.constraint(equalToConstant: 0.5),
            spacer2.heightAnchor.constraint(equalToConstant: 0.5),
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
        guard let id = AuthService.shared.currentUserId else {
            return
        }
        let isOwner = id == comment.userId
        let hideName = isOwner ? true : isHideName
        bubbleView.configure(comment: comment, isHideAvatar: isHideAvatar, isHideName: hideName)
        
        NSLayoutConstraint.deactivate([
            bubbleLeadingConstraint, bubbleTrailingConstraint,
            bubbleTopConstraint, bubbleBottomConstraint,
            dateTopConstraint, dateBottomConstraint
        ])
        
        if isOwner {
            bubbleLeadingConstraint.isActive = false
            bubbleTrailingConstraint.isActive = true
        } else {
            bubbleTrailingConstraint.isActive = false
            bubbleLeadingConstraint.isActive = true
        }
        let isDate = comment.userId.isEmpty
        if isDate {
            bubbleTopConstraint.isActive = false
            bubbleBottomConstraint.isActive = false
            dateTopConstraint.isActive = true
            dateBottomConstraint.isActive = true
            
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
            if comment.createdAt == nil {
                dateStack.layer.opacity = 0
            } else {
                dateStack.layer.opacity = 1
            }
        } else {
            dateTopConstraint.isActive = false
            dateBottomConstraint.isActive = false
            bubbleTopConstraint.isActive = true
            bubbleBottomConstraint.isActive = true

            dateStack.isHidden = true
            bubbleView.isHidden = false
        }
    }
    
    // Reset cell khi tái sử dụng để tránh lỗi hiển thị sai data cũ
    override func prepareForReuse() {
        super.prepareForReuse()
        onPlayVideoCallback = nil
        onPreviewImagesCallback = nil
        bubbleView.isHidden = false
        dateStack.isHidden = true
        
        bubbleView.resetState()
    }
}
