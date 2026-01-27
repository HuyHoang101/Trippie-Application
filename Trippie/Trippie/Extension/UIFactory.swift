//
//  InputUIFactory.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import SDWebImage
import PhoneNumberKit


// MARK: - INPUT STACK VIEW

extension UITextField {
    
    static func createInput(placeholder: String,
                            keyboardType: UIKeyboardType = .default,
                            accentColor: UIColor? = nil,
                            iconName: String? = nil) -> UITextField { // Thêm iconName
        
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        // --- XỬ LÝ ICON VÀ PADDING ---
        if let name = iconName {
            // Nếu có Icon: Tạo một Container để chứa Icon + Space
            let container = UIView()
            
            let iconView = UIImageView(image: UIImage(systemName: name))
            iconView.contentMode = .scaleAspectFit
            // Màu icon: Nếu là Glassmorphism (có accent) thì màu trắng mờ, ngược lại dùng gray hệ thống
            iconView.tintColor = accentColor != nil ? UIColor.white.withAlphaComponent(0.6) : .systemGray
            iconView.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(iconView)
            
            // Setup Constraint cho Icon nằm thụt vào một chút (ví dụ 12pt từ lề trái)
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),
                // Quan trọng: Container phải có chiều rộng đủ cho icon + khoảng cách đến text (ví dụ thêm 8pt bên phải icon)
                container.trailingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
            ])
            
            tf.leftView = container
        } else {
            // Nếu không có Icon: Giữ nguyên padding 12pt cũ của cậu
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            tf.leftView = paddingView
        }
        
        tf.leftViewMode = .always
        
        // --- PHẦN STYLE (GIỮ NGUYÊN CODE CŨ CỦA CẬU) ---
        if let accent = accentColor {
            tf.backgroundColor = accent.withAlphaComponent(0.3)
            tf.layer.borderColor = accent.cgColor
            tf.layer.borderWidth = 1.0
            tf.layer.cornerRadius = 12
            tf.textColor = .white
            tf.borderStyle = .none
            
            tf.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            )
        } else {
            tf.borderStyle = .roundedRect
            tf.backgroundColor = .systemBackground
            tf.textColor = .label
        }
        
        return tf
    }
    
    func enablePasswordToggle() {
        let configSymbol = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let eyeImage = UIImage(systemName: "eye.slash", withConfiguration: configSymbol)
        
        let button = UIButton(type: .custom)
        
        // Dùng Configuration
        var config = UIButton.Configuration.plain()
        config.image = eyeImage
        config.baseForegroundColor = .systemGray2
        
        // Thay cho imageEdgeInsets: Dùng padding để đẩy icon vào trong một chút
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10)
        
        button.configuration = config
        
        // Update hình ảnh khi trạng thái thay đổi
        let action = UIAction { [weak self, weak button] _ in
            guard let self = self, let button = button else { return }
            self.isSecureTextEntry.toggle()
            
            // Cập nhật lại icon theo trạng thái
            let imageName = self.isSecureTextEntry ? "eye.slash" : "eye"
            button.configuration?.image = UIImage(systemName: imageName, withConfiguration: configSymbol)
            
            
            // Fix lỗi nhảy font/cursor khi toggle
            let text = self.text
            self.text = nil
            self.text = text
        }
        
        button.addAction(action, for: .touchUpInside)
        
        self.rightView = button
        self.rightViewMode = .always
    }
    
    func setupDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels // Hoặc .inline nếu muốn hiện lịch to
        
        // Gán picker vào inputView (Thay thế bàn phím)
        self.inputView = datePicker
        
        // Thêm thanh Toolbar có nút "Done" để đóng lịch
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePressed))
        toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneBtn], animated: true)
        self.inputAccessoryView = toolbar
        
        // Lắng nghe sự kiện đổi ngày
        let action = UIAction { [weak self] _ in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.dateFormat = "dd/MM/yyyy"
            self?.text = formatter.string(from: datePicker.date)
        }
        datePicker.addAction(action, for: .valueChanged)
    }
    
    @objc private func donePressed() {
        self.resignFirstResponder()
    }
}

extension UITextView {
    static func createInput(placeholder: String,
                                keyboardType: UIKeyboardType = .default,
                                accentColor: UIColor? = nil) -> UITextView {
        
        let tv = PlaceholderTextView()
        tv.placeholder = placeholder
        tv.keyboardType = keyboardType
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16)
        tv.layer.cornerRadius = 8
        
