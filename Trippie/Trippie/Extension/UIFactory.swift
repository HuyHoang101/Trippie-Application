//
//  InputUIFactory.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import SDWebImage


// MARK: - INPUT STACK VIEW

extension UITextField {
    
    static func createInput(placeholder: String,
                            keyboardType: UIKeyboardType = .default,
                            accentColor: UIColor? = nil) -> UITextField {
        
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Padding chung (cho cả 2 style đều đẹp)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        // --- CHECK STYLE ---
        if let accent = accentColor {
            // CASE 1: CÓ MÀU -> GLASSMORPHISM (Dùng cho Login/Dark BG)
            tf.backgroundColor = accent.withAlphaComponent(0.3)
            tf.layer.borderColor = accent.cgColor
            tf.layer.borderWidth = 1.0
            tf.layer.cornerRadius = 12
            tf.textColor = .white
            tf.borderStyle = .none // Tắt border mặc định để dùng border layer
            
            // Placeholder màu trắng mờ
            tf.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            )
        } else {
            // CASE 2: KHÔNG MÀU -> DEFAULT SYSTEM (Dùng cho màn hình trắng)
            tf.borderStyle = .roundedRect
            tf.backgroundColor = .systemBackground // Tự động trắng/đen theo theme
            tf.textColor = .label
            // Placeholder tự động màu xám của hệ thống, không cần chỉnh
        }
        
        return tf
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
    
    // Hàm helper tạo Input Group (Label + Input)
    static func createInputGroup(labelName: String,
                                 labelFont: UIFont = .systemFont(ofSize: 16, weight: .semibold), // Default font
                                 labelColor: UIColor = .label, // Default màu đen/trắng hệ thống
                                 inputAccentColor: UIColor? = nil, // Default không style
                                 placeholder: String,
                                 isTextView: Bool = false,
                                 keyboardType: UIKeyboardType = .default,
                                 delegate: Any? = nil) -> UIStackView {
            
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
            let tf = UITextField.createInput(placeholder: placeholder,
                                             keyboardType: keyboardType,
                                             accentColor: inputAccentColor)
            if let tfDelegate = delegate as? UITextFieldDelegate {
                tf.delegate = tfDelegate
            }
            tf.returnKeyType = .done
            stack.addArrangedSubview(tf)
        }
        
        return stack
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
        
        // 1. XỬ LÝ PADDING (Quan trọng)
        // UIStackView dùng 'layoutMargins' để làm padding
        if xPadding != nil || yPadding != nil {
            let x = xPadding ?? 0
            let y = yPadding ?? 0
            stack.isLayoutMarginsRelativeArrangement = true // Bắt buộc phải bật cái này
            stack.layoutMargins = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        }
        
        // 2. XỬ LÝ BACKGROUND
        // Từ iOS 14, UIStackView đã hiển thị được background color
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
    
    // CASE A: NÚT TEXT (VUÔNG BO GÓC)
    static func customButton(text: String,
                             font: UIFont = .systemFont(ofSize: 16, weight: .bold),
                             backgroundColor: UIColor,
                             textColor: UIColor = .white) -> UIButton {
        
        let button = AnimatedButton(type: .custom)
        
        // config of button
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = textColor
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        var container = AttributeContainer()
        container.font = font
        config.attributedTitle = AttributedString(text, attributes: container)
        
        config.cornerStyle = .fixed
        config.background.cornerRadius = 12
        
        button.configuration = config
        button.isCircle = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
    
    // CASE B: NÚT ẢNH (TRÒN)
    static func customButton(image: UIImage?,
                             backgroundColor: UIColor,
                             tintColor: UIColor = .white) -> UIButton {
        
        let button = AnimatedButton(type: .custom)
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = tintColor
        config.image = image
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isCircle = true
        
        return button
    }
    
    static func textButton(text: String,
                           font: UIFont = AppTheme.Font.mainBold(size: 14),
                           color: UIColor = .systemBlue) -> UIButton {
        
        let button = AnimatedButton(type: .system) // Dùng .system để có hiệu ứng mờ khi chạm
        
        var config = UIButton.Configuration.plain() // Plain = Không nền
        config.baseForegroundColor = color
        
        var container = AttributeContainer()
        container.font = font
        config.attributedTitle = AttributedString(text, attributes: container)
        
        // Loại bỏ khoảng cách thừa để sát lề
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isCircle = false
        
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
}
