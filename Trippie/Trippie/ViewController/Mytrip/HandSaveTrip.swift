//
//  HandSaveTrip.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/2/26.
//

import UIKit
import Combine
import CountryPickerView
import PhotosUI

class HandSaveTrip: FadeBaseViewController {
    // MARK: - Dependency
    var viewModel: TripViewModel!
    private let imagesViewModel = ImageViewModel.shared
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
    
    private lazy var titleField = UIStackView.createInputGroup(labelName: "Trip Title:", placeholder: "Trip title...", inputHeight: 45, delegate: self)
    private lazy var locationField = UIStackView.createInputGroup(labelName: "Location:", placeholder: "Location...", inputHeight: 45, delegate: self)
    private lazy var countryField = UIStackView.createInputGroup(
        labelName: "Country:",
        placeholder: "Select your country",
        style: .country,
        inputHeight: 45,
        onCountryTap: { [weak self] in
            self?.showCountryPicker()
        }
    )
    private lazy var maxMemberField = UIStackView.createInputGroup(labelName: "Max member:", placeholder: "Max member...", keyboardType: .numberPad, inputHeight: 45, delegate: self)
    
    private lazy var tripTypeGroup = UIStackView.createChoiceGroup(
        labelName: "Trip type:",
        options: ["buddy", "local_host", "seeking_local"]
    )
    private var selectedType: String?
    
