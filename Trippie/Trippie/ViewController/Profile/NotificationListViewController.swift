//
//  NotificationListViewController.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 19/2/26.
//

import UIKit
import Combine

class NotificationListViewController: UIViewController { // Có thể đổi thành FadeBaseViewController nếu cậu muốn
    
    private let tableView = UITableView()
    private let viewModel = NotificationViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - PAGINATION PROPERTIES
    private var isFetchingHistory = false
    private let trippieLoadingView = TrippieLoadingView2() // Con quay xịn xò của cậu
    private var oldDataCount = 0
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    // MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        bindViewModel()
        
        // Kéo data lần đầu
        viewModel.fetchInitialNotifications()
    }
    
    // MARK: - SETUP UI
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotifCell") // Thay bằng Custom Cell của cậu sau
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(trippieLoadingView)
        trippieLoadingView.isHidden = true
        trippieLoadingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            trippieLoadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trippieLoadingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            trippieLoadingView.widthAnchor.constraint(equalToConstant: 36),
            trippieLoadingView.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    
    private func setupNabBar() {
        self.title = "Notification"
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let leftItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = leftItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - BINDING
    private func bindViewModel() {
        // Lắng nghe mảng data để Update TableView
        viewModel.$notifications
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newNotifications in
                guard let self = self else { return }
                
                let newDataCount = newNotifications.count
                
                // Nếu là load thêm (Phân trang) -> Dùng insertRows cho mượt
                if newDataCount > self.oldDataCount && self.oldDataCount > 0 {
                    let indexPaths = (self.oldDataCount..<newDataCount).map { IndexPath(row: $0, section: 0) }
                    self.oldDataCount = newDataCount
                    
                    UIView.performWithoutAnimation {
                        self.tableView.insertRows(at: indexPaths, with: .none)
                    }
                }
                // Lần đầu tiên load
                else {
                    self.oldDataCount = newDataCount
                    self.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        // Lắng nghe cờ isFetchingMore để ẩn Loading View
        viewModel.$isFetchingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                if !isFetching {
                    self?.isFetchingHistory = false
                    self?.trippieLoadingView.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - TABLEVIEW DATASOURCE & DELEGATE
extension NotificationListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath)
        let notif = viewModel.notifications[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = notif.title
        content.secondaryText = notif.body
        cell.contentConfiguration = content
        
        // Highlight thông báo chưa đọc
        cell.backgroundColor = notif.isRead ? .clear : .systemBlue.withAlphaComponent(0.1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Đánh dấu đã đọc và chuyển trang
    }
    
    // --- LOGIC CHẠM ĐÁY TỰ LOAD PAGINATION CỦA CẬU ---
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.notifications.count >= 10 else { return } // Tránh load khi data quá ít
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > 0 && (offsetY + height) >= (contentHeight - 5) && !isFetchingHistory && scrollView.isDragging {
            
            // Chặn lại nếu đã hết data trên Server
            if viewModel.isEndReached { return }
            
            // Bật cờ và hiện loading
            isFetchingHistory = true
            trippieLoadingView.isHidden = false
            
            // Delay nhẹ tạo cảm giác mượt mà
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewModel.loadNextPage()
            }
        }
    }
}
