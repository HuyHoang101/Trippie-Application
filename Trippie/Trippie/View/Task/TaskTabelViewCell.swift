//
//  TaskTabelViewCell.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    static let identifier = "TaskTableViewCell"

    // Callback khi bấm vào nút Edit/Delete
    var onTapAction: (() -> Void)?
    
    private let actionButton = UIButton.customButton(image: UIImage(systemName: "trash"), backgroundColor: .clear, tintColor: .systemRed)
    
    private let rootStackView = UIStackView.customStack(axis: .horizontal, alignment: .fill, distribution: .fill, stackSpacing: 0)
    
    // --- UI Components ---
    
    // Dòng 1: Avatar + Name (Left) | Day - Time (Right)
    private let avatarImageView = TrippieImageView(style: .circle, isShadow: false, borderColor: .systemGray6)
    
    private let nameLabel = UILabel.customLabel(text: "Unknown User", font: .systemFont(ofSize: 13, weight: .regular), textColor: .label)
    
    private let dayTimeLabel = UILabel.customLabel(text: "Day 1 • 7:00", font: .systemFont(ofSize: 13, weight: .regular), textColor: .secondaryLabel, textAligment: .right)
    
    // Dòng 2: Title (Left) | Status (Right)
    private let titleLabel = UILabel.customLabel(text: "Task title", font: .systemFont(ofSize: 16, weight: .semibold), textColor: .label)
    
    
    private let statusBadge = TripStatusBadge()
    
    // Dòng 3: Edit By (Right only)
    private let editByLabel: UILabel = UILabel.customLabel(text: "Edited by Unknown", font: .systemFont(ofSize: 12), textColor: .label, textAligment: .right)

    
    private let userStack = UIStackView()
    private let topRowStack = UIStackView()
    private let middleRowStack = UIStackView()
    private let mainStack = UIStackView()
    private let mainContainer = UIView()
    
    // --- Init ---
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        actionButton.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // --- Layout ---
    private func setupLayout() {
        // 1. Tạo StackView cho Dòng 1 (Top)
        // Group Avatar + Name lại với nhau trước
        userStack.addArrangedSubview(avatarImageView)
        userStack.addArrangedSubview(nameLabel)
        userStack.axis = .horizontal
        userStack.spacing = 8
        userStack.alignment = .center
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Ràng buộc kích thước Avatar
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        topRowStack.addArrangedSubview(userStack)
        topRowStack.addArrangedSubview(dayTimeLabel)
        topRowStack.axis = .horizontal
        topRowStack.distribution = .equalSpacing // Đẩy 2 thằng ra 2 đầu
        
        // 2. Tạo StackView cho Dòng 2 (Middle)
        let spacer = UIView()
        middleRowStack.addArrangedSubview(titleLabel)
        middleRowStack.addArrangedSubview(spacer)
        middleRowStack.addArrangedSubview(statusBadge)
        middleRowStack.axis = .horizontal
        middleRowStack.spacing = 8
        middleRowStack.alignment = .top // Căn lề trên để title dài không làm lệch badge
        // Đặt độ ưu tiên nén (Hugging Priority) để Title được giãn, Badge giữ nguyên size
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)
        
        // 3. Dòng 3 là editByLabel đứng một mình
        
        // 4. Gom tất cả vào 1 StackView dọc chính (Main Container)
        mainStack.addArrangedSubview(topRowStack)
        mainStack.addArrangedSubview(middleRowStack)
        mainStack.addArrangedSubview(editByLabel)
        mainStack.axis = .vertical
        mainStack.spacing = 8 // Khoảng cách giữa các dòng
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        mainContainer.backgroundColor = .systemBackground
        mainContainer.layer.cornerRadius = 12
        
        // Cấu hình đổ bóng (Shadow)
        mainContainer.layer.shadowColor = UIColor.authBackground2.cgColor
        mainContainer.layer.shadowOpacity = 0.2
        mainContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        mainContainer.layer.shadowRadius = 3

        mainContainer.layer.masksToBounds = false
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(rootStackView)
        
        actionButton.isHidden = true
        rootStackView.addArrangedSubview(mainContainer)
        rootStackView.addArrangedSubview(actionButton)
        
        mainContainer.addSubview(mainStack)
        
        // 5. Constraint cho Main Stack (Padding)
        NSLayoutConstraint.activate([
            rootStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rootStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rootStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rootStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            mainStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -12),
            
            actionButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // Hàm cập nhật giao diện dựa theo Mode
    func updateMode(mode: ListTaskMode) {
        UIView.animate(withDuration: 0.3) {
            switch mode {
            case .normal:
                self.actionButton.isHidden = true
                
            case .edit:
                self.actionButton.isHidden = false
                self.actionButton.configuration?.image = UIImage(systemName: "pencil.line")
                self.actionButton.configuration?.baseBackgroundColor = .clear
                self.actionButton.configuration?.baseForegroundColor = .authBackground2
                
            case .delete:
                self.actionButton.isHidden = false
                self.actionButton.configuration?.image = UIImage(systemName: "trash.fill")
                self.actionButton.configuration?.baseBackgroundColor = .clear
                self.actionButton.configuration?.baseForegroundColor = .systemRed
            }
            
            // Ép layout cập nhật ngay lập tức để thấy hiệu ứng trượt
            self.contentView.layoutIfNeeded()
        }
    }
    
    
    
    // --- Configuration (Hàm đổ dữ liệu) ---
    func configure(with task: TaskOfTrip, id: String) {
        // Dòng 1
        if task.userRole == .owner {
            nameLabel.text = "\(task.userName) - Admin"
        } else {
            nameLabel.text = task.userName
        }
        
        dayTimeLabel.text = "Day \(task.dayIndex) • \(task.time)"
        
        // Load Avatar (Dùng Kingfisher hoặc SDWebImage hoặc hàm load ảnh cậu có)
        // Ví dụ: imageView.sd_setImage(with: URL(string: task.userAvatar))
        avatarImageView.setImage(url: task.userAvatar, placeholderSystemName: "person.fill")
        
        // Dòng 2
        titleLabel.text = task.title
        statusBadge.configure(status: PersonalStatus(rawValue: task.status.rawValue)!)
        
        // Dòng 3 (Logic ẩn hiện)
        if let editor = task.editBy, !editor.isEmpty {
            editByLabel.text = "Edited by \(editor)"
            editByLabel.isHidden = false
        } else {
            editByLabel.text = nil
            editByLabel.isHidden = true
        }
        
        if id == task.creatorId {
            mainContainer.backgroundColor = .background.withAlphaComponent(0.5)
        } else {
            mainContainer.backgroundColor = .systemBackground
        }
    }
    
    // Action
    @objc private func didTapActionBtn() {
        onTapAction?()
    }
}