        if let accent = accentColor {
            // CASE 1: GLASSMORPHISM
            tv.backgroundColor = accent.withAlphaComponent(0.3)
            tv.layer.borderColor = accent.cgColor
            tv.layer.borderWidth = 1.0
            tv.textColor = .white
            
            // Placeholder màu trắng mờ
            tv.textColor = .white.withAlphaComponent(0.6)
        } else {
            // CASE 2: DEFAULT SYSTEM
            tv.backgroundColor = .systemBackground
            tv.layer.borderColor = UIColor.systemGray4.cgColor
            tv.layer.borderWidth = 0.5
            tv.textColor = .label
            
            // Placeholder màu xám
            tv.textColor = .lightGray
        }
        
        tv.heightAnchor.constraint(equalToConstant: 100).isActive = true
        return tv
    }
}

extension UIStackView {
    var inputValue: String? {
        get {
            guard arrangedSubviews.count > 1 else { return nil }
            let inputField = arrangedSubviews[1]
            
            if let tf = inputField as? UITextField {
                return tf.text?.isEmpty == true ? nil : tf.text
            } else if let tv = inputField as? UITextView {
                // Logic check màu xám của cậu vẫn hoạt động tốt với class mới
                if tv.textColor == .lightGray || tv.text == (tv as? PlaceholderTextView)?.placeholder || tv.text.isEmpty {
                    return nil
                }
                return tv.text
            }
            return nil
        }
        set {
            guard arrangedSubviews.count > 1 else { return }
            let inputField = arrangedSubviews[1]
            let value = newValue ?? ""
            
            if let tf = inputField as? UITextField {
                tf.text = value
            } else if let tv = inputField as? PlaceholderTextView { // Cast về class custom
                if value.isEmpty {
                    // Reset về trạng thái placeholder
                    tv.text = tv.placeholder
                    tv.textColor = .lightGray
                } else {
                    // Set giá trị thật
                    tv.text = value
                    tv.textColor = .label
                }
            }
        }
    }
    
    func listenToChanges(completion: @escaping (String) -> Void) {
        guard arrangedSubviews.count > 1 else { return }
        let inputField = arrangedSubviews[1]
        
        if let tf = inputField as? UITextField {
            // Dùng UIAction
            let action = UIAction { [weak tf] _ in
                completion(tf?.text ?? "")
            }
            tf.addAction(action, for: .editingChanged)
        }
    }
    
    // Hàm helper tạo Input Group (Label + Input)
    static func createInputGroup(labelName: String,
                                 labelFont: UIFont = .systemFont(ofSize: 16, weight: .semibold), // Default font
                                 labelColor: UIColor = .label, // Default màu đen/trắng hệ thống
                                 inputAccentColor: UIColor? = nil, // Default không style
                                 placeholder: String,
                                 isTextView: Bool = false,
                                 style: InputStyle = .text, // Default text
                                 keyboardType: UIKeyboardType = .default,
                                 inputHeight: CGFloat? = nil,
                                 delegate: Any? = nil,
                                 errorFontSize: CGFloat = 11
    ) -> UIStackView {
            
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. Setup Label
        let label = UILabel()
        label.text = labelName
        label.font = labelFont
        label.textColor = labelColor
        stack.addArrangedSubview(label)
        
        // 2. Setup Input
        if isTextView {
            let tv = UITextView.createInput(placeholder: placeholder,
                                            keyboardType: keyboardType,
                                            accentColor: inputAccentColor)
            if let tvDelegate = delegate as? UITextViewDelegate {
                tv.delegate = tvDelegate
            }
            tv.returnKeyType = .done
            stack.addArrangedSubview(tv)
        } else {
            let tf: UITextField
                
            if style == .phoneNumber {
                let phoneTF = PhoneNumberTextField()
                
                // 1. Cấu hình cơ bản
                phoneTF.withFlag = true
                phoneTF.withPrefix = true
                phoneTF.withExamplePlaceholder = true
                
                // 2. Bật chức năng chọn quốc gia (QUAN TRỌNG)
                // Thuộc tính này tự động bật action: Nhấn vào cờ -> Hiện danh sách
                phoneTF.withDefaultPickerUI = true
                phoneTF.modalPresentationStyle = .pageSheet // Dạng popup hiện đại
                
                // 3. Cấu hình mặc định
                phoneTF.partialFormatter.defaultRegion = "VN"
                
                // 4. FIX PADDING LÁ CỜ (Chuẩn iOS 15+)
                // Thay vì dùng imageEdgeInsets, ta dùng Configuration
                var config = UIButton.Configuration.plain()
                // leading: 10 -> Cách mép trái | trailing: 8 -> Cách số điện thoại
                config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 8)
                phoneTF.flagButton.configuration = config
                
                // 5. UI Style (Border, Màu nền)
                phoneTF.backgroundColor = inputAccentColor?.withAlphaComponent(0.3)
                phoneTF.layer.cornerRadius = 6
                phoneTF.layer.borderWidth = 1
                phoneTF.layer.borderColor = inputAccentColor?.cgColor ?? UIColor.systemGray5.cgColor
                
                // Style text bên trong
                phoneTF.textColor = .label
                phoneTF.font = .systemFont(ofSize: 16, weight: .regular)
                
                tf = phoneTF
            } else {
                
                tf = UITextField.createInput(placeholder: placeholder,
                                             keyboardType: keyboardType,
                                             accentColor: inputAccentColor)
            }
            
            if let tfDelegate = delegate as? UITextFieldDelegate {
                tf.delegate = tfDelegate
            }
            
            // Logic cho từng Style
            switch style {
            case .email:
                tf.keyboardType = .emailAddress
                tf.autocapitalizationType = .none
            case .password:
                tf.isSecureTextEntry = true
                tf.enablePasswordToggle() // Helper inextension
            case .text:
                tf.keyboardType = keyboardType
            case .date:
                tf.setupDatePicker()
            case .phoneNumber:
                tf.keyboardType = .numberPad
            }
            
            if let height = inputHeight {
                tf.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
            tf.returnKeyType = .done
            stack.addArrangedSubview(tf)
        }
        
        let errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.font = AppTheme.Font.mainRegular(size: errorFontSize)
        errorLabel.numberOfLines = 0 // Để lỗi dài tự xuống dòng
        errorLabel.isHidden = true   // Mặc định ẩn đi để không chiếm chỗ
        errorLabel.tag = 666         // Đánh dấu (Tag) để sau này tìm lại được nó
        
        stack.addArrangedSubview(errorLabel)
        
        return stack
    }
    
