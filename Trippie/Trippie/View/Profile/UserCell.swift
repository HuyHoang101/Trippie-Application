//
//  UserCell.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit

class UserCell: UITableViewCell {
    
    static let identifier = "UserCell"
    
    var onTapAction: (() -> Void)?
    
    // 1. Action Button: Cần width cố định để animation đẹp
    private let actionButton: UIButton = {
        let btn = UIButton.customButton(image: UIImage(systemName: "person.fill.checkmark"), backgroundColor: .clear, tintColor: .systemRed)
        // Ẩn mặc định để tránh giật layout lúc đầu
        btn.isHidden = true
        return btn
    }()
    
    // Root Stack: Chứa MainView và ActionButton
    private let rootStackView = UIStackView.customStack(yPadding: 12, axis: .horizontal, alignment: .fill, distribution: .fill, stackSpacing: 8)
    
    private let mainView = UIView()
    
    private let avatarImageView = TrippieImageView(style: .circle, isShadow: false)
    
    private let nameLabel = UILabel.customLabel(
        text: "User Name",
        font: UIFont.systemFont(ofSize: 16, weight: .semibold),
        textColor: .label,
        textAligment: .left
    )
    
    private let emailLabel = UILabel.customLabel(
        text: "email@example.com",
        font: UIFont.systemFont(ofSize: 13, weight: .regular),
        textColor: .secondaryLabel,
        textAligment: .left
    )
    
    private lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        actionButton.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // THÊM VÀO ĐÂY: Reset closure khi tái sử dụng cell
    override func prepareForReuse() {
        super.prepareForReuse()
        self.onTapAction = nil
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        actionButton.isHidden = true
        
        // Setup MainView layout
        mainView.addSubview(avatarImageView)
        mainView.addSubview(infoStackView)
        
        // Setup Root layout
        rootStackView.addArrangedSubview(mainView)
        rootStackView.addArrangedSubview(actionButton)
        contentView.addSubview(rootStackView)
            
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 0.5
        avatarImageView.layer.borderColor = UIColor.authBackground2.withAlphaComponent(0.5).cgColor
        
        // Tắt translate để dùng AutoLayout
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false // Quan trọng
        
        NSLayoutConstraint.activate([
            // 1. Root Stack: Pin chặt vào contentView
            rootStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rootStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16), // Padding trái
            rootStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16), // Padding phải
            
            // 2. Avatar: Pin Top/Bottom vào mainView để xác định chiều cao cho mainView -> SỬA LỖI LAYOUT BỊ BAY
            avatarImageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Quan trọng: Neo Top/Bottom của Avatar vào MainView (có padding) để MainView có height thực tế
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: mainView.topAnchor),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: mainView.bottomAnchor),

            // 3. Info Stack
            infoStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            infoStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -4),
            infoStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            
            // 4. Action Button: Phải có Width cố định -> SỬA LỖI NÚT TRƯỢT NGANG
            actionButton.widthAnchor.constraint(equalToConstant: 44)
        ])
        
        // Constraint height priority để mainView ôm nội dung
        let heightConstraint = mainView.heightAnchor.constraint(greaterThanOrEqualToConstant: 75)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
    
    func updateMode(mode: ActionAceptPersonJoinTrip) {
        // Animation block giống hệt TaskCell
        UIView.animate(withDuration: 0.3) {
            switch mode {
            case .acept:
                self.actionButton.configuration?.image = UIImage(systemName: "person.fill.checkmark")
                self.actionButton.configuration?.baseForegroundColor = .systemGreen
                self.actionButton.isHidden = false
            case .deny:
                self.actionButton.configuration?.image = UIImage(systemName: "person.fill.xmark")
                self.actionButton.configuration?.baseForegroundColor = .systemRed
                self.actionButton.isHidden = false
            case .kick:
                self.actionButton.configuration?.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
                self.actionButton.configuration?.baseForegroundColor = .systemRed
                self.actionButton.isHidden = false
            case .normal:
                self.actionButton.isHidden = true
            }
            // QUAN TRỌNG: Ép layout chạy ngay lập tức để mượt
            self.contentView.layoutIfNeeded()
        }
    }
    
    func configure(user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        avatarImageView.setImage(url: user.avatarUrl, placeholderSystemName: "person.fill", pixel: 350)
        self.layoutIfNeeded()
    }
    
    @objc private func didTapActionBtn() {
        onTapAction?()
    }
}
