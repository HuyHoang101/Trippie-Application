//
//  RegisterViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/26/26.
//

import UIKit
import Combine

class RegisterViewController: AuthBaseViewController {
    
    private let viewModel = RegisterViewModel()
    
    private var cancellable = Set<AnyCancellable>()
    
    // MARK: - UI COMPONENT
    private let backbutton = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: .white, tintColor: .black, padding: 0)
    
    private let registerLabel = UILabel.customLabel(text: "Register", font: AppTheme.Font.mainBlack(size: 30), textColor: .label, textAligment: .left)
    
    private let loginLabel = UILabel.customLabel(text: "Already have an account?", font: AppTheme.Font.mainMedium(size: 14), textColor: .label)
    
    private let loginLink = UIButton.customButton(text: "Log in", font: AppTheme.Font.mainMedium(size: 14), backgroundColor: .white, textColor: .systemBlue, isPadding: false, isCircle: false)
    
    private let hstack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .equalCentering, stackSpacing: 4)
    
    private let fullNameInput = UIStackView.createInputGroup(labelName: "Full Name", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter full name...", inputHeight: 48)
    
    private let emailInput = UIStackView.createInputGroup(labelName: "Email", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter email...", inputHeight: 48)
    
    private let phoneInput = UIStackView.createInputGroup(labelName: "Phone Number", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "0123 456 789", style: InputStyle.phoneNumber, inputHeight: 48)
    
    private let passwordInput = UIStackView.createInputGroup(labelName: "Set Password", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter password...", style: InputStyle.password, inputHeight: 48)
    
    private let confirmPassInput = UIStackView.createInputGroup(labelName: "Confirm Password", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter password...", style: InputStyle.password, inputHeight: 48)
    
    private let registerButton = UIButton.customButton(text: "Register", backgroundColor: UIColor(named: "Button") ?? .systemPurple)
    
    private let mainstack = UIStackView.customStack(xPadding: 25, yPadding: 25, background: .white, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 20, cornerRadius: 12)
    
    private let scrollView = UIScrollView()
    
    // MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        bindLoading(to: viewModel.loading)
        setupUI()
        setupAction()
        binding()
    }
    
    // MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(mainstack)
        
        let v = UIStackView.customStack(axis: .vertical, alignment: .leading, distribution: .fill)
        mainstack.addArrangedSubview(v)
        v.addArrangedSubview(backbutton)
        
        mainstack.addArrangedSubview(registerLabel)
        mainstack.addArrangedSubview(hstack)
        
        let rightSpacer = UIView()
        hstack.addArrangedSubview(loginLabel)
        hstack.addArrangedSubview(loginLink)
        hstack.addArrangedSubview(rightSpacer)
        
        mainstack.addArrangedSubview(fullNameInput)
        mainstack.addArrangedSubview(emailInput)
        mainstack.addArrangedSubview(phoneInput)
        mainstack.addArrangedSubview(passwordInput)
        mainstack.addArrangedSubview(confirmPassInput)
        mainstack.addArrangedSubview(registerButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            mainstack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            mainstack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            mainstack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            mainstack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            mainstack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }
    
    // MARK: - SETUP ACTION
    private func setupAction() {
        backbutton.addTarget(self, action: #selector(returnLoginScreen), for: .touchUpInside)
        loginLink.addTarget(self, action: #selector(returnLoginScreen), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(register), for: .touchUpInside)
    }
    
    @objc private func returnLoginScreen() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func register() {
        viewModel.phone = phoneInput.inputValue
        viewModel.register()
    }
    
    // MARK: - Binding
    private func binding() {
        viewModel.$nameError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                self?.fullNameInput.showError(errorMessage)
            }
            .store(in: &cancellable)
        viewModel.$emailError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                self?.emailInput.showError(errorMessage)
            }
            .store(in: &cancellable)
        viewModel.$passwordError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                self?.passwordInput.showError(errorMessage)
            }
            .store(in: &cancellable)
        viewModel.$confirmError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] errorMessage in
                self?.confirmPassInput.showError(errorMessage)
            }
            .store(in: &cancellable)
        viewModel.registerSuccess
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                if let window = self?.view.window {
                    let coordinator = AppCoordinator(window: window)
                    coordinator.showMainFlow()
                }
                // Bắn thông báo (Delay 0.5s để đợi Main hiện lên đã rồi mới bắn)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Register Successfully!",
                            "isSuccess": true
                        ]
                    )
                }
            }
            .store(in: &cancellable)
        viewModel.generalErrorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.showToast(message: "Register failed: \(msg)", isSuccess: true)
            }
            .store(in: &cancellable)
        
        // lắng nghe ngược lại
        fullNameInput.listenToChanges { [weak self] text in
            self?.viewModel.name = text
        }
        emailInput.listenToChanges { [weak self] text in
            self?.viewModel.email = text
        }
        passwordInput.listenToChanges { [weak self] text in
            self?.viewModel.password = text
        }
        confirmPassInput.listenToChanges { [weak self] text in
            self?.viewModel.confirmPassword = text
        }
    }
}