    // Hàm gọi lỗi: Truyền String vào thì hiện, truyền nil thì ẩn
    func showError(_ message: String?) {
        // 1. Tìm cái label lỗi bằng cái Tag 666
        guard let errorLabel = self.viewWithTag(666) as? UILabel else { return }
        
        // 2. Animation
        UIView.animate(withDuration: 0.25) {
            if let msg = message, !msg.isEmpty {
                // Có lỗi -> Hiện
                errorLabel.text = msg
                errorLabel.isHidden = false
            } else {
                // Không có lỗi (nil hoặc rỗng) -> Ẩn
                errorLabel.text = nil
                errorLabel.isHidden = true
            }
            
            // Lệnh này bắt buộc để StackView tính toán lại layout ngay trong animation
            self.layoutIfNeeded()
        }
    }
    
    static func customStack(xPadding: CGFloat? = nil,
                            yPadding: CGFloat? = nil,
                            background: UIColor = .clear,
                            axis: NSLayoutConstraint.Axis,
                            alignment: UIStackView.Alignment,
                            distribution: UIStackView.Distribution,
                            stackSpacing: CGFloat = 10,
                            isBorder: Bool = false,
                            borderColor: UIColor = .systemGray4,
                            cornerRadius: CGFloat = 0,
                            isShadow: Bool = false
    ) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = axis
        stack.alignment = alignment
        stack.distribution = distribution
        stack.backgroundColor = background
        stack.spacing = stackSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. XỬ LÝ PADDING
        // UIStackView dùng 'layoutMargins' để làm padding
        if xPadding != nil || yPadding != nil {
            let x = xPadding ?? 0
            let y = yPadding ?? 0
            stack.isLayoutMarginsRelativeArrangement = true
            stack.layoutMargins = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        }
        
        // 2. XỬ LÝ BACKGROUND
        stack.backgroundColor = background
        
        // 3. XỬ LÝ BORDER
        if isBorder {
            stack.layer.borderWidth = 1.0
            stack.layer.borderColor = borderColor.cgColor
        }
        
        // 4. XỬ LÝ CORNER RADIUS
        if cornerRadius > 0 {
            stack.layer.cornerRadius = cornerRadius
            // Lưu ý: Với StackView, thường không cần clipsToBounds = true trừ khi nội dung bên trong bị tràn
            // Nếu bật clipsToBounds = true thì Shadow sẽ bị cắt mất.
        }
        
