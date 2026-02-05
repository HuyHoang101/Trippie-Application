//
//  ProfileViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine
import PhotosUI


class ProfileViewController: FadeBaseViewController {
    
    private let viewModel = LoginViewModel()
    private let viewModel2 = UserViewModel.shared
    private let imagesViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    
    //MARK: - UI COMPONENT
    private let multipleChoice = UIButton.customButton(image: UIImage(systemName: "ellipsis"), backgroundColor: (UIColor.background), tintColor: .label, padding: 12)
    private let notification = UIButton.customButton(image: UIImage(systemName: "bell"), backgroundColor: (UIColor.background), tintColor: .label, padding: 12)
    private let mainScroll = UIScrollView()
    private let maincontent = UIView()
    
    private let decorateUI: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.authBackground2.withAlphaComponent(0.7)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let editViewContainer: UIView = {
        let editViewContainer = UIView()
        editViewContainer.backgroundColor = .white
        editViewContainer.translatesAutoresizingMaskIntoConstraints = false
        return editViewContainer
    }()
    private let avatar = TrippieImageView(style: .circle, isShadow: true, borderColor: UIColor.background)
    private let editAvatarButton = UIButton.customButton(image: UIImage(systemName: "pencil"), backgroundColor: UIColor.systemGray5, tintColor: .black, isCircle: true, padding: 10)
    private let nameLabel = UILabel.customLabel(text: "Unknown User", font: AppTheme.Font.mainBold(size: 24), textColor: .label, textAligment: .center)
    private let emailAndPhoneLabel = UILabel.customLabel(text: "abc@example.com | +1 234 567 89", font: UIFont.systemFont(ofSize: 13, weight: .medium), textColor: .label, textAligment: .center)
    
    private let iconRating = TrippieImageView(style: .circle, isShadow: false, borderColor: .clear)
    private let iconFriend = TrippieImageView(style: .circle, isShadow: false, borderColor: .clear)
    private let friendNumber = UILabel.customLabel(text: "0", font: UIFont.systemFont(ofSize: 20, weight: .semibold), textColor: .label, textAligment: .center)
    private let ratingNumber = UILabel.customLabel(text: "0/5.0", font: UIFont.systemFont(ofSize: 20, weight: .semibold), textColor: .label, textAligment: .center)
    private let friendLabel = UILabel.customLabel(text: "Friends", font: UIFont.systemFont(ofSize: 14, weight: .regular), textColor: .label, textAligment: .center)
    private let ratingLabel = UILabel.customLabel(text: "0 rating", font: UIFont.systemFont(ofSize: 14, weight: .regular), textColor: .label, textAligment: .center)
    
    private let addressLabel = UILabel.customLabel(text: "Address: None", font: UIFont.systemFont(ofSize: 14, weight: .regular), textColor: .label)
    private let aboutMeLabel = UILabel.customLabel(text: "About me: New be form Trippie!", font: UIFont.systemFont(ofSize: 14, weight: .regular), textColor: .label)
    
    private let hstack1 = UIStackView.customStack(xPadding: 12, yPadding: 12, background: .systemBackground, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 5, cornerRadius: 12, isShadow: true)
    private let hstack2 = UIStackView.customStack(xPadding: 12, yPadding: 12, background: .systemBackground, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 5, cornerRadius: 12, isShadow: true)
    private let vstack1 = UIStackView.customStack(xPadding: 20, yPadding: 20, background: .systemBackground, axis: .vertical, alignment: .fill, distribution: .fill, cornerRadius: 12, isShadow: true)
    private let vstack2 = UIStackView.customStack(xPadding: 12, yPadding: 12, axis: .vertical, alignment: .fill, distribution: .fill)
    private let vstack3 = UIStackView.customStack(xPadding: 12, yPadding: 12, axis: .vertical, alignment: .fill, distribution: .fill)
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setAction()
        binding()
        bindLoading(to: viewModel2.loading)
        bindLoading(to: imagesViewModel.loading)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        editViewContainer.clipsToBounds = true
        editViewContainer.layer.cornerRadius = editViewContainer.frame.width / 2
        applyCurve(to: decorateUI)
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        
        iconFriend.setLocalImage(name: "friend")
        iconRating.setLocalImage(name: "rating")
        iconRating.translatesAutoresizingMaskIntoConstraints = false
        iconFriend.translatesAutoresizingMaskIntoConstraints = false
        
        viewModel2.fetchMyProfile()
        avatar.setLocalImage(name: "UerDefault")
        avatar.translatesAutoresizingMaskIntoConstraints = false
        
