//
//  GroupMessageViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/12/26.
//

import UIKit
import PhotosUI
import Combine
import AVFoundation
import UniformTypeIdentifiers

class GroupMessageViewController: FadeBaseViewController {
    
    var navigationTitle: String?
    var tripId: String?
    
    var commentViewModel: CommentViewModel!
    private let imageViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    private let tableView = UITableView()
    private let replyLabel = RepplyComponentView()
    private let beginLabel = UILabel.customLabel(text: "Say hello and start chating with you friends.", font: .systemFont(ofSize: 14), textColor: .systemGray3, textAligment: .center)
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    private var isFetchingHistory = false
    private var displayData: [Comment] = []
    private var pendingRawData: [Comment]? = nil
    
    private var isUserInteracting = false
    private var interactionTimer: DispatchWorkItem?
    private var countToLoadHistory = 0
    private var trippieLoadingView = TrippieLoadingView2()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAction()
        binding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
        scrollToBottom()
        trippieLoadingView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countToLoadHistory = 0
    }
    
    
    private func setupUI() {
        UserViewModel.shared.fetchMyProfile()
        commentViewModel.joinChatRoom(tripId: tripId ?? "")
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        replyLabel.imageViewModel = self.imageViewModel
        
        view.addSubview(tableView)
        view.addSubview(replyLabel)
        view.addSubview(beginLabel)
        view.addSubview(trippieLoadingView)
        
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        trippieLoadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            trippieLoadingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            trippieLoadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trippieLoadingView.widthAnchor.constraint(equalTo: trippieLoadingView.heightAnchor),
            trippieLoadingView.heightAnchor.constraint(equalToConstant: 36),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: replyLabel.topAnchor),
            
            replyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            replyLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            
            beginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            beginLabel.bottomAnchor.constraint(equalTo: replyLabel.topAnchor, constant: -40),
            
            beginLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
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
    
    func adjustContentInsetToBottom() {
        // Đảm bảo layout đã tính toán xong
        self.view.layoutIfNeeded()
        
        let tableViewHeight = tableView.bounds.height
        let contentHeight = tableView.contentSize.height
        
        let bottomPadding: CGFloat = 20 // ✅ Khoảng đệm 20px ở đáy chuẩn vật lý
                
        // Nếu nội dung ngắn hơn chiều cao bảng -> Đẩy xuống
        if contentHeight < tableViewHeight {
            let topInset = tableViewHeight - contentHeight
            tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomPadding, right: 0)
        } else {
            // Nếu nội dung dài rồi thì reset top, chỉ giữ lại đệm đáy
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomPadding, right: 0)
        }
    }
    
    private func resetOldData() {
        self.displayData = []
        self.tableView.reloadData()
    }
    
    // XÓA hàm addDateForMessage() cũ và dùng hàm này:
    private func processCommentsWithSeparators(_ comments: [Comment]) -> [Comment] {
        guard !comments.isEmpty else { return [] }
        var newData: [Comment] = []
        let threeHours: TimeInterval = 3 * 60 * 60
        
        for i in 0..<comments.count {
            let currentMsg = comments[i]
            
            if i > 0 {
                let prevMsg = comments[i - 1]
                
                // 1. Thêm Date Separator (Dùng ID cố định thay vì UUID ngẫu nhiên)
                if let currentDate = currentMsg.createdAt, let prevDate = prevMsg.createdAt,
                   currentDate.timeIntervalSince(prevDate) > threeHours {
                    let dateSep = Comment(id: "date_\(currentMsg.id ?? "")", userId: "", userName: "", userAvatar: "", role: .member, imageUrls: [], videoUrl: "", videoThumbnail: "", message: "", createdAt: currentDate, updatedAt: currentDate)
                    newData.append(dateSep)
                }
                
                // 2. Thêm Space Separator (Dùng ID cố định)
                if prevMsg.userId != currentMsg.userId {
                    let spaceSep = Comment(id: "space_\(currentMsg.id ?? "")", userId: "", userName: "", userAvatar: "", role: .member, imageUrls: [], videoUrl: "", videoThumbnail: "", message: "", createdAt: nil, updatedAt: nil)
                    newData.append(spaceSep)
                }
            }
            newData.append(currentMsg)
        }
        return newData
    }
    
    // MARK: - ACTION
    private func setupAction() {
        replyLabel.onTapAttackImage = {[weak self] in
            guard let self = self else {return}
            self.didTapChooseImage()
        }
        replyLabel.onTapAttackVideo = {[weak self] in
            guard let self = self else {return}
            self.didTapChooseVideo()
        }
        replyLabel.onTapAttackTakePhoto = {[weak self] in
            guard let self = self else {return}
            didTapChooseTakePhoto()
        }
        replyLabel.onTapReviewImage = {[weak self] in
            guard let self = self else {return}
            self.didTapReviewImage()
        }
        replyLabel.onTapReviewVideo = {[weak self] in
            guard let self = self else {return}
            didTapReviewVideo()
        }
        replyLabel.onSend = {[weak self] in
            guard let self = self else {return}
            self.didTapSend()
        }
    }
    
    // --- LOGIC CHẠM TRẦN TỰ LOAD HISTORY ---
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // 1. Đảm bảo data đủ nhiều mới kích hoạt chạm trần
        guard displayData.count > 29 else { return }
        
        let offsetY = scrollView.contentOffset.y
        
        // 2. ĐIỀU KIỆN VÀNG:
        // - offsetY <= 10: Tọa độ đã chạm sát đỉnh màn hình (cho sai số 10px để nhạy hơn)
        // - scrollView.isDragging: BẮT BUỘC phải là do NGÓN TAY NGƯỜI DÙNG ĐANG VUỐT.
        //   (Nếu do code tự insertRows hoặc tự scrollToBottom, isDragging = false -> Sẽ không bị đá nhau!)
        
        if offsetY <= 2 && !isFetchingHistory && scrollView.isDragging {
            
            isFetchingHistory = true
            trippieLoadingView.isHidden = false
            
            // Giả lập delay chờ mạng
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.commentViewModel.loadHistory()
                self.trippieLoadingView.isHidden = true
            }
        }
    }

    // --- LOGIC THEO DÕI NGƯỜI DÙNG CHẠM TAY ---
        
    // 1. Vừa chạm tay vuốt -> Đánh dấu đang tương tác, hủy bộ đếm
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserInteracting = true
        interactionTimer?.cancel()
    }
    
    // 2. Buông tay ra nhưng màn hình chưa dừng hẳn
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            flushPendingData()
            startInteractionTimer() // Nếu không trượt tiếp (decelerate) thì đếm 10s
        }
    }
    
    // 3. Màn hình trượt xong và dừng hẳn
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        flushPendingData()
        startInteractionTimer() // Bắt đầu đếm 2s
    }
    
    // Hàm khởi động bộ đếm 10 giây
    private func startInteractionTimer() {
        interactionTimer?.cancel()
        
        let task = DispatchWorkItem { [weak self] in
            self?.isUserInteracting = false // Sau 10s, mở khóa cho phép tự động cuộn xuống đáy
        }
        interactionTimer = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: task)
    }
    
    private func flushPendingData() {
        if let pending = self.pendingRawData {
            self.applyDataToTableView(pending)
            self.pendingRawData = nil // Xóa hàng chờ sau khi áp dụng
        }
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async { // Đảm bảo chạy trên main thread sau khi UI update
            let numberOfRows = self.tableView.numberOfRows(inSection: 0) // Giả sử chỉ có 1 section
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
        self.commentViewModel.newMessagesCount.send(0)
    }
    
    private func didTapReviewImage() {
        let fullVC = PhotoFullScreenViewController()
        fullVC.imageUrls = imageViewModel.uploadedUrls
        fullVC.modalPresentationStyle = .overFullScreen
        fullVC.modalTransitionStyle = .crossDissolve
        present(fullVC, animated: true)
    }
    
    private func didTapReviewVideo() {
        let fullVC = VideoSwipeViewController()
        fullVC.videoUrls = [imageViewModel.videoUrl]
        fullVC.modalTransitionStyle = .crossDissolve
        fullVC.modalPresentationStyle = .overFullScreen
        present(fullVC, animated: true)
    }
    
    private func didTapSend() {
        isUserInteracting = false
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
        var config = PHPickerConfiguration()
        config.selectionLimit = 1 // Giới hạn 1 video cho an toàn băng thông
        config.filter = .videos   // Chỉ hiện Video
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func didTapChooseTakePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("⚠️ Thiết bị này không có Camera")
            // Cậu có thể thay bằng một cái Alert báo lỗi cho người dùng ở đây
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.sourceType = .camera
        
        // 2. Cho phép cả Chụp ảnh (image) và Quay video (movie)
        cameraPicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        
        // Cài đặt chất lượng video quay (Nên để .typeHigh hoặc .typeMedium)
        cameraPicker.videoQuality = .typeHigh
        
        cameraPicker.delegate = self
        
        present(cameraPicker, animated: true)
    }
    
    @objc func handleFakeTouch() {
        isUserInteracting.toggle()
        // Đổi màu nền tableView cho dễ phân biệt đang bật hay tắt cờ
        tableView.backgroundColor = isUserInteracting ? .red.withAlphaComponent(0.2) : .clear
    }
    
    
    //MARK: - BINDING
    @objc private func binding() {
        
        commentViewModel.comments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRawData in
                guard let self = self else { return }
                
                if self.tableView.isDragging || self.tableView.isDecelerating {
                    self.pendingRawData = newRawData
                    return
                }
                
                // NẾU MÀN HÌNH ĐỨNG IM: Vẽ luôn!
                self.applyDataToTableView(newRawData)
                
            }
            .store(in: &cancellable)
    }
    
    private func applyDataToTableView(_ newRawData: [Comment]) {
        let newData = self.processCommentsWithSeparators(newRawData)
        let oldDataCount = self.displayData.count
        let newDataCount = newData.count
        
        // TỰ ĐỘNG BẮT MẠCH LOAD HISTORY
        if oldDataCount > 0 && newDataCount > oldDataCount {
            if self.displayData.first?.id != newData.first?.id {
                self.isFetchingHistory = true
            }
        }
        
        self.beginLabel.isHidden = !newData.isEmpty
                        
        // KỊCH BẢN 1: Load lần đầu tiên hoặc chat rỗng
        if oldDataCount == 0 {
            self.displayData = newData
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.adjustContentInsetToBottom()
            self.scrollToBottom()
            return
        }
        
        // KỊCH BẢN 2: Tải lịch sử (Load History) -> Chỉ INSERT VÀO ĐẦU BẢNG
        if self.isFetchingHistory {
            let newItemsCount = newDataCount - oldDataCount
            if newItemsCount > 0 {
                let indexPaths = (0..<newItemsCount).map { IndexPath(row: $0, section: 0) }
                
                // 1. TÌM MỎ NEO: Ghi nhớ chính xác tin nhắn trên cùng người dùng đang nhìn
                var topOffset: CGFloat = 0
                var oldTopRow = 0
                
                if let topVisibleIndexPath = self.tableView.indexPathsForVisibleRows?.first {
                    oldTopRow = topVisibleIndexPath.row
                    let cellRect = self.tableView.rectForRow(at: topVisibleIndexPath)
                    // Lấy độ lệch từ đỉnh màn hình tới mép trên của bong bóng
                    topOffset = self.tableView.contentOffset.y - cellRect.origin.y
                }
                
                self.displayData = newData
                
                // Tắt animation để nhét tin nhắn
                UIView.performWithoutAnimation {
                    self.tableView.insertRows(at: indexPaths, with: .none)
                    self.tableView.layoutIfNeeded()
                    
                    // 2. KHÔI PHỤC VỊ TRÍ: Cuộn tức thời về lại đúng cái tin nhắn mỏ neo đó
                    // (Tin nhắn cũ giờ đã bị đẩy xuống dưới "newItemsCount" dòng)
                    let restoredIndexPath = IndexPath(row: oldTopRow + newItemsCount, section: 0)
                    self.tableView.scrollToRow(at: restoredIndexPath, at: .top, animated: false)
                    
                    // 3. BÙ TRỪ KHOẢNG LỆCH (Lỡ người dùng có miết nhẹ tay trong 0.5s chờ mạng)
                    self.tableView.contentOffset.y += topOffset
                }
            }
            self.isFetchingHistory = false
        }
        // KỊCH BẢN 3: Có tin nhắn mới tới -> DÙNG MỎ NEO ĐẦU (Đóng băng khung hình)
        else if newDataCount > oldDataCount {
            let indexPaths = (oldDataCount..<newDataCount).map { IndexPath(row: $0, section: 0) }
            
            // 1. TÌM MỎ NEO: Giữ chặt tin nhắn đang xem
            
            
            self.displayData = newData
            
            if self.isUserInteracting {
                UIView.performWithoutAnimation {
                    self.tableView.insertRows(at: indexPaths, with: .none)
                }
            } else {
                // ✅ RẢNH TAY HOẶC Ở ĐÁY: Chèn xong thì cuộn trượt xuống mượt mà
                UIView.performWithoutAnimation {
                    self.tableView.insertRows(at: indexPaths, with: .none)
                }
                // Chỉ tính lại Inset khi người dùng KHÔNG chạm tay vào màn hình
                self.adjustContentInsetToBottom()
                let bottomIndexPath = IndexPath(row: newDataCount - 1, section: 0)
                self.tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: true)
            }
        } // KỊCH BẢN 4: Chỉnh sửa tin nhắn (Edit) -> Chỉ RELOAD DÒNG BỊ SỬA
        else if newDataCount == oldDataCount {
            var indexPathsToReload: [IndexPath] = []
            
            for i in 0..<newDataCount {
                let oldItem = self.displayData[i]
                let newItem = newData[i]
                
                // So sánh nội dung cũ và mới xem có bị edit text, ảnh, hay video không
                if oldItem.message != newItem.message ||
                   oldItem.imageUrls != newItem.imageUrls ||
                   oldItem.videoUrl != newItem.videoUrl {
                    indexPathsToReload.append(IndexPath(row: i, section: 0))
                }
            }
            
            self.displayData = newData
            if !indexPathsToReload.isEmpty {
                // Hiệu ứng .automatic sẽ tạo ra transition mờ đè chữ mới lên cực đẹp
                self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
            }
        }
        // KỊCH BẢN 5: Fallback an toàn (Lỡ bị thu hồi/xóa tin nhắn làm giảm count)
        else {
            self.displayData = newData
            self.tableView.reloadData()
        }
    }
}


