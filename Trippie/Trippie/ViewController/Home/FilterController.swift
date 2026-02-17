//
//  FilterController.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 17/2/26.
//

import UIKit
import CountryPickerView
import Combine

class FilterController: UIViewController {
    
    private let viewModel = TripFeedViewModel.shared
    
    private let containerView = UIStackView.customStack(xPadding: 20, yPadding: 20, background: .background, axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 12, cornerRadius: 12, isShadow: true)
    
    private let searchBtn = UIButton.customButton(text: "Search", backgroundColor: .authBackground2)
    private let closeButton = UIButton.customButton(image: UIImage(systemName: "xmark.circle.fill"), backgroundColor: .clear, tintColor: .white)
    private lazy var countryField = UIStackView.createInputGroup(
        labelName: "Country:",
        placeholder: "Select your country",
        style: .country,
        inputHeight: 45,
        onCountryTap: { [weak self] in
            self?.showCountryPicker()
        }
    )
    private let countryPickerView = CountryPickerView()
    private let searchBar = UITextField.createInput(placeholder: "Searching...", iconName: "magnifyingglass")
    
    private lazy var tripTypeGroup = UIStackView.createChoiceGroup(
        labelName: "Trip type:",
        options: ["buddy", "local_host", "seeking_local"]
    )
    private var selectedType: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAction()
        if let countryTF = countryField.arrangedSubviews[1] as? UITextField {
            countryTF.tintColor = .clear
            countryTF.inputView = UIView()
        }
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.addSubview(containerView)
        view.addSubview(closeButton)
        containerView.addArrangedSubview(searchBar)
        containerView.addArrangedSubview(countryField)
        containerView.addArrangedSubview(tripTypeGroup.stack)
        containerView.addArrangedSubview(searchBtn)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            closeButton.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 12)
        ])
    }
    
    
    //MARK: - SETUP ACTION
    private func setupAction() {
        closeButton.addTarget(self, action: #selector(tapDismiss), for: .touchUpInside)
        tripTypeGroup.buttons.forEach { button in
            button.addTarget(self, action: #selector(handleSingleChoice(_:)), for: .touchUpInside)
        }
        searchBtn.addTarget(self, action: #selector(tapToSearch), for: .touchUpInside)
    }
    
    @objc private func tapDismiss() {
        self.dismiss(animated: true)
    }
    
    @objc private func tapToSearch() {
        let lvc = ListViewController()
        lvc.isFilter = true
        lvc.navigationTitle = "Filtered List"
        
        // Cập nhật data cho ViewModel
        viewModel.searchText.send(searchBar.text ?? "")
        viewModel.country.send(countryField.inputValue ?? "")
        viewModel.tripType.send(TripType(rawValue: selectedType ?? "") ?? nil)
        
        // 1. Tóm lấy Navigation Controller của màn hình cha ở dưới
        guard let presentingNav = self.presentingViewController as? UINavigationController
                ?? self.presentingViewController?.navigationController else {
            self.dismiss(animated: true)
            return
        }
        
        // 2. Tắt màn hình Filter đi
        self.dismiss(animated: true) {
            // 3. Closure này sẽ chạy NGAY SAU KHI màn hình Filter tụt xuống xong
            
            // Tạo hiệu ứng Push chậm 1 giây
            let transition = CATransition()
            transition.duration = 1.0 // Thời gian 1 giây cậu muốn
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .push
            transition.subtype = .fromRight
            
            // Ép hiệu ứng này vào Navigation Controller
            presentingNav.view.layer.add(transition, forKey: kCATransition)
            
            // QUAN TRỌNG: animated chỗ này PHẢI LÀ FALSE.
            // Vì nếu để true, nó sẽ bị đè hiệu ứng gốc của Apple lên hiệu ứng 1s của mình.
            presentingNav.pushViewController(lvc, animated: false)
        }
    }
    
    @objc private func handleSingleChoice(_ sender: UIButton) {
        // 1. Reset toàn bộ các nút về trạng thái chưa chọn
        tripTypeGroup.buttons.forEach { button in
            updateButtonStyle(button, isSelected: false)
        }
        
        // 2. Kích hoạt nút vừa được bấm
        updateButtonStyle(sender, isSelected: true)
        
        // 3. Lưu giá trị đã chọn vào biến
        if let attributedTitle = sender.configuration?.attributedTitle {
            // Chuyển đổi CharacterView thành String chuẩn
            let titleString = String(attributedTitle.characters)
            
            // Xử lý chuỗi để lưu vào selectedType
            self.selectedType = titleString.lowercased().replacingOccurrences(of: " ", with: "_")
        }

    }
    
    private func updateButtonStyle(_ button: UIButton, isSelected: Bool) {
        var config = button.configuration
        
        if isSelected {
            config?.background.backgroundColor = .button
            config?.attributedTitle?.foregroundColor = .white
        } else {
            config?.background.backgroundColor = .systemGray6 // Màu xám (chưa chọn)
            config?.attributedTitle?.foregroundColor = .darkGray
        }
        
        button.configuration = config
    }
    
    private func showCountryPicker() {
        countryPickerView.delegate = self
        countryPickerView.showCountriesList(from: self)
    }
}


extension FilterController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        // 1. Gán giá trị (Hiển thị lên màn hình nhưng chưa kích hoạt sự kiện)
        self.countryField.inputValue = country.name
        
        // Thủ công editingChanged
        if let tf = self.countryField.arrangedSubviews[1] as? UITextField {
            tf.sendActions(for: .editingChanged)
        }
    }
}
