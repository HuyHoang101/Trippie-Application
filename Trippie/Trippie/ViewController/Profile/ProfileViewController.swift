//
//  ProfileViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class ProfileViewController: FadeBaseViewController {
    
    private let viewModel = LoginViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    
    //MARK: - UI COMPONENT
    private let logout = UIButton.customButton(image: UIImage(systemName: "rectangle.portrait.and.arrow.right"), backgroundColor: (UIColor(named: "AuthBackground2") ?? UIColor.systemBlue), tintColor: .label, padding: 12)
    private let mainScroll = UIScrollView()
    private let maincontent = UIView()
    
    private let decorateUI = UIView()
    
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setAction()
        binding()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        
        view.addSubview(logout)
        
        NSLayoutConstraint.activate([
            logout.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            logout.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    //MARK: - SETUP ACTION
    private func setAction() {
        logout.addTarget(self, action: #selector(logoutAction), for: .touchUpInside)
    }
    
    @objc private func logoutAction() {
        viewModel.logout()
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
    }
}