// MARK: - TABLEVIEW DATASOURCE
extension GroupMessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            
//        // Tránh gọi khi data còn trống
//        guard !displayData.isEmpty, displayData.count > 29 else { return }
//        
//        // Khi người dùng lướt lên tới tin nhắn thứ 2 từ trên đếm xuống (Load đón đầu trước khi đụng trần)
//        if indexPath.row == 0 && !isFetchingHistory {
//            if countToLoadHistory == 0 {
//                countToLoadHistory += 1
//            } else {
//                isFetchingHistory = true
//                trippieLoadingView.isHidden = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    self.commentViewModel.loadHistory()
//                    self.trippieLoadingView.isHidden = true
//                }
//                
//            }
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Kiểm tra index an toàn
        guard indexPath.row < displayData.count else {
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.identifier, for: indexPath) as? MessageTableViewCell else {
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
            let fullVC = VideoSwipeViewController()
            fullVC.videoUrls = [video]
            fullVC.modalTransitionStyle = .crossDissolve
            fullVC.modalPresentationStyle = .overFullScreen
            present(fullVC, animated: true)
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
        let _ = displayData[indexPath.row]
        
    }
    
    func isHideNameandHideAvatarAction(index: Int) -> (Bool, Bool) {
        let currentUserId = displayData[index].userId
        
        // Nếu là dải phân cách (Date/Space) thì ẩn luôn
        if currentUserId.isEmpty { return (true, true) }
        
        // LOGIC ẨN TÊN: Chỉ so sánh với tin nhắn NGAY TRƯỚC nó
        let isHideName: Bool
        if index > 0 {
            isHideName = (displayData[index - 1].userId == currentUserId)
        } else {
            isHideName = false
        }
        
        // LOGIC ẨN AVATAR: Chỉ so sánh với tin nhắn NGAY SAU nó
        let isHideAvatar: Bool
        if index < displayData.count - 1 {
            isHideAvatar = (displayData[index + 1].userId == currentUserId)
        } else {
            isHideAvatar = false
        }
        
        return (isHideName, isHideAvatar)
    }
}