        // 5. XỬ LÝ SHADOW
        if isShadow {
            stack.layer.shadowColor = UIColor.black.cgColor
            stack.layer.shadowOpacity = 0.1
            stack.layer.shadowOffset = CGSize(width: 0, height: 4)
            stack.layer.shadowRadius = 6
            stack.clipsToBounds = false // BẮT BUỘC: Phải là false thì bóng mới hiện ra ngoài viền được
        }
        return stack
    }
}


//MARK: - LABEL

extension UILabel {
    
    static func boxStyle(text: String, font: UIFont, background:UIColor, textColor: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = background.withAlphaComponent(0.3)
        label.layer.borderWidth = 1.0
        label.layer.borderColor = background.cgColor
        label.clipsToBounds = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: -2, height: 2)
        label.layer.shadowOpacity = 0.2
        label.layer.shadowRadius = 3
        return label
    }
    
    static func customLabel(text: String, font: UIFont, textColor: UIColor, textAligment: NSTextAlignment = .left) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        label.textAlignment = textAligment
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}


// MARK: - BUTTON
extension UIButton {
    
    // CASE A: NÚT TEXT + ICON (VUÔNG BO GÓC)
    static func customButton(text: String,
                             font: UIFont = .systemFont(ofSize: 16, weight: .bold),
                             backgroundColor: UIColor,
                             textColor: UIColor = .white,
                             isPadding: Bool = true,
                             isCircle: Bool = true,
                             imageName: String? = nil,
                             isSystemImage: Bool = true,
                             imageSize: CGFloat = 20, // size ảnh
                             isBorder: Bool = false,
                             borderColor: UIColor = .clear
    ) -> UIButton {
        
        let button = AnimatedButton(type: .custom)
        
        // Config
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = textColor
        
        if isPadding {
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        } else {
            config.contentInsets = .zero
        }
        // Setup Title
        var container = AttributeContainer()
        container.font = font
        config.attributedTitle = AttributedString(text, attributes: container)
        
        // Setup Image
        if let imgName = imageName {
            if isSystemImage {
                // SF Symbol: Dùng Configuration để chỉnh size
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: imageSize, weight: .semibold)
                config.image = UIImage(systemName: imgName, withConfiguration: symbolConfig)?.withRenderingMode(.alwaysTemplate)
            } else {
                // Assets Image: Resize bằng Renderer
                if let assetImage = UIImage(named: imgName) {
                    let scalable = CGSize(width: imageSize, height: imageSize)
                    let renderer = UIGraphicsImageRenderer(size: scalable)
                    let resizeImage = renderer.image { _ in
                        assetImage.draw(in: CGRect(origin: .zero, size: scalable))
                    }
                    // .alwaysTemplate để ăn theo màu textColor,
                    // .alwaysOriginal nếu muốn giữ màu gốc (như logo Google)
                    config.image = resizeImage.withRenderingMode(.alwaysOriginal)
                }
            }
            config.imagePlacement = .leading
            config.imagePadding = 8
        }
        
        // Setup Corner Radius
        if isCircle {
            config.cornerStyle = .capsule
        } else {
            config.cornerStyle = .fixed
            config.background.cornerRadius = 12
        }
        
        // 2. FIX BORDER (Dùng chuẩn Configuration)
        if isBorder {
            config.background.strokeColor = borderColor
            config.background.strokeWidth = 0.7
        }
        
        config.titleLineBreakMode = .byClipping
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        
        return button
    }
    
    // CASE B: NÚT ẢNH (Có tuỳ chọn tròn hoặc vuông)
    static func customButton(image: UIImage?,
                             backgroundColor: UIColor,
                             tintColor: UIColor = .white,
                             isCircle: Bool = true,
                             padding: CGFloat = 8
    ) -> UIButton {
    
        let button = AnimatedButton(type: .custom)
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = tintColor
        config.image = image
        
        // LOGIC BO TRÒN NẰM Ở ĐÂY
        if isCircle {
            // Capsule: Tự động bo tròn 2 đầu
            // Nếu width = height -> Nó thành hình tròn
            config.cornerStyle = .capsule
        } else {
            // Nếu không tròn thì bo góc nhẹ
            config.cornerStyle = .fixed
            config.background.cornerRadius = 12
        }
        
        // Padding bên trong nút
        config.contentInsets = NSDirectionalEdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}


// MARK: - VIEW CONTROLLER
extension UIViewController {
    
    // Tag riêng để tìm view loading khi cần xoá
    private var loadingViewTag: Int { return 987654 }
    
