//
//  CustomConfirmAlertView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/29/26.
//

import UIKit

class CustomConfirmAlertView: UIView {
    private let containerView = UIView()
    private var completion: ((Bool) -> Void)?
    
    
    //MARK: - Init
    init(type: ConfirmActionType, title: String, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(frame: .zero)
        
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    //MARK: - Setup UI
    private func setupUI(type: ConfirmActionType, title: String) {
        self.backgroundColor = UIColor.black.withAlphaComponent(0)
        self.frame = UIScreen.main.bounds
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOpacity = 0.2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerView)
        
        let iconImage = UIImageView(image: UIImage(systemName: type.iconName))
        iconImage.tintColor = type.color
        iconImage.contentMode = .scaleAspectFit
        iconImage.heightAnchor.constraint(equalToConstant: 40).isActive = true
        iconImage.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        let label = UILabel.customLabel(text: "", font: .systemFont(ofSize: 16, weight: .regular), textColor: .label, textAligment: .center)
        label.numberOfLines = 0
        let fullText = "Do you want to \(type.verb) \(title)?"
        let attString = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.black
        ])
        // In đậm tên (title)
        if let range = fullText.range(of: title) {
            let nsRange = NSRange(range, in: fullText)
            attString.addAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .bold)], range: nsRange)
        }
        label.attributedText = attString
        
        let cancelBtn = UIButton.customButton(text: "Cancel", font: .systemFont(ofSize: 14, weight: .medium), backgroundColor: .systemGray5, textColor: .black)
        cancelBtn.layer.cornerRadius = 8
        cancelBtn.addTarget(self, action: #selector(didTapCancle), for: .touchUpInside)
        
        
        let confirmBtn = UIButton.customButton(text: "Confirm", font: .systemFont(ofSize: 14, weight: .medium), backgroundColor: type.color, textColor: .white)
        confirmBtn.layer.cornerRadius = 8
        confirmBtn.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        
        let btnStack = UIStackView(arrangedSubviews: [cancelBtn, confirmBtn])
        btnStack.axis = .horizontal
        btnStack.spacing = 12
        btnStack.distribution = .fillEqually
        btnStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let mainStack = UIStackView(arrangedSubviews: [iconImage, label, btnStack])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
    }
    
    //MARK: - Action
    @objc private func didTapCancle() {
        dismiss(result: false)
    }
    @objc private func didTapConfirm() {
        dismiss(result: true)
    }
    
    // MARK: - Animations
    private func animateIn() {
        self.containerView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self.containerView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.35)
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func dismiss(result: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.backgroundColor = .clear
        }) { _ in
            self.removeFromSuperview()
            self.completion?(result) // Trả kết quả về
        }
    }
}
