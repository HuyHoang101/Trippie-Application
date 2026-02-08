//
//  RatingModalViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit
import Combine

class RatingModalViewController: UIViewController {

    // MARK: - Data
    var otherUserId: String?
    private let viewModel = UserViewModel.shared
    private var cancellable = Set<AnyCancellable>()
    private var currentRating: Int = 0 {
        didSet { updateStarUI() }
    }
    
    // Biến tạm để lưu rating đang edit (nếu có)
    private var editingRatingObj: RatingFor?

    // MARK: - UI Components
    
    // 1. Container View (Hộp thoại trắng)
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground // Màu trắng/đen tuỳ theme
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 2. Question Label
    private let questionLabel = UILabel.customLabel(
        text: "How was your experience with this traveler?",
        font: UIFont.systemFont(ofSize: 16, weight: .medium),
        textColor: .label
    )
    
    // 3. Stars Container
    private var starImageViews: [UIImageView] = []
    private lazy var starStackView: UIStackView = {
        // Tạo 5 ngôi sao
        for i in 1...5 {
            let iv = UIImageView()
            iv.image = UIImage(systemName: "star")
            iv.tintColor = .systemOrange
            iv.contentMode = .scaleAspectFit
            iv.isUserInteractionEnabled = true
            iv.tag = i // Tag dùng để biết sao thứ mấy
            
            // Add tap gesture cho từng sao
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapStar(_:)))
            iv.addGestureRecognizer(tap)
            
            starImageViews.append(iv)
            
            // Ràng buộc kích thước sao cho đẹp
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 35).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 35).isActive = true
        }
        
        let stack = UIStackView.customStack(
            axis: .horizontal,
            alignment: .center,
            distribution: .fillEqually,
            stackSpacing: 8
        )
        // Add sao vào stack
        starImageViews.forEach { stack.addArrangedSubview($0) }
        return stack
    }()
    
    // 4. Buttons
    private lazy var cancelButton = UIButton.customButton(text: "Cancle", backgroundColor: .systemGray4, textColor: .label)
    
    private lazy var confirmButton = UIButton.customButton(text: "Confirm", backgroundColor: .authBackground2)
    
    private lazy var deleteButton = UIButton.customButton(text: "Delete rating", backgroundColor: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkEditMode()
        setupAction()
        binding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.editingRating.send(nil)
    }
    
    // MARK: - Setup Logic
    private func checkEditMode() {
        // Kiểm tra xem có đang edit không
        if let editingItem = viewModel.editingRating.value {
            self.editingRatingObj = editingItem
            
            // Set UI cho Edit Mode
            self.currentRating = editingItem.num
            self.confirmButton.configuration?.title = "Update"
            self.deleteButton.isHidden = false // Hiện nút xoá
            self.questionLabel.text = "Update your rating for this user?"
        } else {
            // Create Mode
            self.currentRating = 0
            self.confirmButton.configuration?.title = "Confirm"
            self.deleteButton.isHidden = true
        }
    }
    
    private func setupUI() {
        questionLabel.numberOfLines = 0
        viewModel.checkRating(otherId: self.otherUserId!)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4) // Nền tối mờ
        
        view.addSubview(containerView)
        
        // StackView chứa Buttons (Cancel & Confirm)
        let buttonStack = UIStackView.customStack(
            axis: .horizontal,
            alignment: .fill,
            distribution: .fillEqually,
            stackSpacing: 16
        )
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(confirmButton)
        
        // StackView tổng (Vertical)
        let mainStack = UIStackView.customStack(
            axis: .vertical,
            alignment: .center,
            distribution: .fill,
            stackSpacing: 20
        )
        
        mainStack.addArrangedSubview(questionLabel)
        mainStack.addArrangedSubview(starStackView)
        
        // Nếu là Edit thì nhét thêm nút Delete vào giữa
        mainStack.addArrangedSubview(deleteButton)
        
        mainStack.addArrangedSubview(buttonStack)
        
        // Layout container
        containerView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container nằm giữa màn hình
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            
            // Main Stack nằm gọn trong Container (có padding)
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Chiều rộng nút
            buttonStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Hiệu ứng hiện lên (Scale animation)
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        containerView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }

    // MARK: - Actions & Logic
    
    @objc private func didTapStar(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        // Tag được đánh từ 1 -> 5
        self.currentRating = tappedView.tag
    }
    
    private func updateStarUI() {
        for (index, iv) in starImageViews.enumerated() {
            let starValue = index + 1
            if starValue <= currentRating {
                iv.image = UIImage(systemName: "star.fill")
            } else {
                iv.image = UIImage(systemName: "star")
            }
        }
    }
    
    private func setupAction() {
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
    
    @objc private func didTapDelete() {
        guard let otherId = otherUserId,
              let ratingId = editingRatingObj?.id else { return }
        
        // Gọi hàm Delete
        viewModel.deleteRating(ratingId: ratingId, otherUserId: otherId)
        dismiss(animated: true)
    }
    
    @objc private func didTapConfirm() {
        guard let otherId = otherUserId,
              let myId = AuthService.shared.currentUserId else {
            print("❌ Lỗi: Thiếu ID User")
            return
        }
        
        if currentRating == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: .showGlobalToast,
                    object: nil,
                    userInfo: [
                        "message": "You need to rating first to confirm!",
                        "isSuccess": false
                    ]
                )
            }
            // Có thể hiện alert bắt user chọn sao
            return
        }
        
        if let editingItem = editingRatingObj, let ratingId = editingItem.id {
            // --- CASE UPDATE ---
            viewModel.updateRating(ratingId: ratingId, newNum: currentRating, otherUserId: otherId)
        } else {
            // --- CASE ADD NEW ---
            // Model RatingFor giả định
            let newRating = RatingFor(
                userId: myId,
                otherUserId: otherId,
                num: currentRating
            )
            viewModel.addRating(rating: newRating)
        }
        
        dismiss(animated: true)
    }
    
    //MARK: - BINDDING
    private func binding() {
        viewModel.editingRating
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkEditMode()
            }
            .store(in: &cancellable)
    }
}
