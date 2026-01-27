//
//  TripCellView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/27/26.
//

import UIKit

class UniversalTripCard: UIView {
    
    // MARK: - UI COMPONENTS
    private let imgView = TrippieImageView(style: .rounded(radius: 8, corners: nil))
    
    // 1. Title
    private let titleLabel = UILabel.customLabel(text: "Trip Title", font: .systemFont(ofSize: 16, weight: .bold), textColor: .label)
    
    // 2. Middle Row Components
    private let locationLabel = UILabel.customLabel(text: "Location, Country", font: .systemFont(ofSize: 13, weight: .regular), textColor: .secondaryLabel)
    
    private let dayIndexLabel = UILabel.customLabel(text: "3 Days", font: .systemFont(ofSize: 12, weight: .bold), textColor: UIColor(named: "AuthBackground1") ?? UIColor.purple)
    
    // 3. Planner
    private let plannerLabel = UILabel.customLabel(text: "Plan by: Owner", font: .systemFont(ofSize: 12, weight: .medium), textColor: .darkGray)
    
    // 4. Footer Components (List Mode)
    private let footerStack = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
    private let dateLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 12), textColor: .gray)
    
    // Status Box
    private let statusContainer = UIView()
    private let statusLabel = UILabel()
    
    // MARK: - INIT
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - SETUP LAYOUT
    private func setupLayout() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        
        // Shadow Setup
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 4
        
        // 1. Setup Image
        imgView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imgView)
        
        // 2. Setup Middle Row (Location + Day Index)
        // Dùng StackView ngang để chứa 2 ông này
        let middleStack = UIStackView(arrangedSubviews: [locationLabel, dayIndexLabel])
        middleStack.axis = .horizontal
        middleStack.spacing = 8
        middleStack.alignment = .firstBaseline // Căn theo chân chữ cho thẳng hàng
        middleStack.distribution = .fill // Location chiếm hết chỗ trống, Day bị đẩy về phải
        
        // Cấu hình độ ưu tiên để Location tự co ngắn lại nếu hết chỗ, Day Index luôn hiển thị
        locationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        locationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        dayIndexLabel.setContentHuggingPriority(.required, for: .horizontal)
        dayIndexLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // 3. Setup Footer (Status Box)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.translatesAutoresizingMaskIntoConstraints = false
        statusContainer.layer.cornerRadius = 6
        statusContainer.clipsToBounds = true
        statusContainer.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: -4),
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -8)
        ])
        
        footerStack.addArrangedSubview(dateLabel)
        let spacer = UIView() // Spacer đẩy status về cuối
        footerStack.addArrangedSubview(spacer)
        footerStack.addArrangedSubview(statusContainer)
        
        // 4. Main Stack (Gom tất cả vào đây)
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, middleStack, plannerLabel, footerStack])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.alignment = .fill
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoStack)
        
        // --- CONSTRAINTS ---
        NSLayoutConstraint.activate([
            // Image Constraints
            imgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imgView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgView.widthAnchor.constraint(equalToConstant: 110),
            imgView.heightAnchor.constraint(equalToConstant: 90),
            
            // Card Constraints (Chiều cao tối thiểu)
            heightAnchor.constraint(greaterThanOrEqualToConstant: 110),
            
            // Info Stack Constraints
            infoStack.leadingAnchor.constraint(equalTo: imgView.trailingAnchor, constant: 12),
            infoStack.topAnchor.constraint(equalTo: imgView.topAnchor, constant: 2), // Căn chỉnh top một chút cho đẹp
            infoStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
        
        titleLabel.numberOfLines = 1
        locationLabel.lineBreakMode = .byTruncatingTail
    }
    
    // MARK: - CONFIGURATION
    func configure(trip: Trip, isListMode: Bool = false) {
        // 1. Data
        titleLabel.text = trip.title
        locationLabel.text = "\(trip.location), \(trip.country)"
        plannerLabel.text = "Planer: \(trip.ownerName)"
        dayIndexLabel.text = "\(trip.dayIndex) Days"
        imgView.setImage(url: trip.coverImage)
        
        // 2. Logic ẩn hiện
        footerStack.isHidden = !isListMode
        
        if isListMode {
            // Hiển thị đầy đủ cho màn hình List
            
            // Format Date
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            dateLabel.text = formatter.string(from: trip.startTime)
            
            // Status Logic
            // Lưu ý: trip.status trả về String hoặc Enum
            // Đây là ví dụ xử lý String, cậu sửa logic màu tùy ý nhé
            let statusText = trip.status.rawValue.capitalized
            let isFull = statusText.lowercased() == "full"
            
            statusContainer.backgroundColor = isFull ? UIColor.systemRed.withAlphaComponent(0.1) : UIColor.systemGreen.withAlphaComponent(0.1)
            statusLabel.text = statusText
            statusLabel.textColor = isFull ? .systemRed : .systemGreen
            statusLabel.font = .systemFont(ofSize: 11, weight: .bold)
        }
    }
}
