//
//  StatusModalViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/24/26.
//

import UIKit

class StatusModalViewController: UIViewController {
    
    // Biến nhận dữ liệu truyền vào
    var participation: Participation!
    
    // UI Components
    private let dimmedView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    
    // Giữ mảng status để ánh xạ với tag của Button
    private let statuses = PersonalStatus.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // Tạo hiệu ứng mờ dần (Fade-in) khi show modal
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.2) {
            self.dimmedView.alpha = 1
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // 1. Setup Dimmed View (Màn đen mờ)
        dimmedView.backgroundColor = .black.withAlphaComponent(0.4)
        dimmedView.alpha = 0
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmedView)
        
        // 2. Setup Container View (Cửa sổ trắng)
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 10
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) // Chuẩn bị cho hiệu ứng pop-up
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // 3. Setup Title
        titleLabel.text = "Update Status"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 4. Setup StackView chứa các nút
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        // 5. Render danh sách Buttons
        for (index, status) in statuses.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(status.displayName, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            btn.layer.cornerRadius = 10
            btn.tag = index // Gắn tag để biết nút nào được bấm
            
            // LOGIC SOI TRẠNG THÁI HIỆN TẠI
            if status == participation.personalStatus {
                // Đang là status này -> Disable, đổi màu xám
                btn.backgroundColor = .systemGray5
                btn.setTitleColor(.systemGray, for: .normal)
                btn.isEnabled = false // Không cho bấm
            } else {
                // Status khác -> Hiện màu bình thường, cho phép bấm
                btn.backgroundColor = UIColor(named: "AuthBackground2")?.withAlphaComponent(0.1) ?? .systemBlue.withAlphaComponent(0.1)
                btn.setTitleColor(UIColor(named: "AuthBackground2") ?? .systemBlue, for: .normal)
                btn.isEnabled = true
                btn.addTarget(self, action: #selector(didTapStatusButton(_:)), for: .touchUpInside)
            }
            
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stackView.addArrangedSubview(btn)
        }
        
        // 6. Constraints
        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    // Chạm vùng đen mờ để tắt Modal
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissModal))
        dimmedView.addGestureRecognizer(tapGesture)
        dimmedView.isUserInteractionEnabled = true
    }
    
    @objc private func didTapStatusButton(_ sender: UIButton) {
        // 1. Lấy trạng thái mới dựa vào tag
        let selectedStatus = statuses[sender.tag]
        
        // 2. Cập nhật personalStatus trước khi gọi API
        var updatedParticipation = self.participation!
        updatedParticipation.personalStatus = selectedStatus
        
        // 3. Gọi viewModel cập nhật

        TripViewModel.shared.updatePersonalStatus(participation: updatedParticipation)
        
        // 4. Đóng modal
        dismissModal()
    }
    
    @objc private func dismissModal() {
        // Animation mờ dần rồi dismiss
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmedView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}
