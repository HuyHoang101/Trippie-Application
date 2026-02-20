//
//  HandsaveTask.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//

import UIKit
import Combine
import CountryPickerView
import PhotosUI

class HandsaveTask: FadeBaseViewController {
    // MARK: - Dependency
    var viewModel: TaskViewModel!
    var id: String!
    var userRole: UserRole!
    private let imagesViewModel = ImageViewModel()
    private var cancellabel = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    private lazy var coverImageSelected = StackImagePickerView()
    
    private lazy var titleField = UIStackView.createInputGroup(labelName: "Task Title:", placeholder: "Task title...", inputHeight: 45, delegate: self)
    private lazy var dayIndexField = UIStackView.createInputGroup(labelName: "Day of the trip:", placeholder: "1, 2, 3, ...", keyboardType: .numberPad, inputHeight: 45, delegate: self)
    private lazy var timeLineField = UIStackView.createInputGroup(labelName: "Time at:", placeholder: "7:00", style: .time, inputHeight: 45, delegate: self)
    private lazy var taskDescriptionField = UIStackView.createInputGroup(labelName: "Description:", placeholder: "Description...", isTextView: true, inputHeight: 45, delegate: self)
    private lazy var startDateField = UIStackView.createInputGroup(labelName: "Date:", placeholder: "01/01/1999", style: .date, inputHeight: 45, delegate: self)
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save Task", for: .normal)
        btn.backgroundColor = .button
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 15
        sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    private let countryPickerView = CountryPickerView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        binding()
        checkEditMode()
        setupNavBar()
        bindLoading(to: viewModel.loading)
        bindLoading(to: imagesViewModel.loading)
    }
    
    // Hủy đăng ký khi thoát màn hình (Clean memory)
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Xoá dữ liệu edit để lần sau mở lên ko bị dính data cũ
        viewModel.editingTask.send(nil)
        if !imagesViewModel.uploadedUrls.isEmpty {
            imagesViewModel.deleteAllImages()
        }
    }
    
    // MARK: - SETUP UI
    
    private func setupUI() {
        setupBackground()
        coverImageSelected.delegate = self
        
        // 1. Thêm ScrollView vào View chính trước
        view.addSubview(scrollView)
        
        // 2. Thêm StackView và Button VÀO TRONG ScrollView
        scrollView.addSubview(stackView)
        scrollView.addSubview(saveButton)
        
        let fields = [coverImageSelected, titleField, startDateField, dayIndexField, timeLineField, taskDescriptionField]
        fields.forEach { stackView.addArrangedSubview($0) }
        
        NSLayoutConstraint.activate([
            // A. Ghim ScrollView full màn hình
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // B. Ghim StackView vào CONTENT của ScrollView
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            
            // C. Khóa chiều rộng StackView bằng Frame của ScrollView (trừ padding 40) để tránh scroll ngang
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            
            // D. Ghim SaveButton xuống dưới StackView
            saveButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -40),
            saveButton.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavBar() {
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = leftItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - SETUP ACTION
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    @objc private func handleSave() {
        var isError = false
        
        // 3. Validate Day Index
        let dayIndexStr = dayIndexField.inputValue ?? ""
        if dayIndexStr.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dayIndexField.showError("Day index must not be empty!")
            }
            isError = true
        } else if Int(dayIndexStr) == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dayIndexField.showError("Day index must be a number!")
            }
            isError = true
        } else if Int(dayIndexStr)! < 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dayIndexField.showError("Day index must be greater than or equal 0!")
            }
            isError = true
        }
        
        // 6. Validate Description
        if (taskDescriptionField.inputValue ?? "").isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.taskDescriptionField.showError("Description must not be empty!")
            }
            isError = true
        }
        
        // 7. Validate Title
        if (titleField.inputValue ?? "").isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.titleField.showError("Title must not be empty!")
            }
            isError = true
        }
        
        // 7. Validate Time
        if (timeLineField.inputValue ?? "").isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.timeLineField.showError("Time must not be empty!")
            }
            isError = true
        }
        
        // --- CHECK TỔNG ---
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        
        guard let startDateStr = startDateField.inputValue,
              let startDate = formatter.date(from: startDateStr) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startDateField.showError("Invalid date format (dd/MM/yyyy)")
            }
            isError = true
            return
        }
        
        if isError {
            return
        }

        let finalDayIndex = Int(dayIndexField.inputValue!)!
        let finalTitle = titleField.inputValue!
        let finalDesc = taskDescriptionField.inputValue!
        let finalTime = timeLineField.inputValue!
        
        
        guard let ownerId = AuthService.shared.currentUserId else {
            viewModel.errorMessage.send("Authorized Error, login again!")
            return
        }
        guard let ownerName = AuthService.shared.currentUserName else {
            viewModel.errorMessage.send("Authorized Error, login again!")
            return
        }
        
        guard let img = imagesViewModel.uploadedUrls.first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: .showGlobalToast,
                    object: nil,
                    userInfo: [
                        "message": "Save failed: task need a cover image!",
                        "isSuccess": false
                    ]
                )
            }
            return
        }
        
        var task: TaskOfTrip = TaskOfTrip(
            coverImage: img,
            title: finalTitle,
            description: finalDesc,
            status: .upcoming,
            tripId: self.id,
            creatorId: ownerId,
            userName: ownerName,
            userAvatar: AuthService.shared.currentUserAvatar ?? "",
            userRole: self.userRole,
            date: startDate,
            dayIndex: finalDayIndex,
            time: finalTime)
        
        if let t = viewModel.editingTask.value {
            task.id = t.id
            task.status = t.status
            task.creatorId = t.creatorId
            task.userName = t.userName
            task.userAvatar = t.userAvatar
            task.userRole = t.userRole
        }
        Task {
            let (isSuccess, message) = await viewModel.handSaveTask(task: task, name: ownerName)
            
            if isSuccess {
                imagesViewModel.uploadedUrls = []
                self.navigationController?.popViewController(animated: true)
            } else {
                if message.contains("edited") {
                    let alert = await confirmAlert(type: .cancelTaskEdit, title: "")
                    if alert {
                        viewModel.editingTask.send(nil)
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    let alert = await confirmAlert(type: .cancelTaskDelete, title: "")
                    if alert {
                        viewModel.editingTask.send(nil)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Logic Helper
    private func checkEditMode() {
        // Kiểm tra xem có data edit không
        guard let task = viewModel.editingTask.value else {
            title = "Create New Task"
            saveButton.configuration?.title = "Create task"
            return
        }
        title = "Editting Task"
        titleField.inputValue = task.title
        taskDescriptionField.inputValue = task.description
        dayIndexField.inputValue = "\(task.dayIndex)"
        timeLineField.inputValue = task.time
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: task.date!)
        startDateField.inputValue = "\(dateString)"
        coverImageSelected.renderImages([task.coverImage])
        imagesViewModel.uploadedUrls = [task.coverImage]
        saveButton.setTitle("Update", for: .normal)
        
    }

    
    //MARK: - BINDING
    private func binding() {
        imagesViewModel.$uploadedUrls
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] imgs in
                self?.coverImageSelected.renderImages(imgs)
            }
            .store(in: &cancellabel)
        
        titleField.listenToChanges { [weak self] _ in
            self?.titleField.showError(nil)
        }
        
        taskDescriptionField.listenToChanges { [weak self] _ in
            self?.taskDescriptionField.showError(nil)
        }
        
        dayIndexField.listenToChanges { [weak self] _ in
            self?.dayIndexField.showError(nil)
        }
        
        timeLineField.listenToChanges { [weak self] _ in
            self?.timeLineField.showError(nil)
        }
        
        startDateField.listenToChanges { [weak self] _ in
            self?.startDateField.showError(nil)
        }
    }
   
}

extension HandsaveTask: StackImagePickerDelegate {
    func didTapSelectImage() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func didTapDeleteAll() {
        imagesViewModel.deleteAllImages()
    }
}

extension HandsaveTask: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        Task {
            // Sử dụng TaskGroup để xử lý song song (Nhanh hơn Loop thường)
            let processedImages = await withTaskGroup(of: Data?.self) { group -> [Data] in
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
            
            // Upload mảng ảnh đã được resize
            self.imagesViewModel.uploadImages(processedImages, folder: "tasks")
        }
    }
}
