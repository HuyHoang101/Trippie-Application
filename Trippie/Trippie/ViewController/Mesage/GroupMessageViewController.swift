//
//  GroupMessageViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//

import UIKit
import PhotosUI
import Combine

class GroupMessageViewController: FadeBaseViewController {
    
    var navigationTitle: String?
    var tripId: String?
    
    private let commentViewModel = CommentViewModel.shared
    private let imageViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    private let tableView = UITableView()
    private let replyLabel = RepplyComponentView()
    private let beginLabel = UILabel.customLabel(text: "Say hello and start chating with you friends.", font: .systemFont(ofSize: 14), textColor: .systemGray3, textAligment: .center)
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    private var displayData: [Comment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        replyLabel.imageViewModel = self.imageViewModel
        
        view.addSubview(tableView)
        view.addSubview(replyLabel)
        view.addSubview(beginLabel)
        
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: replyLabel.topAnchor),
            
            replyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            replyLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            beginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            beginLabel.bottomAnchor.constraint(equalTo: replyLabel.topAnchor, constant: -40),
            
            beginLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        ])
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let menuBtn = DropdownButton()
        
        // 2. Gán items
        var dropDownItems: [DropdownItem] = []
        
        dropDownItems.append(DropdownItem(title: "All Images", icon: "photos.fill", type: .normal) { [weak self] in
            guard let self = self else { return }
            
        })
        dropDownItems.append(DropdownItem(title: "All Videos", icon: "videos.fill", type: .normal) { [weak self] in
            guard let self = self else { return }
            
        })
        menuBtn.items = dropDownItems
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: menuBtn)
        
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItem = rightItem
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func resetOldData() {
        self.displayData = []
        self.tableView.reloadData()
    }
    
    private func addDateForMessage() {
    
        guard !displayData.isEmpty else { return }
        
        var newData: [Comment] = []
        let threeHours: TimeInterval = 3 * 60 * 60
        
        for (index, currentMsg) in displayData.enumerated() {
            
            
            if index > 0 {
                let prevMsg = displayData[index - 1]
                
                if let currentDate = currentMsg.createdAt,
                   let prevDate = prevMsg.createdAt {
                    
                    if currentDate.timeIntervalSince(prevDate) > threeHours {
                        
                        let separator = Comment(
                            id: UUID().uuidString, // ID phải unique để không lỗi List
                            userId: "",           // Rỗng theo ý cậu
                            userName: "",
                            userAvatar: "",
                            role: .member,        // ⚠️ Lưu ý: Chọn 1 case mặc định của Enum
                            imageUrls: [],
                            videoUrl: "",
                            videoThumbnail: "",
                            message: "",          // Message rỗng
                            createdAt: currentDate, // Lấy ngày của tin nhắn sau để hiển thị
                            updatedAt: currentDate
                        )
                        
                        newData.append(separator)
                    }
                }
            }
            
            newData.append(currentMsg)
        }

        self.displayData = newData
    }
    
    
    // MARK: - ACTION
    private func setupAction() {
        replyLabel.onTapAttackImage = {[weak self] in
            guard let self = self else {return}
            
        }
        replyLabel.onTapAttackVideo = {[weak self] in
            guard let self = self else {return}
            
        }
        replyLabel.onTapAttackTakePhoto = {[weak self] in
            guard let self = self else {return}
            
        }
        replyLabel.onTapReviewImage = {[weak self] in
            guard let self = self else {return}
            self.didTapReviewImage()
        }
        replyLabel.onTapReviewVideo = {[weak self] in
            guard let self = self else {return}
            
        }
        replyLabel.onSend = {[weak self] in
            guard let self = self else {return}
            self.didTapSend()
        }
    }
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func didTapReviewImage() {
        let fullVC = PhotoFullScreenViewController()
        fullVC.imageUrls = imageViewModel.uploadedUrls
        fullVC.modalPresentationStyle = .overFullScreen
        fullVC.modalTransitionStyle = .crossDissolve
        present(fullVC, animated: true)
    }
    
    private func didTapReviewVideo() {
        
    }
    
    private func didTapSend() {
        commentViewModel.sendComment(message: replyLabel.chat, imgUrls: imageViewModel.uploadedUrls, videoUrl: imageViewModel.videoUrl, thumbnailUrl: imageViewModel.VideoThumbnail)
        imageViewModel.uploadedUrls = []
        imageViewModel.videoUrl = ""
        imageViewModel.VideoThumbnail = ""
    }
    
    private func didTapCancel() {
        imageViewModel.deleteAllImages()
    }
    
    private func didTapChooseImage() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func didTapChooseVideo() {
        
    }
    
    private func didTapChooseTakePhoto() {
        
    }
    
    
    //MARK: - BINDING
    @objc private func binding() {
        
        commentViewModel.comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] c in
                guard let self = self else { return }
                self.displayData = c
                self.addDateForMessage()
                self.beginLabel.isHidden = !self.displayData.isEmpty
                self.tableView.reloadData()
            }
            .store(in: &cancellable)
    }
}


