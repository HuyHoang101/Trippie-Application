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
    private var oldNotifications: [NotificationItem] = []
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    // MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        bindViewModel()
        setupNabBar()
        // Kéo data lần đầu
        viewModel.fetchInitialNotifications()
    }
    
    // MARK: - SETUP UI
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotifCell") // Thay bằng Custom Cell của cậu sau
        
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
                
                let oldDataCount = self.oldNotifications.count
                let newDataCount = newNotifications.count
                
                // 1. Phân trang (Load thêm data ở dưới đáy)
                if newDataCount > oldDataCount && oldDataCount > 0 {
                    let indexPaths = (oldDataCount..<newDataCount).map { IndexPath(row: $0, section: 0) }
                    self.oldNotifications = newNotifications
                    
                    UIView.performWithoutAnimation {
                        self.tableView.insertRows(at: indexPaths, with: .none)
                    }
                }
                // 2. Có sự thay đổi dữ liệu bên trong (Ví dụ: isRead đổi từ false -> true)
                else if newDataCount == oldDataCount && newDataCount > 0 {
                    var indexPathsToReload: [IndexPath] = []
                    
                    // So sánh mảng cũ và mới xem dòng nào bị thay đổi
                    for i in 0..<newDataCount {
                        if self.oldNotifications[i].isRead != newNotifications[i].isRead {
                            indexPathsToReload.append(IndexPath(row: i, section: 0))
                        }
                    }
                    
                    self.oldNotifications = newNotifications
                    
                    // Chỉ reload đúng cái dòng bị đổi màu với hiệu ứng mượt
                    if !indexPathsToReload.isEmpty {
                        self.tableView.reloadRows(at: indexPathsToReload, with: .fade)
                    }
                }
                // 3. Lần đầu tiên load data (Hoặc làm mới hoàn toàn)
                else {
                    self.oldNotifications = newNotifications
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotifCell", for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        
        let notif = viewModel.notifications[indexPath.row]
        
        cell.configure(with: notif)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Đánh dấu đã đọc và chuyển trang
        let notif = viewModel.notifications[indexPath.row]
        if let id = notif.id {
            viewModel.markAsRead(id: id)
        }
        let detailVC = DetailViewController()
        detailVC.navigationTitle = "Detail"
        detailVC.id = notif.tripId
        detailVC.isFeedBoard = notif.type == "status_change"
        self.navigationController?.pushViewController(detailVC, animated: true)
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
