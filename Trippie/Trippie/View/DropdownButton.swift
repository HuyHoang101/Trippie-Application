//
//  DropdownButton.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/5/26.
//

import UIKit

class DropdownButton: UIButton {
    
    // Data source
    var items: [DropdownItem] = []
    
    // chức năng "trạng thái được chọn" (false default)
    var enableSelectionMode: Bool = false
    
    // số dòng đươc chọn (-1 là chưa chọn gì)
    var selectedIndex: Int = -1
    
    // Config giao diện Box
    private let menuWidth: CGFloat = 200
    private let rowHeight: CGFloat = 44
    
    // --- Init ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtonAppearance()
        addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- Setup Button Style (Giống style cậu gửi) ---
    private func setupButtonAppearance() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        setImage(UIImage(systemName: "ellipsis", withConfiguration: symbolConfig), for: .normal)
        tintColor = .white
        
        backgroundColor = UIColor.authBackground2.withAlphaComponent(0.5)
        
        layer.cornerRadius = 18
        layer.masksToBounds = true
        
        widthAnchor.constraint(equalToConstant: 36).isActive = true
        heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    // --- Action ---
    @objc private func didTapButton() {
        showDropdown()
    }
    
    private func showDropdown() {
        // 1. Tìm Window chuẩn (để add view lên lớp cao nhất)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        // 2. Ép Button cập nhật layout ngay lập tức để lấy frame chuẩn
        self.superview?.layoutIfNeeded()
        
        // 3. Tính toạ độ của Button so với Window (Dùng convert from self an toàn hơn)
        let rect = window.convert(self.bounds, from: self)
        
        // Debug: In ra để xem toạ độ có đúng là góc trên phải không (Ví dụ: x: 340, y: 50)
        //print("📍 Button Rect: \(rect)")
        
        // 4. Tạo Menu
        let menu = DropdownMenuView(items: items, width: menuWidth, rowHeight: rowHeight)
        
        // Cấu hình chế độ chọn cho Menu
        menu.isSelectionMode = self.enableSelectionMode
        menu.selectedIndex = self.selectedIndex
        
        // Callback: khi menu chọn dòng mới, cập nhập lại biến selectedIndex của Button
        menu.didSelectItem = { [weak self] index in
            self?.selectedIndex = index
        }
        
        // --- TÍNH TOÁN VỊ TRÍ ---
        
        // Y: Nằm ngay dưới button + 5pt đệm
        let y = rect.maxY + 5
        
        // X: Căn phải (Right Aligned)
        // Nếu rect.maxX (cạnh phải nút) < menuWidth -> Chứng tỏ bị lỗi toạ độ 0,0 -> Fallback về căn phải màn hình
        var x = rect.maxX - menuWidth
        
        // [Fix Lỗi] Nếu tính ra x bị âm hoặc quá lệch (do lỗi convert), ta ép nó dính sát lề phải màn hình
        let rightPadding: CGFloat = 16 // Cách lề phải màn hình 1 chút cho đẹp
        if x < 0 || rect.maxX == 0 {
            x = window.bounds.width - menuWidth - rightPadding
        } else {
            // Logic bình thường: Căn theo nút, nhưng nếu nút sát lề quá thì chỉnh lại chút
            // Đảm bảo menu không bị tràn ra ngoài màn hình bên phải
            if x + menuWidth > window.bounds.width {
                 x = window.bounds.width - menuWidth - rightPadding
            }
        }
        
        // 5. Gán Frame
        // Quan trọng: Phải set translatesAutoresizingMaskIntoConstraints = true (mặc định) vì ta đang dùng Frame
        menu.frame = CGRect(x: x, y: y, width: menuWidth, height: CGFloat(items.count) * rowHeight)
        
        // 6. Show
        menu.show(in: window)
    }
}





private class DropdownMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    private let items: [DropdownItem]
    private let rowHeight: CGFloat
    
    // Các biến nhận được dropdown button
    var isSelectionMode: Bool = false
    var selectedIndex: Int = -1
    
    // CallBack: cho button biết dòng nào đang được chọn
    var didSelectItem: ((Int) -> Void)?
    
    // Màn che trong suốt để bắt sự kiện tap ra ngoài
    private let backgroundButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .black.withAlphaComponent(0.05)
        return btn
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none // Tắt gạch ngang
        tv.isScrollEnabled = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()
    
    init(items: [DropdownItem], width: CGFloat, rowHeight: CGFloat) {
        self.items = items
        self.rowHeight = rowHeight
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        // Style cho cái Box
        backgroundColor = .systemBackground // Màu nền Box
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        
        addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 12
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    func show(in window: UIWindow) {
        // 1. Add background
        backgroundButton.frame = window.bounds
        backgroundButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        window.addSubview(backgroundButton)
        
        // 2. Add Box
        window.addSubview(self)
        
        // Lưu lại khung hình chuẩn đang có
        let finalFrame = self.frame
        
        // Đặt điểm neo về góc trên-phải (để bung từ đó ra)
        self.layer.anchorPoint = CGPoint(x: 1, y: 0)
        
        // Gán lại khung hình chuẩn (vì đổi anchorPoint sẽ làm lệch frame)
        self.frame = finalFrame
        // -------------------------------------
        
        // 3. Animation
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    @objc func dismiss() {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            self.backgroundButton.removeFromSuperview()
        }
    }
    
    // --- TableView Logic ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let item = items[indexPath.row]
        
        // Config Cell
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let isSelected = (isSelectionMode && indexPath.row == selectedIndex)
        
        if isSelected {
            cell.imageView?.image = UIImage(systemName: "checkmark")
            cell.imageView?.tintColor = item.type == .destructive ? .systemRed.withAlphaComponent(0.6) : item.type == .clear ? .systemGreen.withAlphaComponent(0.6) : .label.withAlphaComponent(0.6)
            
            cell.textLabel?.textColor = item.type == .destructive ? .systemRed.withAlphaComponent(0.6) : item.type == .clear ? .systemGreen.withAlphaComponent(0.6) : .label.withAlphaComponent(0.6)
            cell.isUserInteractionEnabled = false
        } else {
            cell.isUserInteractionEnabled = true
            if let icon = item.icon {
                cell.imageView?.image = UIImage(systemName: icon)
                cell.imageView?.tintColor = item.type == .destructive ? .systemRed : item.type == .clear ? .systemGreen : .label
            } else {
                cell.imageView?.image = nil
            }
            
            cell.textLabel?.textColor = item.type == .destructive ? .systemRed : item.type == .clear ? .systemGreen : .label
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Feedback rung nhẹ khi bấm
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        items[indexPath.row].action()
        
        if isSelectionMode {
            self.selectedIndex = indexPath.row
            self.didSelectItem?(indexPath.row) // Báo về Button
        }
        
        dismiss()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}
