//
//  TaskDetailModalViewController.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 8/2/26.
//

import UIKit
import Combine

class TaskDetailModalViewController: UIViewController {
    
    var task: TaskOfTrip?
    
    var viewModel: TaskViewModel!
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatar = TrippieImageView(style: .circle, isShadow: false)
    
    // Sử dụng TrippieImageView của bạn cho ảnh cover
    private let coverImageView = TrippieImageView(style: .rounded(radius: 4, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]), isShadow: false, borderColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.3))
    
    private let nameLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 16, weight: .bold), textColor: .label)
    private let timeInfoLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 13), textColor: .secondaryLabel)
    private let dateAndDayLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 14), textColor: .secondaryLabel)
    
    private let titleLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 20, weight: .bold), textColor: .label)
    private let descriptionLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 15), textColor: .label)
    private let editByLabel = UILabel.customLabel(text: "", font: .italicSystemFont(ofSize: 12), textColor: .secondaryLabel)
    
    private let statusBadge = TripStatusBadge() // Sử dụng badge loé sáng của bạn
    
    private let closeButton = UIButton.customButton(image: UIImage(systemName: "xmark.circle.fill"), backgroundColor: .clear, tintColor: .systemGray3)
    private let multipleChoiceBtn = DropdownButton()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderData()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(containerView)
        descriptionLabel.numberOfLines = 0
        multipleChoiceBtn.translatesAutoresizingMaskIntoConstraints = false
        multipleChoiceBtn.tintColor = .systemGray3
        multipleChoiceBtn.backgroundColor = .clear
        
        // Header Stack (Avatar + Name & Info)
        let nameAndInfoStack = UIStackView.customStack(axis: .vertical, alignment: .leading, distribution: .fill, stackSpacing: 2)
        nameAndInfoStack.addArrangedSubview(nameLabel)
        nameAndInfoStack.addArrangedSubview(timeInfoLabel)
        
        let headerStack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
        headerStack.addArrangedSubview(avatar)
        headerStack.addArrangedSubview(nameAndInfoStack)
        
        
        // Main Content Stack
        let contentStack = UIStackView.customStack(xPadding: 20, yPadding: 20, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 15)
        
        // Top Section
        let topSectionStack = UIStackView.customStack(axis: .horizontal, alignment: .top, distribution: .equalCentering)
        let space = UIView()
        space.translatesAutoresizingMaskIntoConstraints = false
        topSectionStack.addArrangedSubview(headerStack)
        topSectionStack.addArrangedSubview(space)
        
        let titleStatusStack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
        let spacer = UIView()
        titleStatusStack.addArrangedSubview(titleLabel)
        titleStatusStack.addArrangedSubview(spacer)
        titleStatusStack.addArrangedSubview(statusBadge)
        
        contentStack.addArrangedSubview(topSectionStack)
        contentStack.addArrangedSubview(titleStatusStack)
        contentStack.addArrangedSubview(dateAndDayLabel)
        contentStack.addArrangedSubview(descriptionLabel)
        contentStack.addArrangedSubview(editByLabel)
        contentStack.addArrangedSubview(coverImageView)
        
        containerView.addSubview(contentStack)
        containerView.addSubview(closeButton)
        containerView.addSubview(multipleChoiceBtn)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            multipleChoiceBtn.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            multipleChoiceBtn.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -5),
            multipleChoiceBtn.widthAnchor.constraint(equalToConstant: 22),
            multipleChoiceBtn.heightAnchor.constraint(equalToConstant: 22),
            
            avatar.widthAnchor.constraint(equalToConstant: 45),
            avatar.heightAnchor.constraint(equalToConstant: 45),
            
            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            space.widthAnchor.constraint(equalToConstant: 80),
            
            coverImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func renderData() {
        guard let task = task else { return }
        let role = task.userRole == .owner
        avatar.setImage(url: task.userAvatar)
        nameLabel.text = "\(task.userName) \(role ? "- Admin" : "")"
        dateAndDayLabel.text = "Day \(task.dayIndex) • \(task.time)"
        titleLabel.text = task.title
        descriptionLabel.text = task.description
        
        if role {
            multipleChoiceBtn.enableSelectionMode = true
            let status = task.status
            let index = status == .upcoming ? 0 : status == .onGoing ? 1 : status == .completed ? 2 : 3
            multipleChoiceBtn.selectedIndex = index
            
            multipleChoiceBtn.items = [
                DropdownItem(title: "Upcoming", icon: "clock", type: .normal) {
                    self.didTapUpcoming()
                },
                DropdownItem(title: "On going", icon: "figure.walk", type: .normal) {
                    self.didTapOngoing()
                },
                DropdownItem(title: "Completed", icon: "checkmark.seal.fill", type: .normal) {
                    self.didTapCompleted()
                },
                DropdownItem(title: "Cancel", icon: "xmark.circle.fill", type: .destructive) {
                    self.didTapCancel()
                },
            ]
        }
        // Set Status Badge
        let status = PersonalStatus(rawValue: task.status.rawValue) ?? .upcoming
        statusBadge.configure(status: status) // Giả định TripStatusBadge có hàm setStatus
        
        // Logic hiển thị Edit By / Created At
        if let editor = task.editBy, !editor.isEmpty {
            let df = DateFormatter()
            df.dateFormat = "MMM d, HH:mm"
            let dateStr = df.string(from: task.updatedAt ?? Date())
            editByLabel.text = "Edited by \(editor) at \(dateStr)"
            editByLabel.isHidden = false
            
            // Nếu có editBy, dòng thời gian dưới tên sẽ hiện ngày tạo ban đầu
            timeInfoLabel.text = "Posted on \(formatDate(task.createdAt))"
        } else {
            editByLabel.isHidden = true
            timeInfoLabel.text = "Posted on \(formatDate(task.createdAt))"
        }
        
        // Xử lý ảnh Cover
        if task.coverImage.isEmpty {
            coverImageView.isHidden = true
        } else {
            coverImageView.isHidden = false
            coverImageView.setImage(url: task.coverImage)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Just now" }
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
    }
    
    @objc private func dismissModal() {
        self.dismiss(animated: true)
    }
    
    @objc private func didTapUpcoming() {
        var task = self.task
        task?.status = .upcoming
        self.viewModel.editingTask.send(task)
        self.viewModel.handSaveTask(task: task!, name: AuthService.shared.currentUserName ?? "Unknown User", isEdit: false)
        self.task = task
        self.renderData()
    }
    
    @objc private func didTapOngoing() {
        var task = self.task
        task?.status = .onGoing
        self.viewModel.editingTask.send(task)
        self.viewModel.handSaveTask(task: task!, name: AuthService.shared.currentUserName ?? "Unknown User", isEdit: false)
        self.task = task
        self.renderData()
    }
    
    @objc private func didTapCompleted() {
        var task = self.task
        task?.status = .completed
        self.viewModel.editingTask.send(task)
        self.viewModel.handSaveTask(task: task!, name: AuthService.shared.currentUserName ?? "Unknown User", isEdit: false)
        self.task = task
        self.renderData()
    }
    
    @objc private func didTapCancel() {
        var task = self.task
        task?.status = .cancel
        self.viewModel.editingTask.send(task)
        self.viewModel.handSaveTask(task: task!, name: AuthService.shared.currentUserName ?? "Unknown User", isEdit: false)
        self.task = task
        self.renderData()
    }
}

