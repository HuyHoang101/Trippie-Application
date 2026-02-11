//
//  StackImagePickerView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/3/26.
//

import UIKit

protocol StackImagePickerDelegate: AnyObject {
    func didTapSelectImage()
    func didTapDeleteAll()
}

class StackImagePickerView: UIView {
    
    weak var delegate: StackImagePickerDelegate?
    
    //MARK: - UI COMPONENT
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingView = TrippieLoadingView()
    
    private let placeholderLabel = UILabel.customLabel(text: "No image selected", font: .systemFont(ofSize: 14), textColor: .systemGray3, textAligment: .center)
    public var actionButton = UIButton.customButton(text: "Select photos", backgroundColor: .button, imageName: "photo.on.rectangle", isSystemImage: true)
    
    
    //MARK: - LYFE CYCLE
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        setupAction()
        updateButtonState(false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.addDashedBorder()
        
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        addSubview(containerView)
        addSubview(actionButton)
        containerView.addSubview(placeholderLabel)
        containerView.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.isHidden = true
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -15),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.6),
            
            loadingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            placeholderLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func renderImages(_ images: [String]) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        self.layoutIfNeeded()
        
        if images.isEmpty {
            containerView.addSubview(placeholderLabel)
            placeholderLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            placeholderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        }
        
        let displayLimit = min(images.count, 3)
        
        for (index, image) in images.prefix(displayLimit).enumerated().reversed() {
            let iv = TrippieImageView(style: .rounded(radius: 8, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]), isShadow: true)
            iv.setImage(url: image)
            iv.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                iv.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: displayLimit == 1 ? 0 : -5),
                
                iv.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.9),
                iv.heightAnchor.constraint(equalTo: iv.widthAnchor, multiplier: 0.6)
            ])
            
            if index != 0 {
                // Tỷ lệ thu nhỏ: Mỗi tấm sau nhỏ hơn tấm trước 5%
                let scale = 1.0 - (CGFloat(index) * 0.08)
                
                // Độ dịch xuống: Mỗi tấm sau tụt xuống 15pt so với tâm
                // (chỉnh số 12 thành số khác để giãn khoảng cách tuỳ ý)
                let translationY = CGFloat(index) * 12.0
                
                // Áp dụng Transform: Dịch xuống trước -> sau đó mới Thu nhỏ
                iv.transform = CGAffineTransform(translationX: 0, y: translationY)
                                .scaledBy(x: scale, y: scale)
                
                // (Optional) Làm mờ nhẹ các tấm sau để tạo chiều sâu
                iv.alpha = 1.0 - (CGFloat(index) * 0.2)
            } else {
                // Tấm index 0: Giữ nguyên, không transform, rõ nét nhất
                iv.transform = .identity
                iv.alpha = 1.0
            }
        }
        
        if images.count > displayLimit {
            let label = UILabel.customLabel(text: "+ \(images.count - displayLimit)", font: .systemFont(ofSize: 16, weight: .semibold), textColor: .white)
            containerView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        }
        
        containerView.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        
        updateButtonState(!images.isEmpty)
    }
    
    private func updateButtonState(_ hasImages: Bool) {
        var config = actionButton.configuration ?? UIButton.Configuration.filled()
        
        if hasImages {
            config.title = "Cancel All Photos"
            config.image = UIImage(systemName: "trash")
            config.baseBackgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            config.baseForegroundColor = .white
        } else {
            config.title = "Select photos"
            config.image = UIImage(systemName: "photo.on.rectangle")
            config.baseBackgroundColor = .button
            config.baseForegroundColor = .white
        }
        config.imagePadding = 8
        config.imagePlacement = .leading
        
        actionButton.configuration = config
    }
    
    //MARK: - SETUP ACTION
    private func setupAction() {
        actionButton.removeTarget(nil, action: nil, for: .allEvents)
        actionButton.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }
    
    @objc private func handleButtonTap() {
        print("Debug: is tapped!")
        let currentTitle = actionButton.configuration?.title ?? ""
        if currentTitle.contains("Cancel") {
            delegate?.didTapDeleteAll()
        } else {
            delegate?.didTapSelectImage()
        }
    }
    
    func imageLoading(_ isLoading: Bool) {
        if isLoading {
            self.loadingView.isHidden = false
            self.loadingView.start()
            self.actionButton.isEnabled = false
            self.actionButton.configuration?.baseBackgroundColor = .authBackground1.withAlphaComponent(0.4)
        } else {
            self.loadingView.isHidden = true
            self.loadingView.stop()
            self.actionButton.isEnabled = true
        }
    }
}
