//
//  TripStyleExplaination.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/2/26.
//

import UIKit

class TripStyleExplaination: UIViewController {
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    //MARK: - UI COMPONENT
    private let mainStack = UIStackView.customStack(
        xPadding: 20,
        yPadding: 30,
        background: .systemBackground,
        axis: .vertical,
        alignment: .fill,
        distribution: .fill,
        stackSpacing: 25,
        cornerRadius: 24
    )
    
    private let headerLabel = UILabel.customLabel(
        text: "Trip Types Guide",
        font: .systemFont(ofSize: 20, weight: .bold),
        textColor: .label
    )

    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - SETUPUI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        

        view.addSubview(mainStack)
        mainStack.addArrangedSubview(headerLabel)
        
        mainStack.addArrangedSubview(createTypeRow(
            type: TripType.buddy.rawValue,
            explanation: "Find new friends with similar interests to travel with."
        ))
        
        mainStack.addArrangedSubview(createTypeRow(
            type: TripType.localHost.rawValue,
            explanation: "The tour planner is a local resident, ready to guide visitors through the experience firsthand."
        ))
        
        mainStack.addArrangedSubview(createTypeRow(
            type: TripType.seekingLocal.rawValue,
            explanation: "The planner is a tourist looking for a local guide."
        ))

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    
    // MARK: - HELPER
    // Hàm helper tạo từng dòng giải thích
    private func createTypeRow(type: String, explanation: String) -> UIStackView {
        let tagLabel = UILabel.boxStyle(
            text: type.toSentenceCase(),
            font: .systemFont(ofSize: 12, weight: .bold),
            background: .button,
            textColor: .white
        )
        
        let descLabel = UILabel.customLabel(
            text: explanation,
            font: .systemFont(ofSize: 14),
            textColor: .secondaryLabel
        )
        descLabel.numberOfLines = 0
        
        let row = UIStackView.customStack(
            axis: .horizontal,
            alignment: .center,
            distribution: .fill,
            stackSpacing: 15
        )
        
        // Fix chiều rộng cho tag để cột text bên phải luôn thẳng hàng
        tagLabel.widthAnchor.constraint(equalToConstant: 110).isActive = true
        
        row.addArrangedSubview(tagLabel)
        row.addArrangedSubview(descLabel)
        
        return row
    }
}
