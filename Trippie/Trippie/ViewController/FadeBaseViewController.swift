//
//  FadeBaseViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class FadeBaseViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalToast(_:)),
            name: .showGlobalToast,
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Cập nhật frame cho gradient layer
        if let gradient = self.view.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = self.view.bounds
        }
    }
    
    // MARK: -  CHECKING DARKMODE
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Kiểm tra xem giao diện có thực sự thay đổi màu không
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setupBackground()
        }
    }
    
    func setupBackground() {
        AppTheme.applyFadeBackground(to: self.view)
    }
    
    //MARK: - TOAST LOGIC
    // 2. Xử lý khi nhận được tin nhắn
    @objc private func handleGlobalToast(_ notification: Notification) {
        // Lấy dữ liệu từ userInfo
        if let userInfo = notification.userInfo,
           let message = userInfo["message"] as? String,
           let isSuccess = userInfo["isSuccess"] as? Bool {
            
            // Gọi hàm showToast xịn xò của cậu
            self.showToast(message: message, isSuccess: isSuccess)
        }
    }
    
    // Nhớ hủy đăng ký khi view chết để tránh leak memory (Dù iOS mới tự lo nhưng cứ làm cho chuẩn)
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Orientation Lock
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    func bindLoading<P: Publisher>(to publisher: P) where P.Output == Bool, P.Failure == Never {
        publisher
            .receive(on: RunLoop.main) // Luôn update UI trên Main Thread
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
    }
    
}
