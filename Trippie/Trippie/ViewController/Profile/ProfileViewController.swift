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
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    
    var anotherUserProfile: User?
    
    private let viewModel = LoginViewModel()
    private let viewModel2 = UserViewModel.shared
    private let imagesViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    
    //MARK: - UI COMPONENT
    private let notification = UIButton.customButton(image: UIImage(systemName: "bell"), backgroundColor: (UIColor.background), tintColor: .label, padding: 10)
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
    private let followLabel = UIButton.customButton(text: "+ Follow", font: .systemFont(ofSize: 15), backgroundColor: .clear, textColor: .authBackground2, isPadding: false)
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
        updateCacheUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        editViewContainer.clipsToBounds = true
        editViewContainer.layer.cornerRadius = editViewContainer.frame.width / 2
        applyCurve(to: decorateUI)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNavBar()
    }
    
    func updateCacheUI() {
        let sizeMB = GlobalCacheForApplication.calculateCurrentCacheSize()
        
        let sizeString = String(format: "%.1f MB", sizeMB)
        print("Memory Cache: \(sizeString)")
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        iconFriend.setLocalImage(name: "friend")
        iconRating.setLocalImage(name: "rating")
        iconRating.translatesAutoresizingMaskIntoConstraints = false
        iconFriend.translatesAutoresizingMaskIntoConstraints = false
        
        avatar.setLocalImage(name: "UerDefault")
        avatar.translatesAutoresizingMaskIntoConstraints = false
        
        editViewContainer.addSubview(editAvatarButton)
        
        view.addSubview(decorateUI)
        view.addSubview(avatar)
        
        
        let stack = UIStackView.customStack(xPadding: 15, yPadding: 20, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 10)
        stack.addArrangedSubview(nameLabel)
        if let id = anotherUserProfile?.id, id != AuthService.shared.currentUserId {
            let spacer1 = UIView()
            let spacer2 = UIView()
            let hstack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
            hstack.addArrangedSubview(spacer1)
            hstack.addArrangedSubview(followLabel)
            hstack.addArrangedSubview(spacer2)
            spacer1.translatesAutoresizingMaskIntoConstraints = false
            spacer2.translatesAutoresizingMaskIntoConstraints = false
            spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor).isActive = true
            stack.addArrangedSubview(hstack)
        } else {
            avatar.addSubview(editViewContainer)
            editViewContainer.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 0).isActive = true
            editViewContainer.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 0).isActive = true
            editAvatarButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.35 * 0.25).isActive = true
            editAvatarButton.heightAnchor.constraint(equalTo: editAvatarButton.widthAnchor).isActive = true
            viewModel2.fetchMyProfile()
        }
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
            
            iconFriend.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1),
            iconFriend.heightAnchor.constraint(equalTo: iconFriend.widthAnchor),
            iconRating.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.1),
            iconRating.heightAnchor.constraint(equalTo:iconRating.widthAnchor),
        ])
        
        renderProfile()
    }
    
    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        
        let menuBtn = DropdownButton()
        menuBtn.backgroundColor = .background
        
        // 2. Gán items
        if (anotherUserProfile?.id) != nil {
            menuBtn.items = [
                DropdownItem(title: "Rating", icon: "star.fill", type: .normal) { [weak self] in
                    guard let self = self else { return }
                    self.showRatingModal()
                },
            ]
        } else {
            menuBtn.items = [
                DropdownItem(title: "All Users", icon: "person.3.fill", type: .normal) { [weak self] in
                    guard let self = self else { return }
                    self.pushToAllUsersList()
                },
                DropdownItem(title: "Friends List", icon: "person.2.fill", type: .normal) { [weak self] in
                    guard let self = self else { return }
                    self.pushToFriendList()
                },
                DropdownItem(title: "Edit information", icon: "person.text.rectangle", type: .normal) { [weak self] in
                    guard let self = self else { return }
                    self.pushToEditingProfile()
                },
                DropdownItem(title: "Log out", icon: "rectangle.portrait.and.arrow.right", type: .destructive) { [weak self] in
                    guard let self = self else { return }
                    self.logoutAction()
                },
                DropdownItem(title: "Clear cache", icon: "bubbles.and.sparkles", type: .clear) { [weak self] in
                    guard let self = self else { return }
                    Task {
                        do {
                            await self.clearAllCache()
                        }
                    }
                }
            ]
        }
        
        let rightItem = UIBarButtonItem(customView: menuBtn)
        let leftItem = UIBarButtonItem(customView: notification)
        menuBtn.tintColor = .label
        
        self.navigationItem.rightBarButtonItem = rightItem
        
        self.navigationItem.leftBarButtonItem = leftItem
        
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.authBackground2.withAlphaComponent(0.7)
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func renderProfile() {
        // 1. Tạo biến user tạm thời
        var userToDisplay: User?
        
        // 2. Ưu tiên lấy Profile người khác nếu có
        if let anotherUser = anotherUserProfile {
            userToDisplay = anotherUser
        } else {
            // 3. Nếu không thì lấy Profile của mình
            userToDisplay = viewModel2.myProfile.value
        }
        
        // 4. Nếu cả 2 đều nil thì return (chưa có gì để hiện)
        guard let user = userToDisplay else { return }
        
        let name = (user.name.isEmpty == true) ? "Unknown User" : user.name
        nameLabel.text = name
        
        let email = (user.email.isEmpty == true) ? "abc@example.com" : user.email
        let phone = (user.phone.isEmpty == true) ? "+1 234 567 89" : user.phone
        emailAndPhoneLabel.text = "\(email) | \(phone)"
        
        avatar.setImage(url: user.avatarUrl, placeholderSystemName: "person.fill", pixel: 350)

        friendNumber.text = "\(user.friendIds.count)"
        
        ratingNumber.text = "\(user.rating)/5.0"
        ratingLabel.text = "\(user.ratingCount) rating"
        
        let address = user.address.isEmpty == true ? "None" : "\(user.address)"
        let aboutMe = user.aboutMe.isEmpty == true ? "Newbie of Trippie!" : "\(user.aboutMe)"
        
        addressLabel.attributedText = createBoldPrefixLabel(prefix: "Address: ", content: address)
        aboutMeLabel.attributedText = createBoldPrefixLabel(prefix: "About me: ", content: aboutMe)
        addressLabel.numberOfLines = 0
        aboutMeLabel.numberOfLines = 0
        aboutMeLabel.textAlignment = .justified
        
        
        notification.configuration?.image = UIImage(systemName: anotherUserProfile == nil ? "bell" : "arrow.left")
        guard let anotherId = anotherUserProfile?.id else { return }
        let isFriend = viewModel2.isMyFriend(userId: anotherId)
        followLabel.configuration?.title = isFriend ? "Following" : "+ Follow"
        followLabel.configuration?.baseForegroundColor = isFriend ? .authBackground1 : .authBackground2
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
        if (anotherUserProfile?.id) != nil {
            notification.addTarget(self, action: #selector(goBackAction), for: .touchUpInside)
            followLabel.addTarget(self, action: #selector(addFriendAction), for: .touchUpInside)
        } else {
            notification.addTarget(self, action: #selector(pushToNotification), for: .touchUpInside)
        }
        
    }
    
    @objc private func pushToNotification() {
        let vc = NotificationListViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func showRatingModal() {
        let vc = RatingModalViewController()
        vc.otherUserId = self.anotherUserProfile?.id// Truyền ID người được rate
        
        // Quan trọng: Set style này để nền trong suốt đè lên màn hình cũ
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve // Hiệu ứng mờ dần
        
        self.present(vc, animated: true)
    }

    @objc private func addFriendAction() {
        Task {
            await doAddFriendAction()
        }
    }
    
    @MainActor
    private func doAddFriendAction() async {
        guard let another = anotherUserProfile, let anotherId = another.id else { return }
        
        // Kiểm tra trạng thái bạn bè
        let isFriend = viewModel2.isMyFriend(userId: anotherId)
        
        // Hiển thị Alert xác nhận
        let isConfirmed = await confirmAlert(type: isFriend ? .unfollow : .follow, title: "\(another.name)?")
        
        if isConfirmed {
            self.viewModel2.toggleFriendship(targetUser: another)
            let id = AuthService.shared.currentUserId!
            if isFriend {
                if let ids = self.anotherUserProfile?.friendIds {
                    let filteredIds = ids.filter { $0 != id }
                    self.anotherUserProfile?.friendIds = filteredIds
                }
            } else {
                self.anotherUserProfile?.friendIds.append(id)
            }
        }
    }
    
    @objc private func goBackAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func logoutAction() {
        viewModel.logout()
    }
    
    @objc private func pushToEditingProfile() {
        let editProfileVC = HandSaveProfile()
        editProfileVC.viewModel = viewModel2
        viewModel2.editingProfile.send(viewModel2.myProfile.value)
        self.navigationController?.pushViewController(editProfileVC, animated: true)
    }
    
    @objc private func pushToFriendList() {
        let userListVC = FriendsOrMembersListViewController()
        userListVC.navigationTitle = "Friends"
        userListVC.listType = .friends
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc private func pushToAllUsersList() {
        let userListVC = FriendsOrMembersListViewController()
        userListVC.listType = .allUsers
        userListVC.navigationTitle = "All Users"
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc private func didTapSelectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @MainActor
    func clearAllCache() async {
        let isConfirmed = await confirmAlert(type: .clear, title: "")
        
        if isConfirmed {
            GlobalCacheForApplication.clearAllCache()
        }
    }
    
    @MainActor
    private func showConfirmAndUpdateAvatar(newUrl: String) async {
        // 1. Hiện preview ảnh mới cho user xem trước (Optimistic UI)
        self.avatar.setImage(url: newUrl)
        
        // 2. Hiện Alert hỏi
        let isConfirmed = await confirmAlert(type: .add, title: "your new avatar?")
        
        if isConfirmed {
            // --- ĐỒNG Ý ---
            self.viewModel2.updateAvatar(avatarUrl: newUrl)
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
        
        viewModel2.userAfterRating
            .receive(on: RunLoop.main)
            .filter { $0 != nil }
            .sink { [weak self] profile in
                self?.ratingLabel.text = "\(profile?.ratingCount ?? 0) rating"
                self?.ratingNumber.text = "\(profile?.rating ?? 0.0)/5.0"
                self?.viewModel2.userAfterRating.send(nil)
            }
            .store(in: &cancellable)
        
        imagesViewModel.$uploadedUrls
            .dropFirst()
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
        
        Publishers.CombineLatest(viewModel2.loading, imagesViewModel.loading)
            .receive(on: RunLoop.main)
            .sink { [weak self] (isLoadingUser, isLoadingImage) in
                // Logic OR: Chỉ cần 1 trong 2 đang load thì hiện Loading
                let shouldShowLoading = isLoadingUser || isLoadingImage
                
                if shouldShowLoading {
                    self?.showLoading() // Hàm hiện loading của cậu
                } else {
                    self?.hideLoading() // Hàm ẩn loading của cậu
                }
            }
            .store(in: &cancellable)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // 1. Lấy ảnh đã được người dùng cắt hình vuông
        guard let editedImage = info[.editedImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        
        picker.dismiss(animated: true)
        guard let imageData = editedImage.jpegData(compressionQuality: 0.8) else {
            print("can't change it to data")
            return
        }
        // 2. Xử lý Resize và Upload
        Task {
            // Gọi hàm resize targetSize: 1024
            if let resizedImage = ImageUtils.downsampleToData(imageData: imageData, maxDimension: 512) {
                self.imagesViewModel.uploadImages([resizedImage], folder: "avatars")
            } else {
                self.imagesViewModel.uploadImages([imageData], folder: "avatars")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