        editViewContainer.addSubview(editAvatarButton)
        avatar.addSubview(editViewContainer)
        
        view.addSubview(decorateUI)
        view.addSubview(avatar)
        
        
        let stack = UIStackView.customStack(xPadding: 15, yPadding: 20, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 10)
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(emailAndPhoneLabel)
        
        view.addSubview(stack)
        
        let stack2 = UIStackView.customStack(xPadding: 15, yPadding: 20, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 10)
        let stack3 = UIStackView.customStack(axis: .horizontal, alignment: .fill, distribution: .fill, stackSpacing: 10)
        
        view.addSubview(stack2)
        
        stack2.addArrangedSubview(stack3)
        stack2.addArrangedSubview(vstack1)
        
        stack3.addArrangedSubview(hstack1)
        stack3.addArrangedSubview(hstack2)
        
        hstack1.addArrangedSubview(iconFriend)
        hstack1.addArrangedSubview(vstack2)
        
        hstack2.addArrangedSubview(iconRating)
        hstack2.addArrangedSubview(vstack3)
        
        vstack1.addArrangedSubview(addressLabel)
        vstack1.addArrangedSubview(aboutMeLabel)
        
        vstack2.addArrangedSubview(friendNumber)
        vstack2.addArrangedSubview(friendLabel)
        
        vstack3.addArrangedSubview(ratingNumber)
        vstack3.addArrangedSubview(ratingLabel)
        
        
        NSLayoutConstraint.activate([
            decorateUI.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            decorateUI.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            decorateUI.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            decorateUI.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            avatar.centerXAnchor.constraint(equalTo: decorateUI.centerXAnchor),
            avatar.centerYAnchor.constraint(equalTo: decorateUI.bottomAnchor, constant: -15),
            avatar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.35),
            avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            
            stack.topAnchor.constraint(equalTo: avatar.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stack2.topAnchor.constraint(equalTo: stack.bottomAnchor),
            stack2.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack2.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            hstack1.widthAnchor.constraint(equalTo: hstack2.widthAnchor),
            
            editAvatarButton.topAnchor.constraint(equalTo: editViewContainer.topAnchor, constant: 3.5),
            editAvatarButton.bottomAnchor.constraint(equalTo: editViewContainer.bottomAnchor, constant: -3.5),
            editAvatarButton.leadingAnchor.constraint(equalTo: editViewContainer.leadingAnchor, constant: 3.5),
            editAvatarButton.trailingAnchor.constraint(equalTo: editViewContainer.trailingAnchor, constant: -3.5),
            
            editViewContainer.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 0),
            editViewContainer.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 0),
            editAvatarButton.widthAnchor.constraint(equalTo: avatar.widthAnchor, multiplier: 0.25),
            editAvatarButton.heightAnchor.constraint(equalTo: editAvatarButton.widthAnchor),
            
