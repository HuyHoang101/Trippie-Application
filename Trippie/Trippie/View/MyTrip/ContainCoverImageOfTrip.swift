//
//  ContainCoverImageOfTrip.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/10/26.
//

import UIKit
import Combine

class ContainCoverImageOfTrip: UIView {
    
    private var cancellable = Set<AnyCancellable>()
    private let stackView = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
    private var dotViews: [UIView] = []
    private let scrollImageView = ImageColectionAnimateScroll()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        binding()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        addSubview(scrollImageView)
        addSubview(stackView)
        scrollImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollImageView.topAnchor.constraint(equalTo: topAnchor),
            scrollImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }
    
    private func setupDotView(count: Int) {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
        }
        
        for _ in 0..<count {
            let v = UIView()
            v.backgroundColor = .systemGray6.withAlphaComponent(0.4)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.widthAnchor.constraint(equalToConstant: 6).isActive = true
            v.heightAnchor.constraint(equalToConstant: 6).isActive = true
            v.layer.cornerRadius = 3
            v.clipsToBounds = true
            dotViews.append(v)
            stackView.addArrangedSubview(v)
        }
        dotViews[0].backgroundColor = .systemGray6
        dotViews[0].transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        if count <= 1 {
            stackView.isHidden = true
        } else {
            stackView.isHidden = false
        }
    }
    
    //MARK: - CONFIGURE
    func setData(from urls: [String]) {
        self.scrollImageView.configure(urls: urls)
        self.setupDotView(count: urls.count)
    }
    
    
    //MARK: - BINDING
    private func binding() {
        self.scrollImageView.$currentIndex
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] i in
                guard let self = self else { return }
                self.updateDotState(index: i)
            }
            .store(in: &cancellable)
    }
    
    private func updateDotState(index: Int) {
        guard index >= 0 && index < dotViews.count else { return }
        
        // Reset animation
        UIView.animate(withDuration: 0.3) {
            self.dotViews.forEach {
                $0.backgroundColor = .systemGray6.withAlphaComponent(0.4)
                $0.transform = .identity
            }
            
            // Highlight current
            self.dotViews[index].backgroundColor = .white // Màu sáng hẳn lên
            self.dotViews[index].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    }
}
