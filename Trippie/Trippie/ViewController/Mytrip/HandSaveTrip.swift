//
//  HandSaveTrip.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/2/26.
//

import UIKit
import Combine
import CountryPickerView

class HandSaveTrip: UIViewController {
    // MARK: - Dependency
    var viewModel: TripViewModel!
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
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
        checkEditMode()
        setupNavBar()
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
        // 1. Thêm ScrollView vào View chính trước
        view.addSubview(scrollView)
        
        // 2. Thêm StackView và Button VÀO TRONG ScrollView
        scrollView.addSubview(stackView)
        scrollView.addSubview(saveButton)
        
        let fields = [titleField, locationField, countryField, maxMemberField, tripTypeGroup.stack, startDateField, dayIndexField, tripDescriptionField, tripRuleField]
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
        titleField.inputValue = trip.title
        locationField.inputValue = trip.location
        countryField.inputValue = trip.country
        maxMemberField.inputValue = "\(trip.maxMember)"
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
            config?.background.backgroundColor = .button // Màu xanh (đã chọn)
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
}

extension HandSaveTrip: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        // Đúng ý cậu: Chỉ lưu tên Country
        self.countryField.inputValue = country.name
    }
}