            iconFriend.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1),
            iconFriend.heightAnchor.constraint(equalTo: iconFriend.widthAnchor),
            iconRating.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1),
            iconRating.heightAnchor.constraint(equalTo:iconRating.widthAnchor),
        ])
        
        renderProfile()
        setupNavBar()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        
        let menuBtn = DropdownButton()
        
        // 2. Gán items
        menuBtn.items = [
            DropdownItem(title: "Edit information", icon: "person.text.rectangle", type: .normal) {
                print("")
            },
            DropdownItem(title: "Log out", icon: "rectangle.portrait.and.arrow.right", type: .destructive) {
                self.logoutAction()
            }
        ]
        
        let rightItem = UIBarButtonItem(customView: menuBtn)
        let leftItem = UIBarButtonItem(customView: notification)
        
        self.navigationItem.rightBarButtonItem = rightItem
        self.navigationItem.leftBarButtonItem = leftItem
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.authBackground2.withAlphaComponent(0.7)
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func renderProfile() {
        guard let user = viewModel2.myProfile.value else { return }
        
        let name = (user.name.isEmpty == true) ? "Unknown User" : user.name
        nameLabel.text = name
        
        let email = (user.email.isEmpty == true) ? "abc@example.com" : user.email
        let phone = (user.phone.isEmpty == true) ? "+1 234 567 89" : user.phone
        emailAndPhoneLabel.text = "\(email) | \(phone)"
        
        if  user.avatarUrl.isEmpty {
            avatar.setLocalImage(name: "UserDefault")
        } else {
            avatar.setImage(url: user.avatarUrl, placeholderSystemName: "person")
        }
        
        friendNumber.text = "\(user.friendIds.count)"
        
        ratingNumber.text = "\(user.rating)/5.0"
        ratingLabel.text = "\(user.ratingCount) rating"
        
        let address = user.address.isEmpty == true ? "None" : "\(user.address)"
        let aboutMe = user.aboutMe.isEmpty == true ? "Newbie of Trippie!" : "\(user.aboutMe)"
        
        addressLabel.attributedText = createBoldPrefixLabel(prefix: "Address: ", content: address)
        aboutMeLabel.attributedText = createBoldPrefixLabel(prefix: "About me: ", content: aboutMe)
        
    }
    
    func applyCurve(to view: UIView) {
        let width = view.bounds.width
        let height = view.bounds.height
        let curveHeight = 40.0

        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height - curveHeight))
        
        // Vẽ cung tròn đi qua 2 điểm lề
        path.addQuadCurve(to: CGPoint(x: 0, y: height - curveHeight),
                              controlPoint: CGPoint(x: width / 2, y: height + curveHeight))
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        view.layer.mask = mask
    }
    
    func createBoldPrefixLabel(prefix: String, content: String) -> NSAttributedString {
        
        let boldAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        
        let regularAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ]
        

        let finalString = NSMutableAttributedString(string: prefix, attributes: boldAttribute)
        let contentString = NSAttributedString(string: content, attributes: regularAttribute)
        finalString.append(contentString)
        
        return finalString
    }
    
    //MARK: - SETUP ACTION
    private func setAction() {
        editAvatarButton.addTarget(self, action: #selector(didTapSelectImage), for: .touchUpInside)
    }
    
    @objc private func logoutAction() {
        viewModel.logout()
    }
    
    
    @objc func didTapSelectImage() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @MainActor
    private func showConfirmAndUpdateAvatar(newUrl: String) async {
        // 1. Hiện preview ảnh mới cho user xem trước (Optimistic UI)
        self.avatar.setImage(url: newUrl)
        
        // 2. Hiện Alert hỏi
        let isConfirmed = await confirmAlert(type: .add, title: "your new avatar?")
        
        if isConfirmed {
            // --- ĐỒNG Ý ---
            var profile = self.viewModel2.myProfile.value
            profile?.avatarUrl = newUrl
            
            // Gọi API update profile...
            // self.viewModel2.updateProfile(profile)
            
            // Quan trọng: Sau khi xong việc, nên clear list url tạm đi để tránh trigger lại lần sau
            // (Tuỳ logic bên ViewModel của bạn có cần giữ lại không)
            // self.imagesViewModel.uploadedUrls = []
            
        } else {
            // --- HỦY ---
            // Revert về ảnh cũ từ Profile gốc
            if let oldUrl = self.viewModel2.myProfile.value?.avatarUrl, !oldUrl.isEmpty {
                self.avatar.setImage(url: oldUrl)
            } else {
                self.avatar.setLocalImage(name: "UserDefault")
            }
            
            // Xoá ảnh vừa up lên server
            self.imagesViewModel.deleteAllImages()
        }
    }
    
    //Mark: - Binding
    private func binding() {
        viewModel.logoutSuccess
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                if let window = self?.view.window {
                    let coordinator = AppCoordinator(window: window)
                    coordinator.showAuthFlow()
                }
            }
            .store(in: &cancellable)
        
        viewModel2.myProfile
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.renderProfile()
            }
            .store(in: &cancellable)
        
        imagesViewModel.$uploadedUrls // Giả sử biến này là @Published
            .dropFirst() // Bỏ qua giá trị khởi tạo đầu tiên (thường là rỗng)
            .receive(on: RunLoop.main)
            .sink { [weak self] urls in
                guard let self = self else { return }
                
                // Chỉ chạy khi có URL mới (tức là upload thành công)
                guard let newUrl = urls.first, !newUrl.isEmpty else { return }
                
                // Gọi hàm xử lý Async trong Sink
                Task {
                    await self.showConfirmAndUpdateAvatar(newUrl: newUrl)
                }
            }
            .store(in: &cancellable)
    }
}

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        var selectedImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        // Lấy UIImage từ kết quả chọn
        for result in results {
            dispatchGroup.enter()
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let img = image as? UIImage {
                        selectedImages.append(img)
                    }
                    dispatchGroup.leave()
                }
            } else {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.imagesViewModel.uploadImages(selectedImages, folder: "avatars")
        }
    }
}
