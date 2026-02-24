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
    var imageViewModel: ImageViewModel! {
        didSet {
            binding()
            renderVideoImage(videoLoading: false)
        }
    }
    var chat: String {
        return chatBox.text
    }
    
    private var cancellable = Set<AnyCancellable>()
    
    private let images = ImageAttachmentView()
    private let video = VideoAttachmentView()
    private let chatBox = ChatInputView()
    private let sendBtn = UIButton.customButton(image: UIImage(systemName: "paperplane.fill"), backgroundColor: .authBackground2, tintColor: .white, isCircle: true)
    private let attackmentImageBtn = UIButton.customButton(image: UIImage(systemName: "photo"), backgroundColor: .clear, tintColor: .systemGray3, padding: 3)
    private let attackmentVideoBtn = UIButton.customButton(image: UIImage(systemName: "video.fill"), backgroundColor: .clear, tintColor: .systemGray3, padding: 3)
    private let attackmentTakePhoto = UIButton.customButton(image: UIImage(systemName: "camera.fill"), backgroundColor: .clear, tintColor: .systemGray3, padding: 3)
    private let appendBtn = UIButton.customButton(image: UIImage(systemName: "chevron.right"), backgroundColor: .clear, tintColor: .authBackground2, padding: 3)
    private let cancelBtn = UIButton.customButton(image: UIImage(systemName: "xmark"), backgroundColor: .clear, tintColor: .systemGray, padding: 3)
    private var startChating: Bool = false
    
    private let rootStack = UIStackView.customStack(yPadding: 12, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 4)
    
    private let vstack1 = UIStackView.customStack(xPadding: 8, axis: .vertical, alignment: .leading, distribution: .fill)
    
    //MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        action()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        let mainstack = UIStackView.customStack(xPadding: 8, axis: .horizontal, alignment: .bottom, distribution: .fill)
        addSubview(rootStack)
        addSubview(cancelBtn)
        
        rootStack.addArrangedSubview(vstack1)
        rootStack.addArrangedSubview(mainstack)
        
        vstack1.addArrangedSubview(video)
        vstack1.addArrangedSubview(images)
        
        mainstack.addArrangedSubview(appendBtn)
        mainstack.addArrangedSubview(attackmentTakePhoto)
        mainstack.addArrangedSubview(attackmentImageBtn)
        mainstack.addArrangedSubview(attackmentVideoBtn)
        mainstack.addArrangedSubview(chatBox)
        mainstack.addArrangedSubview(sendBtn)
        
        images.translatesAutoresizingMaskIntoConstraints = false
        video.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            
            cancelBtn.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            cancelBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            appendBtn.widthAnchor.constraint(equalToConstant: 36),
            appendBtn.heightAnchor.constraint(equalToConstant: 36),
            
            attackmentImageBtn.widthAnchor.constraint(equalToConstant: 36),
            attackmentImageBtn.heightAnchor.constraint(equalToConstant: 36),
            
            attackmentVideoBtn.widthAnchor.constraint(equalToConstant: 36),
            attackmentVideoBtn.heightAnchor.constraint(equalToConstant: 36),
            
            attackmentTakePhoto.widthAnchor.constraint(equalToConstant: 36),
            attackmentTakePhoto.heightAnchor.constraint(equalToConstant: 36),
            
            sendBtn.widthAnchor.constraint(equalToConstant: 40),
            sendBtn.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        images.isHidden = true
        video.isHidden = true
        cancelBtn.isHidden = true
        appendBtn.isHidden = true
    }
    
    private func renderVideoImage(videoLoading: Bool) {
        let imgs = imageViewModel.uploadedUrls
        let thumnail = imageViewModel.VideoThumbnail
        let videoUrl = imageViewModel.videoUrl
        
        // Reset state
        vstack1.isHidden = false
        images.isHidden = true
        video.isHidden = true
        cancelBtn.isHidden = true
        
        // Enable buttons back
        attackmentTakePhoto.isEnabled = true
        attackmentVideoBtn.isEnabled = true
        attackmentImageBtn.isEnabled = true
        chatBox.isEditable = true
        

        if !imgs.isEmpty {
            images.isHidden = false
            images.configure(urls: imgs)
            attackmentTakePhoto.isEnabled = false
            attackmentVideoBtn.isEnabled = false
            attackmentImageBtn.isEnabled = false
        } else {
            images.isHidden = true
        }
        
        
        if !thumnail.isEmpty || !videoUrl.isEmpty {
            video.isHidden = false
            video.configure(videoThumbnail: thumnail, isLoading: videoLoading)
            attackmentTakePhoto.isEnabled = false
            attackmentVideoBtn.isEnabled = false
            attackmentImageBtn.isEnabled = false
        } else {
            video.isHidden = true
        }
        
        
        if !imgs.isEmpty && imgs[0] != "placeholder_bending" {
            cancelBtn.isHidden = false
        } else {
            cancelBtn.isHidden = true
            
            if (!thumnail.isEmpty || !videoUrl.isEmpty) && thumnail != "Thumbnail_loading" {
                cancelBtn.isHidden = false
            } else {
                cancelBtn.isHidden = true
            }
        }
        
        video.widthAnchor.constraint(equalToConstant: 150).isActive = true
        video.heightAnchor.constraint(equalTo: video.widthAnchor, multiplier: 3/4).isActive = true
        
        UIView.animate(withDuration: 0.3) {
            // Ép thằng View cha (GroupMessageViewController.view) update lại layout
            // Để nó đẩy cái khung chat lên trần thay vì bành xuống dưới
            self.superview?.layoutIfNeeded()
            
            // Cập nhật các element bên trong chính nó
            self.layoutIfNeeded()
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
        self.chatBox.text = ""
    }
    
    @objc private func didTapCancel() {
        onTapCancel?()
    }
    
    //MARK: - BINDING
    private func binding() {
        imageViewModel.$VideoThumbnail
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] l in
                let link = l == "Thumbnail_loading"
                self?.renderVideoImage(videoLoading: link)
            }
            .store(in: &cancellable)
        
        
        imageViewModel.loading
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.sendBtn.isEnabled = !loading
                self?.cancelBtn.isEnabled = !loading
                if loading {
                    self?.attackmentImageBtn.isEnabled = !loading
                    self?.attackmentVideoBtn.isEnabled = !loading
                    self?.attackmentTakePhoto.isEnabled = !loading
                }
                
            }
            .store(in: &cancellable)
        
        imageViewModel.$uploadedUrls
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.renderVideoImage(videoLoading: false)
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
                }
            }
            .store(in: &cancellable)
    }
    
    func updateChat(chatText: String) {
        self.chatBox.text = chatText
    }
    
    func activeVideoImage(isActive: Bool) {
        self.attackmentImageBtn.isEnabled = isActive
        self.attackmentVideoBtn.isEnabled = isActive
        self.attackmentTakePhoto.isEnabled = isActive
    }
}