extension GroupMessageViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        let provider = results[0].itemProvider
                
        // ----------------------------------------
        // KỊCH BẢN A: NGƯỜI DÙNG CHỌN VIDEO
        // ----------------------------------------
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                guard let self = self, let url = url, error == nil else { return }
                
                // ⚠️ BẮT BUỘC: Copy file ra thư mục an toàn của App để không bị hệ thống xóa mất
                let tempDir = FileManager.default.temporaryDirectory
                let localUrl = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
                
                do {
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    try FileManager.default.copyItem(at: url, to: localUrl)
                    
                    // Lấy Thumbnail Data
                    guard let thumbnailData = self.generateThumbnail(for: localUrl) else { return }
                    
                    // Switch về Main Thread gọi ViewModel
                    DispatchQueue.main.async {
                        self.imageViewModel.UploadVideo(fileUrl: localUrl, thumbnailData: thumbnailData, folder: "chats")
                    }
                } catch {
                    print("Lỗi xử lý video: \(error.localizedDescription)")
                }
            }
        }
        
        // ------------------------------------
        // KỊCH BẢN B: NGƯỜI DÙNG CHỌN ẢNH
        // ------------------------------------
        else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            Task {
                // 1. Xử lý song song để lấy mảng DATA
                let optimizedDataArray = await withTaskGroup(of: Data?.self) { group -> [Data] in
                    for result in results {
                        group.addTask {
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
                
                // 2. Upload
                self.imageViewModel.uploadImages(optimizedDataArray, folder: "chats")
            }
        }
    }
    
    private func generateThumbnail(for url: URL) -> Data? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        // Cực kỳ quan trọng: Giữ đúng chiều quay gốc của video (cầm dọc/ngang)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            // Lấy frame ở giây thứ 0 (bắt đầu video)
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail.jpegData(compressionQuality: 1.0)
        } catch {
            print("Lỗi tạo thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}


// MARK: - CAMERA DELEGATE
extension GroupMessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let mediaType = info[.mediaType] as? String else { return }
        
        // ----------------------------------------
        // KỊCH BẢN A: NGƯỜI DÙNG VỪA CHỤP ẢNH XONG
        // ----------------------------------------
        if mediaType == UTType.image.identifier {
            if let originalImage = info[.originalImage] as? UIImage {
                if let imageData = originalImage.jpegData(compressionQuality: 1.0) {
                    self.imageViewModel.uploadImages([imageData], folder: "chats")
                }
            }
        }
        
        // ----------------------------------------
        // KỊCH BẢN B: NGƯỜI DÙNG VỪA QUAY VIDEO XONG
        // ----------------------------------------
        else if mediaType == UTType.movie.identifier {
            if let videoUrl = info[.mediaURL] as? URL {
                // Lấy Thumbnail Data bằng cái hàm tớ đưa cậu lúc nãy
                if let thumbnailData = self.generateThumbnail(for: videoUrl) {
                    // Chuyển về Main Thread an toàn rồi Upload
                    DispatchQueue.main.async {
                        self.imageViewModel.UploadVideo(fileUrl: videoUrl, thumbnailData: thumbnailData, folder: "chats")
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
