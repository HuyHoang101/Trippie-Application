//
//  LoginViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class LoginViewController: AuthBaseViewController {
    
    private let viewModel = LoginViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    //MARK: - UI COMPONENT
    
    private let icon: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(systemName: "bus.doubledecker")
        img.tintColor = .white
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 32).isActive = true
        img.heightAnchor.constraint(equalTo: img.widthAnchor).isActive = true
        return img
    }()
    
    private let applabel = UILabel.customLabel(text: "Trippie", font: AppTheme.Font.mainBold(size: 24), textColor: .white, textAligment: .center)
    
    private let applabel2 = UILabel.customLabel(text: "Travel together", font: AppTheme.Font.mainBold(size: 18), textColor: .white, textAligment: .center)
    
    private let vstack = UIStackView.customStack(axis: .vertical, alignment: .leading, distribution: .fill, stackSpacing: 2)
    
    private let hstack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 10)
    
    private let loginLabel = UILabel.customLabel(text: "Login", font: AppTheme.Font.mainBlack(size: 30), textColor: .label, textAligment: .center)
    
    private let registerLabel = UILabel.customLabel(text: "Don't have an account?", font: AppTheme.Font.mainMedium(size: 14), textColor: .label)
    
    private let registerlink = UIButton.customButton(text: "Sign Up", font: AppTheme.Font.mainMedium(size: 14), backgroundColor: .white, textColor: .systemBlue, isPadding: false, isCircle: false)
    
    private let hstack2 = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .equalCentering, stackSpacing: 4)
    
    private let emailInput = UIStackView.createInputGroup(labelName: "Email", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter email...", inputHeight: 48)
    
    private let passwordInput = UIStackView.createInputGroup(labelName: "Password", labelFont: AppTheme.Font.mainRegular(size: 11), labelColor: UIColor(named: "TextGray") ?? .black, placeholder: "Enter password...", style: InputStyle.password, inputHeight: 48)
    
    private let loginButton = UIButton.customButton(text: "Log In", backgroundColor: UIColor(named: "Button") ?? .systemPurple)
    
    private let hstack3 = UIStackView.customStack(xPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 5)
    
    private let leftline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray2
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }()
    
    private let rightline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray2
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }()
    
    private let orLabel = UILabel.customLabel(text: "Or", font: AppTheme.Font.mainRegular(size: 12), textColor: .gray)
    
    private let loginWithGoogle = UIButton.customButton(text: "Continue with Google", font: AppTheme.Font.mainBold(size: 14), backgroundColor: .white, textColor: .label, isCircle: false, imageName: "Google", isSystemImage: false, isBorder: true, borderColor: .tertiaryLabel)
    
    private let loginWithFaceBook = UIButton.customButton(text: "Continue with Facebook", font: AppTheme.Font.mainBold(size: 14), backgroundColor: .white, textColor: .label, isCircle: false, imageName: "Facebook", isSystemImage: false, isBorder: true, borderColor: .tertiaryLabel)
    
    private let vstack2 = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 15)
    
    private let mainstack = UIStackView.customStack(xPadding: 25, yPadding: 25, background: .white, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 30, cornerRadius: 12)
    
    
    //MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindLoading(to: viewModel.loading)
        setupUI()
        setupAction()
        binding()
    }
    
    //MARK: - SETUP UI
    func setupUI() {
        let leftSpacer = UIView()
        let rightSpacer = UIView()
        
        setupBackground()
        view.addSubview(hstack)
        
        hstack.addArrangedSubview(icon)
        hstack.addArrangedSubview(vstack)
        vstack.addArrangedSubview(applabel)
        vstack.addArrangedSubview(applabel2)
        
        view.addSubview(mainstack)
        
        mainstack.addArrangedSubview(loginLabel)
        mainstack.addArrangedSubview(hstack2)
        
        hstack2.addArrangedSubview(leftSpacer)
        hstack2.addArrangedSubview(registerLabel)
        hstack2.addArrangedSubview(registerlink)
        hstack2.addArrangedSubview(rightSpacer)
        
        mainstack.addArrangedSubview(emailInput)
        mainstack.addArrangedSubview(passwordInput)
        mainstack.addArrangedSubview(loginButton)
        mainstack.addArrangedSubview(hstack3)
        
        hstack3.addArrangedSubview(leftline)
        hstack3.addArrangedSubview(orLabel)
        hstack3.addArrangedSubview(rightline)
        
        mainstack.addArrangedSubview(vstack2)
        
        vstack2.addArrangedSubview(loginWithGoogle)
        vstack2.addArrangedSubview(loginWithFaceBook)
        
        NSLayoutConstraint.activate([
            hstack.bottomAnchor.constraint(equalTo: mainstack.topAnchor, constant: -12),
            hstack.centerXAnchor.constraint(equalTo: mainstack.centerXAnchor),
            
            mainstack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainstack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainstack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor),
            leftline.widthAnchor.constraint(equalTo: rightline.widthAnchor),
            
            loginWithGoogle.heightAnchor.constraint(equalToConstant: 50),
            loginWithFaceBook.heightAnchor.constraint(equalToConstant: 50),
            
        ])
    }
    
    //MARK: - Action
    
    private func setupAction() {
        registerlink.addTarget(self, action: #selector(pressSignup), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
    }
    
    @objc private func pressSignup() {
        let registervc = RegisterViewController()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.pushViewController(registervc, animated: true)
    }
    
    @objc private func didTapLogin() {
        viewModel.login()
    }
    
    //MARK: - BINDING
    private func binding() {
        // Lắng nghe lỗi Email
        viewModel.$emailError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.emailInput.showError(msg)
            }
            .store(in: &cancellable)
            
        // Lắng nghe lỗi Password
        viewModel.$passwordError
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.passwordInput.showError(msg)
            }
            .store(in: &cancellable)
        
        viewModel.loginSuccess
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                if let window = self.view.window {
                    let coordinator = AppCoordinator(window: window)
                    coordinator.showMainFlow()
                }
                
                // Bắn thông báo (Delay 0.5s để đợi Main hiện lên đã rồi mới bắn)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: .showGlobalToast,
                        object: nil,
                        userInfo: [
                            "message": "Login Successfully!",
                            "isSuccess": true
                        ]
                    )
                }
            }
            .store(in: &cancellable)
        
        viewModel.generalErrorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] msg in
                self?.showToast(message: "Register failed: \(msg)", isSuccess: false)
            }
            .store(in: &cancellable)
        
        // Lắng nghe gõ phím để update ngược lại ViewModel
        emailInput.listenToChanges { [weak self] text in self?.viewModel.email = text }
        passwordInput.listenToChanges { [weak self] text in self?.viewModel.password = text }
    }
}
