//
//  RepplyComponentView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//

import UIKit
import Combine
import PhotosUI

class RepplyComponentView: UIView {
    
    var onTapAttackImage: (() -> Void)?
    var onTapAttackVideo: (() -> Void)?
    var onTapAttackTakePhoto: (() -> Void)?
    var onSend: (() -> Void)?
    var onTapReviewImage: (() -> Void)?
    var onTapReviewVideo: (() -> Void)?
    var onTapCancel: (() -> Void)?
    var imageViewModel: ImageViewModel!
    var chat: String = ""
    
    private let messageViewModel = CommentViewModel.shared
    private var cancellable = Set<AnyCancellable>()
    
    private let images = ImageAttachmentView()
    private let video = VideoAttachmentView()
    private let chatBox = ChatInputTextView()
    private let sendBtn = UIButton.customButton(image: UIImage(systemName: "paperplane.fill"), backgroundColor: .authBackground2, tintColor: .white, isCircle: true)
    private let attackmentImageBtn = UIButton.customButton(image: UIImage(systemName: "photo"), backgroundColor: .clear, tintColor: .systemGray3)
    private let attackmentVideoBtn = UIButton.customButton(image: UIImage(systemName: "video.fill"), backgroundColor: .clear, tintColor: .systemGray3)
    private let attackmentTakePhoto = UIButton.customButton(image: UIImage(systemName: "camera.fill"), backgroundColor: .clear, tintColor: .systemGray3)
    private let appendBtn = UIButton.customButton(image: UIImage(systemName: "chevron.right"), backgroundColor: .clear, tintColor: .authBackground2)
    private let cancelBtn = UIButton.customButton(image: UIImage(systemName: "xmark"), backgroundColor: .clear, tintColor: .systemGray)
    private var startChating: Bool = false
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        binding()
        action()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        let mainstack = UIStackView.customStack(xPadding: 8, yPadding: 12, axis: .horizontal, alignment: .bottom, distribution: .fill)
        addSubview(images)
        addSubview(video)
        addSubview(mainstack)
        addSubview(cancelBtn)
        mainstack.addArrangedSubview(appendBtn)
        mainstack.addArrangedSubview(attackmentTakePhoto)
        mainstack.addArrangedSubview(attackmentImageBtn)
        mainstack.addArrangedSubview(attackmentVideoBtn)
        mainstack.addArrangedSubview(chatBox)
        mainstack.addArrangedSubview(sendBtn)
        
        images.translatesAutoresizingMaskIntoConstraints = false
        video.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainstack.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainstack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainstack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainstack.topAnchor.constraint(equalTo: images.bottomAnchor, constant: 4),
            
            images.topAnchor.constraint(equalTo: video.bottomAnchor),
            images.leadingAnchor.constraint(equalTo: video.leadingAnchor),
            
            video.topAnchor.constraint(equalTo: topAnchor),
            video.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            cancelBtn.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            cancelBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
        ])
        if let container = self.superview {
            video.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.6).isActive = true
            video.heightAnchor.constraint(equalTo: video.widthAnchor, multiplier: 3/4).isActive = true
        }
}
    
    private func renderVideoImage() {
        let imgs = imageViewModel.uploadedUrls
        let thumnail = imageViewModel.VideoThumbnail
        let videoUrl = imageViewModel.videoUrl
        if !imgs.isEmpty {
            images.isHidden = false
            images.configure(urls: imgs)
            attackmentTakePhoto.isEnabled = false
            attackmentVideoBtn.isEnabled = false
            cancelBtn.isHidden = false
        } else if !thumnail.isEmpty || !videoUrl.isEmpty {
            video.isHidden = false
            video.configure(videoThumbnail: thumnail)
            attackmentTakePhoto.isEnabled = false
            attackmentVideoBtn.isEnabled = false
            attackmentImageBtn.isEnabled = false
            chatBox.text = ""
            chatBox.placeholder = "Send a message..."
            chatBox.isEditable = false
            cancelBtn.isHidden = false
        } else {
            images.isHidden = true
            video.isHidden = true
            attackmentTakePhoto.isEnabled = true
            attackmentVideoBtn.isEnabled = true
            attackmentImageBtn.isEnabled = true
            chatBox.isEditable = true
            cancelBtn.isHidden = true
        }
    }
    
    //MARK: - ACTION
    private func action() {
        appendBtn.addTarget(self, action: #selector(appendAction), for: .touchUpInside)
        
        attackmentImageBtn.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)
        
        attackmentVideoBtn.addTarget(self, action: #selector(didTapSelectVideo), for: .touchUpInside)
        
        attackmentTakePhoto.addTarget(self, action: #selector(didTapSelectTakePhoto), for: .touchUpInside)
        
        sendBtn.addTarget(self, action: #selector(didTapSendMessage), for: .touchUpInside)
        
        cancelBtn.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        
        images.onTapImage = { [weak self] in
            self?.onTapReviewImage?()
        }
        video.onTap = { [weak self] in
            self?.onTapReviewVideo?()
        }
        
    }
    
    @objc private func appendAction() {
        self.appendBtn.isHidden = true
        self.attackmentImageBtn.isHidden = false
        self.attackmentVideoBtn.isHidden = false
        self.attackmentTakePhoto.isHidden = false
    }
    
    @objc private func didTapSelectImage() {
        onTapAttackImage?()
    }
    
    @objc private func didTapSelectVideo() {
        onTapAttackVideo?()
    }
    
    @objc private func didTapSelectTakePhoto() {
        onTapAttackTakePhoto?()
    }
    
    @objc private func didTapSendMessage() {
        onSend?()
    }
    
    @objc private func didTapCancel() {
        onTapCancel?()
    }
    
    //MARK: - BINDING
    private func binding() {
        imageViewModel.$videoUrl
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.renderVideoImage()
            }
            .store(in: &cancellable)
        
        imageViewModel.loading
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.sendBtn.isEnabled = !loading
            }
            .store(in: &cancellable)
        
        imageViewModel.$uploadedUrls
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.renderVideoImage()
            }
            .store(in: &cancellable)
        
        chatBox.isTypingPublisher
            .sink { [weak self] isTyping in
                guard let self = self else { return }
                
                if isTyping {
                    self.appendBtn.isHidden = false
                    self.attackmentImageBtn.isHidden = true
                    self.attackmentVideoBtn.isHidden = true
                    self.attackmentTakePhoto.isHidden = true
                    self.chat = self.chatBox.text
                }
            }
            .store(in: &cancellable)
    }
}
