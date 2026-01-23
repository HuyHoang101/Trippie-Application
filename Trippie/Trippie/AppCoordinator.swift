//
//  AppCoordinator.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class AppCoordinator {
    
    var window: UIWindow
    
    // Dùng cái này để switch root view
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
        
        // Kiểm tra logic đăng nhập ở đây
        splashVC.onAnimationCompleted = { [weak self] in
            self?.checkLoginAndNavigate()
        }
    }
    
    // MARK: - FLOWS
    private func checkLoginAndNavigate() {
        if let _ = AuthService.shared.currentUserId {
            showMainFlow()
        } else {
            showAuthFlow()
        }
    }
    
    func showAuthFlow() {
        // Tạo Navigation Controller cho luồng Auth
        let navigationController = UINavigationController()
        
        let loginVC = LoginViewController()
        
        // Setup Coordinator
        navigationController.viewControllers = [loginVC]
        
        // Gán làm root
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // Hiệu ứng chuyển cảnh nhẹ nhàng
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    func showMainFlow() {
        // Gọi MainTabCoordinator để dựng TabBar
        let mainTabCoordinator = MainTabCoordinator(window: window)
        mainTabCoordinator.start()
    }
}