    func showLoading() {
        // 1. Kiểm tra xem đã có loading đang hiện chưa (tránh hiện chồng 2 cái)
        if view.viewWithTag(loadingViewTag) != nil { return }
        
        // 2. Khởi tạo Loading View
        let loadingView = TrippieLoadingView(frame: view.bounds)
        loadingView.tag = loadingViewTag
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // Tự co giãn khi xoay màn hình
        
        // 3. Add vào màn hình
        view.addSubview(loadingView)
        
        // 4. Bắt đầu animation
        loadingView.start()
    }
    
    func hideLoading() {
        // 1. Tìm view loading thông qua Tag
        if let loadingView = view.viewWithTag(loadingViewTag) as? TrippieLoadingView {
            // 2. Dừng animation cho nhẹ máy
            loadingView.stop()
            
            // 3. Xoá khỏi màn hình với hiệu ứng mờ dần cho mượt
            UIView.animate(withDuration: 0.3, animations: {
                loadingView.alpha = 0
            }) { _ in
                loadingView.removeFromSuperview()
            }
        }
    }
    
    func showToast(message: String, isSuccess: Bool, seconds: Double = 2.0) {
        guard let window = view.window else { return }
        
        // 1. Tạo Container View (NỀN TRẮNG)
        let toastContainer = UIStackView()
        toastContainer.axis = .horizontal
        toastContainer.spacing = 12 // Tăng khoảng cách ra chút cho thoáng
        toastContainer.alignment = .center
        toastContainer.distribution = .fill
        toastContainer.backgroundColor = .white
        toastContainer.layer.cornerRadius = 12
        toastContainer.clipsToBounds = false    // QUAN TRỌNG: Phải false mới hiện được bóng đổ
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Padding
        toastContainer.isLayoutMarginsRelativeArrangement = true
        toastContainer.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        // --- THÊM ĐỔ BÓNG (SHADOW) ---
        toastContainer.layer.shadowColor = UIColor.black.cgColor
        toastContainer.layer.shadowOpacity = 0.15 // Độ đậm của bóng (0.0 - 1.0)
        toastContainer.layer.shadowOffset = CGSize(width: 0, height: 4) // Bóng đổ xuống dưới
        toastContainer.layer.shadowRadius = 8 // Độ nhoè của bóng
        
        
        // 2. Tạo Wrapper cho Icon (CÁI VÒNG TRÒN MÀU)
        let iconWrapper = UIView()
        iconWrapper.backgroundColor = isSuccess ? .systemGreen : .systemRed
        
        iconWrapper.translatesAutoresizingMaskIntoConstraints = false
        iconWrapper.layer.cornerRadius = 16 // Bằng 1/2 chiều cao (32/2)
        iconWrapper.heightAnchor.constraint(equalToConstant: 32).isActive = true
        iconWrapper.widthAnchor.constraint(equalToConstant: 32).isActive = true
        
        // 3. Tạo Icon bên trong
        let iconImageView = UIImageView()
        let iconName = isSuccess ? "checkmark" : "xmark" // Dùng icon mảnh sẽ đẹp hơn fill
        let config = UIImage.SymbolConfiguration(weight: .black)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        
        // Màu icon: Nếu nền wrapper đậm thì icon trắng, nếu nền wrapper nhạt thì icon đậm
        iconImageView.tintColor = .white
        // Nếu wrapper dùng .systemGreen/.systemRed thì ở đây tintColor = .white
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Icon vào Wrapper và căn giữa
        iconWrapper.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconWrapper.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16), // Icon nhỏ hơn wrapper
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        
        // 4. Tạo Message Label (MÀU CHỮ ĐEN)
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .black 
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.numberOfLines = 0
        
        
        // 5. Add vào Stack
        toastContainer.addArrangedSubview(iconWrapper)
        toastContainer.addArrangedSubview(messageLabel)
        
        
        // 6. Add vào Window
        window.addSubview(toastContainer)
        
        // Constraints
        NSLayoutConstraint.activate([
            toastContainer.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 10),
            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -20),
            toastContainer.centerXAnchor.constraint(equalTo: window.centerXAnchor)
        ])
        
        // Animation (Giữ nguyên)
        toastContainer.alpha = 0
        toastContainer.transform = CGAffineTransform(translationX: 0, y: -20) // Hiệu ứng trượt từ trên xuống
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            toastContainer.alpha = 1
            toastContainer.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: seconds, options: .curveEaseIn) {
                toastContainer.alpha = 0
                toastContainer.transform = CGAffineTransform(translationX: 0, y: -20)
            } completion: { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
}

extension Notification.Name {
    static let showGlobalToast = Notification.Name("showGlobalToast")
}
