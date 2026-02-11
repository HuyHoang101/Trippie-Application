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
    
    //Callback action
    var onTapAction: (() -> Void)?
    
    private let actionButton = UIButton.customButton(image: UIImage(systemName: "checkmark.circle.fill"), backgroundColor: .clear, tintColor: .systemRed)
    
    private let rootStackView = UIStackView.customStack(yPadding: 12, axis: .horizontal, alignment: .fill, distribution: .fill, stackSpacing: 0)
    
    private let mainView = UIView()
    
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
        actionButton.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none // Tắt hiệu ứng xám khi click (tuỳ chọn)
        
        mainView.addSubview(avatarImageView)
        mainView.addSubview(infoStackView)
        rootStackView.addArrangedSubview(mainView)
        rootStackView.addArrangedSubview(actionButton)
        contentView.addSubview(rootStackView)
            
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 0.5
        avatarImageView.layer.borderColor = UIColor.authBackground2.withAlphaComponent(0.5).cgColor
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Avatar: Nằm bên trái, giữa chiều dọc, size 50x50
            avatarImageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),

            // StackView: Nằm bên phải Avatar, cách 12pt
            infoStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            infoStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -16),
            infoStackView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            
            rootStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rootStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
        ])
        
    }
    
    func updateMode(mode: ActionAceptPersonJoinTrip) {
        UIView.animate(withDuration: 0.3) {
            switch mode {
            case .acept:
                self.actionButton.isHidden = false
                self.actionButton.configuration?.image = UIImage(systemName: "person.fill.checkmark")
                self.actionButton.configuration?.baseBackgroundColor = .clear
                self.actionButton.configuration?.baseForegroundColor = .systemGreen
            case .deny:
                self.actionButton.isHidden = false
                self.actionButton.configuration?.image = UIImage(systemName: "person.fill.xmark")
                self.actionButton.configuration?.baseBackgroundColor = .clear
                self.actionButton.configuration?.baseForegroundColor = .systemRed
            case .kick:
                self.actionButton.isHidden = false
                self.actionButton.configuration?.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
                self.actionButton.configuration?.baseBackgroundColor = .clear
                self.actionButton.configuration?.baseForegroundColor = .systemRed
            case .normal:
                self.actionButton.isHidden = true
            }
        }
    }
    
    // MARK: - Data Binding
    func configure(user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        avatarImageView.setImage(url: user.avatarUrl, placeholderSystemName: "person.fill", pixel: 350)
    }
    
    @objc private func didTapActionBtn() {
        onTapAction?()
    }
}
