//
//  TripCardView.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//

import UIKit

class TripCardView: UIView {
    
    // MARK: - Components
    
 
    private let imgView = TrippieImageView(
        style: .rounded(radius: 12, corners: [.layerMaxXMinYCorner, .layerMinXMinYCorner]),
        isShadow: false,
        borderColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.3)
    )
    
    // 2. Status Badge (Viên thuốc)
    private let statusBadge = TripStatusBadge()
    
    // 3. Text Components
    private let daysLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 14, weight: .semibold), textColor: UIColor(named: "AuthBackground1") ?? .purple)
    
    private let locationLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 14, weight: .semibold), textColor: .darkGray)
    private let startDateLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 13, weight: .regular), textColor: .gray)
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        // --- 1. Card Container Style ---
        self.backgroundColor = .white
        self.layer.cornerRadius = 12
        // Shadow cho Card
        self.layer.shadowColor = (UIColor(named: "AuthBackground2") ?? UIColor.blue).withAlphaComponent(0.2).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 6
        
        // --- 2. Image Setup ---
        imgView.translatesAutoresizingMaskIntoConstraints = false
        // Để ảnh bo góc khớp với card, ta cần clip content của ảnh
        imgView.clipsToBounds = true
        imgView.contentMode = .scaleAspectFill
        addSubview(imgView)
        
        // --- 3. Status Badge Setup ---
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        // Shadow cho viên thuốc
        statusBadge.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        statusBadge.layer.shadowOffset = CGSize(width: 2, height: 2)
        statusBadge.layer.shadowOpacity = 0.5
        statusBadge.layer.shadowRadius = 3
        addSubview(statusBadge)
        
        // --- 4. Info Stack Setup ---
        
        // Ép daysLabel chỉ to vừa đủ chữ của nó
        daysLabel.setContentHuggingPriority(.required, for: .horizontal)
        daysLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Ép startDateLabel không bị co lại theo chiều dọc
        startDateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Hàng 2: Location + StartDate
        let rowStack = UIStackView(arrangedSubviews: [locationLabel, daysLabel])
        rowStack.axis = .horizontal
        rowStack.distribution = .fill
        rowStack.alignment = .firstBaseline
        rowStack.spacing = 8
        
        // Main Stack (VStack chứa 2 hàng trên)
        let infoStack = UIStackView(arrangedSubviews: [rowStack, startDateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoStack)
        
        // --- 5. Constraints ---
        NSLayoutConstraint.activate([
            // Image: Neo trên, trái, phải. Chiều cao theo tỷ lệ
            imgView.topAnchor.constraint(equalTo: topAnchor),
            imgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Status Badge: Góc trên phải, đè lên ảnh
            statusBadge.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            statusBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // Info Stack: Nằm dưới ảnh, cách lề
            infoStack.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 12),
            infoStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12) // Quan trọng để Card tự giãn chiều cao
        ])
    }
    
    // MARK: - Data Configuration
    func configure(mytrip: TripWithStatus) {
        // 1. Data Mapping
        let trip = mytrip.trip
        

        locationLabel.text = "\(trip.location), \(trip.country)"
        daysLabel.text = "\(trip.dayIndex) days"
        daysLabel.textColor = UIColor(named: "AuthBackground1") ?? .purple // Set lại màu như yêu cầu
        
        // 2. Date Processing (Timestamp -> String)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        startDateLabel.text = "Start: " + formatter.string(from: trip.startTime)
        
        // 3. Image
        imgView.setImage(url: trip.coverImage)
        
        // 4. Personal Status & Animation
        statusBadge.configure(status: mytrip.participation.personalStatus)
    }
}
