//
//  TripContainerCell.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//
import UIKit

class TripContainerCell: UITableViewCell {
    
    // Nhúng thẻ UniversalTripCard vào
    let cardView = UniversalTripCard()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Tạo khoảng cách (Padding) giữa các cell
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func bindData(trip: TripWithStatus) {
        cardView.configure(trip: trip, isListMode: true)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.prepareForReuse()
    }
}
