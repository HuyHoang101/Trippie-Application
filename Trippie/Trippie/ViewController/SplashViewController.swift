//
//  FlashScreen.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

class SplashViewController: AuthBaseViewController {
    
    var onAnimationCompleted: (() -> Void)?
    
    
    //MARK: - UI COMPONENT
    private let containerStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private var allLetterLabels: [UILabel] = []
    
    
    
    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startFallingAnimation()
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let titleStack = createWorkStack(text: "Trippie", font: AppTheme.Font.mainBlack(size: 50))
        containerStack.addArrangedSubview(titleStack)
        
        let sloganStack = createWorkStack(text: "Travel together", font: AppTheme.Font.mainBold(size: 32))
        containerStack.addArrangedSubview(sloganStack)
        
        prepareAnimation()
    }
    
    private func createWorkStack(text: String, font: UIFont) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .bottom
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        for char in text {
            let label = UILabel()
            label.text = String(char)
            label.font = font
            label.textColor = .white
            
            if char == " " {
                label.widthAnchor.constraint(equalToConstant: 8).isActive = true
            }
            stack.addArrangedSubview(label)
            
            if char != " " {
                allLetterLabels.append(label)
            }
        }
        return stack
    }
    
    //MARK: - ANIMATION
    private func prepareAnimation() {
        for label in allLetterLabels {
            label.transform = CGAffineTransform(translationX: -20, y: -50)
            label.alpha = 0
        }
    }
    
    private func startFallingAnimation() {
        var delayCounter: Double = 0
        
        for (_, label) in allLetterLabels.enumerated() {
            UIView.animate(
                withDuration: 0.4,
                delay: delayCounter,
                usingSpringWithDamping: 0.6, //Hiệu ứng nảy (bouncy)
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: {
                    label.transform = .identity
                    label.alpha = 1
                }, completion: nil
            )
            delayCounter += 0.1
        }
        
        let totalTime = delayCounter + 0.5 + 0.7
        
        // Call func go to app
        DispatchQueue.main.asyncAfter(deadline: .now() + totalTime) { [weak self] in
            self?.onAnimationCompleted?()
        }
    }
}
