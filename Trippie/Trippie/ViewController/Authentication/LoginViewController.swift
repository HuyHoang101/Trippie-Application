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
    
    //MARK: - UI COMPONENT
    
    private let icon: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(systemName: "bus.doubledecker")
        img.backgroundColor = .white
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 20).isActive = true
        img.heightAnchor.constraint(equalTo: img.widthAnchor).isActive = true
        return img
    }()
    
    private let applabel = UILabel.customLabel(text: "Trippie", font: AppTheme.Font.mainBold(size: 26), textColor: .white, textAligment: .center)
    
    private let applabel2 = UILabel.customLabel(text: "Travel together", font: AppTheme.Font.mainBold(size: 22), textColor: .white, textAligment: .center)
    
    private let vstack = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 4)
    
    private let hstack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 5)
    
    private let loginLabel = UILabel.customLabel(text: "Login", font: AppTheme.Font.mainBlack(size: 30), textColor: .label)
    
    private let registerLabel = UILabel.customLabel(text: "Don't have an account?", font: AppTheme.Font.mainRegular(size: 14), textColor: .secondaryLabel)
    
    private let registerlink = UIButton.textButton(text: "Sign Up")
    
    private let hstack2 = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
    
    private let emailInput = UIStackView.createInputGroup(labelName: "Email", placeholder: "Enter email...")
    
    private let passwordInput = UIStackView.createInputGroup(labelName: "Password", placeholder: "Enter password...")
    
    
    
    private let mainstack = UIStackView.customStack(xPadding: 15, yPadding: 20, background: .white, axis: .vertical, alignment: .fill, distribution: .fill, cornerRadius: 12)
    
    //MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindLoading(to: viewModel.loading)
        setupUI()
    }
    
    //MARK: - SETUP UI
    func setupUI() {
        setupBackground()
        view.addSubview(hstack)
        view.addSubview(mainstack)
        mainstack.addArrangedSubview(loginLabel)
    }
}
