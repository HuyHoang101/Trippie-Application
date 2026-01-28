//
//  FeedCard.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/27/26.
//

import UIKit

class FeedCard: UIView {
    
    private let titleLabel = UILabel.customLabel(text: "", font: UIFont.systemFont(ofSize: 14, weight: .semibold), textColor: .black)
    private let countryLabel = UILabel.customLabel(text: "", font: UIFont.systemFont(ofSize: 12, weight: .medium), textColor: .systemGray3)
    private let dayIndex = UILabel.customLabel(text: "", font: UIFont.systemFont(ofSize: 12, weight: .semibold), textColor: UIColor(named: "AuthBackground1") ?? UIColor.purple, textAligment: .right)
    private let image = TrippieImageView(style: .rounded(radius: 12, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]), isShadow: false, borderColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.3))
    private let subview: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 8
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    init(trip: Trip) {
        super.init(frame: .zero)
        
        setupUI()
        configure(with: trip)
    }
    
    required init?(coder: NSCoder) { nil }
    
    //MARK: - SETUP UI
    private func setupUI() {
        backgroundColor = UIColor.clear
        image.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(image)
        addSubview(subview)
        
        subview.addSubview(titleLabel)
        subview.addSubview(countryLabel)
        subview.addSubview(dayIndex)
        
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: topAnchor),
            image.leadingAnchor.constraint(equalTo: leadingAnchor),
            image.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            image.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.74),
            
            subview.topAnchor.constraint(equalTo: image.bottomAnchor, constant: -20),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: subview.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: -12),
            
            countryLabel.leadingAnchor.constraint(equalTo: subview.leadingAnchor, constant: 12),
            countryLabel.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: -12),
            countryLabel.trailingAnchor.constraint(equalTo: dayIndex.leadingAnchor, constant: -12),
            
            dayIndex.bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: -12),
            dayIndex.trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: -12),
        ])
    }
    
    //MARK: - Config
    func configure(with trip: Trip) {
        titleLabel.text = trip.title
        countryLabel.text = trip.country
        dayIndex.text = "\(trip.dayIndex) days"
        image.setImage(url: trip.coverImage)
    }
}
