//
//  UserCell.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit

class UserCell: UITableViewCell {
    
    // Identifier để register
    static let identifier = "UserCell"
    
    // MARK: - UI Components
    // 1. Dùng TrippieImageView có sẵn của cậu
    private let avatarImageView = TrippieImageView(style: .circle, isShadow: false)
    
    // 2. Name Label (Đậm hơn chút cho nổi bật)
    private let nameLabel = UILabel.customLabel(
        text: "User Name",
        font: UIFont.systemFont(ofSize: 16, weight: .semibold),
        textColor: .label,
        textAligment: .left
    )
    
    // 3. Email Label (Nhạt hơn, nhỏ hơn)
    private let emailLabel = UILabel.customLabel(
        text: "email@example.com",
        font: UIFont.systemFont(ofSize: 13, weight: .regular),
        textColor: .secondaryLabel,
        textAligment: .left
    )
    
    // 4. VStack (UIStackView) để gom Name và Email
    private lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        stack.axis = .vertical
        stack.spacing = 4 // Khoảng cách giữa tên và email
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none // Tắt hiệu ứng xám khi click (tuỳ chọn)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(infoStackView)
            
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 0.5
        avatarImageView.layer.borderColor = UIColor.authBackground2.withAlphaComponent(0.5).cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Avatar: Nằm bên trái, giữa chiều dọc, size 50x50
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),

            // StackView: Nằm bên phải Avatar, cách 12pt
            infoStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
        
    }
    
    // MARK: - Data Binding
    func configure(user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        avatarImageView.setImage(url: user.avatarUrl, placeholderSystemName: "person.fill")
    }
}