// MARK: - TABLEVIEW DATASOURCE
extension GroupMessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell", for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }
        
        let item = displayData[indexPath.row]
        
        let (hideName, hideAvatar): (Bool, Bool) = isHideNameandHideAvatarAction(index: indexPath.row)
        cell.configure(comment: item, isHideAvatar: hideAvatar, isHideName: hideName)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        cell.onPlayVideoCallback = { [weak self] in
            guard let self = self else { return }
            let video = item.videoUrl
        }
        
        cell.onPreviewImagesCallback = { [weak self] in
            guard let self = self else { return }
            let fullVC = PhotoFullScreenViewController()
            fullVC.imageUrls = item.imageUrls
            fullVC.modalPresentationStyle = .overFullScreen
            fullVC.modalTransitionStyle = .crossDissolve
            present(fullVC, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrip = displayData[indexPath.row]
        
    }
    
    func isHideNameandHideAvatarAction(index: Int) -> (Bool, Bool) {
        // Lấy userId hiện tại
        let currentUserId = displayData[index].userId
        
        // 1. LOGIC ẨN TÊN (Hide Name)
        // Tên bị ẩn khi: Nó KHÔNG phải tin đầu tiên VÀ tin phía TRƯỚC nó có cùng userId
        let isHideName: Bool
        if index > 0 {
            let prevUserId = displayData[index - 1].userId
            isHideName = (prevUserId == currentUserId)
        } else {
            // Tin đầu tiên của cả list -> Luôn hiện tên (Không ẩn)
            isHideName = false
        }
        
        // 2. LOGIC ẨN AVATAR (Hide Avatar)
        // Avatar bị ẩn khi: Nó KHÔNG phải tin cuối cùng VÀ tin phía SAU nó có cùng userId
        let isHideAvatar: Bool
        if index < displayData.count - 1 {
            let nextUserId = displayData[index + 1].userId
            isHideAvatar = (nextUserId == currentUserId)
        } else {
            // Tin cuối cùng của cả list -> Luôn hiện avatar (Không ẩn)
            isHideAvatar = false
        }
        
        return (isHideName, isHideAvatar)
    }
}


extension GroupMessageViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        Task {
            // 1. Xử lý song song để lấy mảng DATA
            let optimizedDataArray = await withTaskGroup(of: Data?.self) { group -> [Data] in
                for result in results {
                    group.addTask {
                        // Gọi hàm mới trả về Data
                        return await result.loadResizedImage(targetSize: 1024)
                    }
                }
                
                var dataList: [Data] = []
                for await data in group {
                    if let validData = data {
                        dataList.append(validData)
                    }
                }
                return dataList
            }
            
            // 2. Upload (Lúc này cậu cần đảm bảo ViewModel có hàm nhận [Data])
            // Không cần chuyển đổi gì nữa, tiết kiệm rất nhiều bộ nhớ!
            self.imageViewModel.uploadImages(optimizedDataArray, folder: "chats")
        }
    }
}
