//
//  NotificationCell.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/23/26.
//

import UIKit

class NotificationCell: UITableViewCell {
    
    // UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .right
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal) // Giữ timeLabel không bị ép nhỏ
        return label
    }()
    
    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let topStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .top
        return stack
    }()

    // Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(mainStack)
        
        topStack.addArrangedSubview(titleLabel)
        topStack.addArrangedSubview(timeLabel)
        
        mainStack.addArrangedSubview(topStack)
        mainStack.addArrangedSubview(bodyLabel)
        
        // Padding cho cell
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // Truyền data vào Cell (Cậu nhớ sửa kiểu dữ liệu NotificationModel cho đúng với model của cậu nhé)
    func configure(with notif: NotificationItem) {
        titleLabel.text = notif.title
        bodyLabel.text = notif.body
        guard let date = notif.createdAt else { return }
        timeLabel.text = date.toNotificationFormat() // Dùng extension vừa tạo
        
        // Highlight thông báo chưa đọc
        contentView.backgroundColor = notif.isRead ? .clear : .background
    }
}
