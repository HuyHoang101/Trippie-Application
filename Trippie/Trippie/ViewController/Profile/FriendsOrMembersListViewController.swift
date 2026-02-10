//
//  FriendsOrMembersListViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit
import Combine

class FriendsOrMembersListViewController: FadeBaseViewController {
    

    var memberIds: [String]?
    var isPendingRequest: Bool?
    var isAllUser: Bool?
    var navigationTitle: String?
    
    private let viewModel = UserViewModel.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var displayData: [User] {
        let result = isAllUser ?? false ? viewModel.allUsers.value : (memberIds != nil) ? viewModel.profiles.value : viewModel.friendProfiles.value
        self.emptyState.isHidden = !(result.count == 0)
        return result
    }
    
    private let emptyState = UILabel.customLabel(text: "No member was found.", font: .systemFont(ofSize: 16), textColor: .secondaryLabel)
    
    private let tableView = UITableView()
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupTableView()
        bindLoading(to: viewModel.loading)
        
        let targetIds = memberIds ?? viewModel.myProfile.value?.friendIds ?? []
        if let i = self.isAllUser, i {
            viewModel.fetchAlluser()
        } else {
            viewModel.fetchUsers(ids: targetIds, isFriend: (memberIds == nil))
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    //MARK: - SETUP UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(emptyState)
        emptyState.isHidden = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyState.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyState.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none // Để row cell nhìn sạch hơn
        
        // Đăng ký Cell của bạn
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.identifier)
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let menuBtn = DropdownButton()
        
        // 2. Gán items
        menuBtn.items = [
            DropdownItem(title: "Add Task", icon: "plus", type: .normal) {
                
            },
            DropdownItem(title: "Delete Task", icon: "trash", type: .destructive) {
                print("Delete Task")
            }
        ]
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: menuBtn)
        
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItem = rightItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: - ACTION
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - BINDING
    private func setupBindings() {
        // 1. Xác định xem màn hình này đang cần data nào
        let targetPublisher: CurrentValueSubject<[User], Never>
        
        if memberIds != nil {
            // Case 1: Màn hình danh sách thành viên chuyến đi
            targetPublisher = viewModel.profiles
        } else if let isAll = isAllUser, isAll == true {
            // Case 2: Màn hình tìm kiếm tất cả user
            targetPublisher = viewModel.allUsers
        } else {
            // Case 3: Mặc định là danh sách bạn bè
            targetPublisher = viewModel.friendProfiles
        }
        
        // 2. Chỉ subscribe đúng 1 lần duy nhất
        targetPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - TABLEVIEW DATASOURCE & DELEGATE
extension FriendsOrMembersListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let user = displayData[indexPath.row]
        cell.configure(user: user)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // Chiều cao phù hợp cho Avatar 50pt + padding
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = displayData[indexPath.row]
        let anotherProfile = ProfileViewController()
        anotherProfile.anotherUserProfile = user
        self.navigationController?.pushViewController(anotherProfile, animated: true)
    }
}
