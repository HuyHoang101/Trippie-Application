//
//  HandSaveProfile.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit
import Combine
import CountryPickerView
import PhotosUI

class HandSaveProfile: FadeBaseViewController {
    // Hủy đăng ký khi thoát màn hình (Clean memory)
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    
    // MARK: - Dependency
    var viewModel: UserViewModel!
    private var cancellabel = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    private lazy var nameField = UIStackView.createInputGroup(labelName: "Name:", placeholder: "Nguyen Van A...", inputHeight: 45, delegate: self)
    private lazy var locationField = UIStackView.createInputGroup(labelName: "Address:", placeholder: "Location...", inputHeight: 45, delegate: self)
    private lazy var aboutMeField = UIStackView.createInputGroup(labelName: "About me:", placeholder: "Description...", isTextView: true, inputHeight: 45, delegate: self)
    private lazy var emailField = UIStackView.createInputGroup(labelName: "Email:", placeholder: "Rule for all member in trip...", delegate: self)
    private lazy var phoneField = UIStackView.createInputGroup(labelName: "Phone:", placeholder: "", keyboardType: .phonePad, delegate: self)
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save Profile", for: .normal)
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Xoá dữ liệu edit để lần sau mở lên ko bị dính data cũ
        viewModel.editingProfile.send(nil)
    }
    
    // MARK: - SETUP UI
    
    private func setupUI() {
        setupBackground()
        
        // 1. Thêm ScrollView vào View chính trước
        view.addSubview(scrollView)
        
        // 2. Thêm StackView và Button VÀO TRONG ScrollView
        scrollView.addSubview(stackView)
        scrollView.addSubview(saveButton)
        
        let fields = [nameField, emailField, phoneField, locationField, aboutMeField]
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
        
        // Validate Address
        if (locationField.inputValue ?? "").isEmpty {
            locationField.showError("Location must not be empty!")
            isError = true
        }
        
        // Validate aboutme
        if (aboutMeField.inputValue ?? "").isEmpty {
            aboutMeField.showError("About me must not empty")
            isError = true
        }
        
        // Validate Name
        if (nameField.inputValue ?? "").isEmpty {
            nameField.showError("Name must not be empty!")
            isError = true
        }
        
        // Validate Phone
        if (phoneField.inputValue ?? "").isEmpty {
            phoneField.showError("Phone must not be empty!")
            isError = true
        }
        
        // Validate Email
        if (emailField.inputValue ?? "").isEmpty {
            emailField.showError("Email must not be empty!")
            isError = true
        } else {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if !emailPred.evaluate(with: emailField.inputValue) {
                emailField.showError("The email address is not in the correct format (e.g., abc@mail.com).")
                isError = true
            }
        }
        
        // --- CHECK TỔNG, và ngày ---
        if isError {
            print("❌ Form có lỗi, không save được.")
            return
        }
        
        
        let finalName = nameField.inputValue!
        let finalAboutMe = aboutMeField.inputValue!
        let finalLoc = locationField.inputValue!
        let finalEmail = emailField.inputValue!
        let finalPhone = phoneField.inputValue!
        
        var user: User = self.viewModel.editingProfile.value!
        user.name = finalName
        user.aboutMe = finalAboutMe
        user.address = finalLoc
        user.email = finalEmail
        user.phone = finalPhone
        
        viewModel.editProfile(user: user)
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Logic Helper
    private func checkEditMode() {
        // Kiểm tra xem có data edit không
        guard let user = viewModel.editingProfile.value else {
            return
        }
        title = "Editting Trip"
        emailField.inputValue = user.email
        phoneField.inputValue = user.phone
        nameField.inputValue = user.name
        aboutMeField.inputValue = user.aboutMe
        locationField.inputValue = user.address
        
        saveButton.setTitle("Update Profile", for: .normal)
    }
    
    
    //MARK: - BINDING
    private func binding() {
        nameField.listenToChanges { [weak self] _ in
            self?.nameField.showError(nil)
        }
        
        locationField.listenToChanges { [weak self] _ in
            self?.locationField.showError(nil)
        }
        
        aboutMeField.listenToChanges { [weak self] _ in
            self?.aboutMeField.showError(nil)
        }
        
        emailField.listenToChanges { [weak self] _ in
            self?.emailField.showError(nil)
        }
        
        phoneField.listenToChanges { [weak self] _ in
            self?.phoneField.showError(nil)
        }        
    }
   
}
