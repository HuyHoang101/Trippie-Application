//
//  BaseScreenAuth.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class AuthBaseViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Cập nhật frame cho gradient layer
        if let gradient = self.view.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = self.view.bounds
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Kiểm tra xem giao diện có thực sự thay đổi màu không
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setupBackground()
        }
    }
    
    func setupBackground() {
        AppTheme.applyAuthBackground(to: self.view)
    }
    
    // MARK: - Orientation Lock
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: - BINDING
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