    private lazy var startDateField = UIStackView.createInputGroup(labelName: "Start date:", placeholder: "01/01/1999", style: InputStyle.date, inputHeight: 45, delegate: self)
    private lazy var dayIndexField = UIStackView.createInputGroup(labelName: "Total days:", placeholder: "Total days of your trip...", keyboardType: .numberPad, inputHeight: 45, delegate: self)
    private lazy var tripDescriptionField = UIStackView.createInputGroup(labelName: "Description:", placeholder: "Description...", isTextView: true, inputHeight: 45, delegate: self)
    private lazy var tripRuleField = UIStackView.createInputGroup(labelName: "Trip Rule:", placeholder: "Rule for all member in trip...", isTextView: true, inputHeight: 45, delegate: self)
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save Trip", for: .normal)
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
        if let countryTF = countryField.arrangedSubviews[1] as? UITextField {
            countryTF.tintColor = .clear
            countryTF.inputView = UIView() 
        }
    }
    
    // Hủy đăng ký khi thoát màn hình (Clean memory)
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Xoá dữ liệu edit để lần sau mở lên ko bị dính data cũ
        viewModel.editingTrip.send(nil)
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
        
        let fields = [coverImageSelected, titleField, locationField, countryField, maxMemberField, tripTypeGroup.stack, startDateField, dayIndexField, tripDescriptionField, tripRuleField]
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
        tripTypeGroup.buttons.forEach { button in
            button.addTarget(self, action: #selector(handleSingleChoice(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func handleSave() {
        var isError = false
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")

        guard let startDate: Date = formatter.date(from: startDateField.inputValue ?? "") else {
            startDateField.showError("False date formatter")
            isError = true
            return
        }
        
        // 1. Validate Start Date
        // Kiểm tra xem có parse được ngày không
        guard let startDateStr = startDateField.inputValue,
              let startDate = formatter.date(from: startDateStr) else {
            startDateField.showError("Invalid date format (dd/MM/yyyy)")
            isError = true
            return // Riêng Date nếu nil thì return luôn để tránh crash logic sau, hoặc dùng if để đi tiếp
        }
        
        // 2. Validate Max Member
        let maxMemStr = maxMemberField.inputValue ?? ""
        if maxMemStr.isEmpty {
            maxMemberField.showError("Max member must not be empty!")
            isError = true
        } else if let maxMem = Int(maxMemStr), maxMem <= 0 {
            maxMemberField.showError("Max member must be > 0!")
            isError = true
        } else if Int(maxMemStr) == nil {
            maxMemberField.showError("Max member must be a number!")
            isError = true
        }
        
        // 3. Validate Day Index (Total Days)
        let dayIndexStr = dayIndexField.inputValue ?? ""
        if dayIndexStr.isEmpty {
            dayIndexField.showError("Total days must not be empty!") // Sửa: startDateField -> dayIndexField
            isError = true
        } else if Int(dayIndexStr) == nil {
            dayIndexField.showError("Total days must be a number!")
            isError = true
        }
        
        // 4. Validate Country
        if (countryField.inputValue ?? "").isEmpty {
            countryField.showError("Country must not be empty!")
            isError = true
        }
        
        // 5. Validate Location
        if (locationField.inputValue ?? "").isEmpty {
            locationField.showError("Location must not be empty!")
            isError = true
        }
        
        // 6. Validate Description
        if (tripDescriptionField.inputValue ?? "").isEmpty {
            tripDescriptionField.showError("Description must not be empty!")
            isError = true
        }
        
        // 7. Validate Title
        if (titleField.inputValue ?? "").isEmpty {
            titleField.showError("Title must not be empty!")
            isError = true
        }
        
        // --- CHECK TỔNG ---
        if isError {
            print("❌ Form có lỗi, không save được.")
            return
        }
        
        let finalMaxMember = Int(maxMemberField.inputValue!)!
        let finalDayIndex = Int(dayIndexField.inputValue!)!
        let finalTitle = titleField.inputValue!
        let finalDesc = tripDescriptionField.inputValue!
        let finalLoc = locationField.inputValue!
        let finalCountry = countryField.inputValue!
        
        guard let ownerId = AuthService.shared.currentUserId else {
            viewModel.errorMessage.send("Authorized Error, login again!")
            return
        }
        guard let ownerName = AuthService.shared.currentUserId else {
            viewModel.errorMessage.send("Authorized Error, login again!")
            return
        }
        var trip: Trip = Trip(
            ownerId: ownerId,
            ownerName: ownerName,
            coverImage: imagesViewModel.uploadedUrls,
            title: finalTitle,
            description: finalDesc,
            tripRule: tripRuleField.inputValue,
            location: finalLoc,
            country: finalCountry,
            tripType: TripType(rawValue: selectedType!) ?? .buddy,
            status: TripStatus.recruiting,
            members: [],
            pendingRequests: [],
            maxMember: finalMaxMember,
            currentMember: 0,
            startTime: startDate,
            dayIndex: finalDayIndex,
        )
        
        if let t = viewModel.editingTrip.value {
            trip.id = t.trip.id
            trip.currentMember = t.trip.currentMember
            trip.status = t.trip.status
            trip.members = t.trip.members
            trip.pendingRequests = t.trip.pendingRequests
            viewModel.handleSave(trip: trip)
            self.navigationController?.popViewController(animated: true)
        } else {
            viewModel.handleSave(trip: trip)
            self.navigationController?.popViewController(animated: true)
            
        }
    }
    
    @objc private func handleSingleChoice(_ sender: UIButton) {
        // 1. Reset toàn bộ các nút về trạng thái chưa chọn
        tripTypeGroup.buttons.forEach { button in
            updateButtonStyle(button, isSelected: false)
        }
        
        // 2. Kích hoạt nút vừa được bấm
        updateButtonStyle(sender, isSelected: true)
        
        // 3. Lưu giá trị đã chọn vào biến
        if let attributedTitle = sender.configuration?.attributedTitle {
            // Chuyển đổi CharacterView thành String chuẩn
            let titleString = String(attributedTitle.characters)
            
            // Xử lý chuỗi để lưu vào selectedType
            self.selectedType = titleString.lowercased().replacingOccurrences(of: " ", with: "_")
        }

    }
    // MARK: - Logic Helper
    private func checkEditMode() {
        // Kiểm tra xem có data edit không
        guard let trip = viewModel.editingTrip.value?.trip else {
            title = "Create New Trip"
            saveButton.setTitle("Create", for: .normal)
            return
        }
        title = "Editting Trip"
        imagesViewModel.uploadedUrls = trip.coverImage
        titleField.inputValue = trip.title
        locationField.inputValue = trip.location
        countryField.inputValue = trip.country
        maxMemberField.inputValue = "\(trip.maxMember)"
        dayIndexField.inputValue = "\(trip.dayIndex)"
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: trip.startTime)
        startDateField.inputValue = "\(dateString)"
        tripDescriptionField.inputValue = trip.description
        tripRuleField.inputValue = trip.tripRule
        saveButton.setTitle("Update", for: .normal)
        
        // 1. Lưu giá trị hiện tại vào biến selectedType
        self.selectedType = trip.tripType.rawValue
        
        // 2. Duyệt qua danh sách các nút để tìm nút khớp với rawValue
        tripTypeGroup.buttons.forEach { button in
            if let attributedTitle = button.configuration?.attributedTitle {
                let titleString = String(attributedTitle.characters)
                
                // Chuyển tiêu đề nút về dạng rawValue (ví dụ: "Local host" -> "local_host")
                let formattedTitle = titleString.lowercased().replacingOccurrences(of: " ", with: "_")
                
                // Nếu khớp thì tô màu "Selected", không khớp thì để màu "Gray"
                let isMatch = (formattedTitle == trip.tripType.rawValue)
                updateButtonStyle(button, isSelected: isMatch)
            }
        }
    }
    
    private func updateButtonStyle(_ button: UIButton, isSelected: Bool) {
        var config = button.configuration
        
        if isSelected {
            config?.background.backgroundColor = .button
            config?.attributedTitle?.foregroundColor = .white
        } else {
            config?.background.backgroundColor = .systemGray6 // Màu xám (chưa chọn)
            config?.attributedTitle?.foregroundColor = .darkGray
        }
        
        button.configuration = config
    }
    
    private func showCountryPicker() {
        // 2. Gán delegate để nhận kết quả
        countryPickerView.delegate = self
        
        // 3. Hiển thị danh sách quốc gia (Dạng chuẩn UIKit)
        countryPickerView.showCountriesList(from: self)
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
        
        tripDescriptionField.listenToChanges { [weak self] _ in
            self?.tripDescriptionField.showError(nil)
        }
        
        locationField.listenToChanges { [weak self] _ in
            self?.locationField.showError(nil)
        }
        
        countryField.listenToChanges { [weak self] _ in
            self?.countryField.showError(nil)
        }
        
        dayIndexField.listenToChanges { [weak self] _ in
            self?.dayIndexField.showError(nil)
        }
        
        startDateField.listenToChanges { [weak self] _ in
            self?.startDateField.showError(nil)
        }
        
        maxMemberField.listenToChanges { [weak self] _ in
            self?.maxMemberField.showError(nil)
        }
        
    }
   
}

extension HandSaveTrip: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        // Đúng ý cậu: Chỉ lưu tên Country
        self.countryField.inputValue = country.name
    }
}

extension HandSaveTrip: StackImagePickerDelegate {
    func didTapSelectImage() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func didTapDeleteAll() {
        imagesViewModel.deleteAllImages()
    }
}

extension HandSaveTrip: PHPickerViewControllerDelegate {
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
            //print("DEBUG: Đã load xong \(selectedImages.count) ảnh. Bắt đầu upload...")
            
            // Lúc này selectedImages mới có dữ liệu
            self?.imagesViewModel.uploadImages(selectedImages)
        }
    }
}
