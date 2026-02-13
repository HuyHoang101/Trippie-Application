//
//  FriendsOrMembersListViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/6/26.
//

import UIKit
import Combine

class FriendsOrMembersListViewController: FadeBaseViewController {
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    private var currentMode: ActionAceptPersonJoinTrip = .normal {
        didSet {
            for cell in tableView.visibleCells {
                if let userCell = cell as? UserCell {
                    userCell.updateMode(mode: currentMode)
                }
            }
        }
    }

    var memberIds: [String]?
    var tripDetail: Trip?
    var navigationTitle: String?
    var listType: UserListType?
    
    private let tripViewModel = TripViewModel.shared
    private let viewModel = UserViewModel.shared
    private var cancellables = Set<AnyCancellable>()
    private var displayData: [User] = []
    
    private let emptyState = UILabel.customLabel(text: "No member was found.", font: .systemFont(ofSize: 16), textColor: .secondaryLabel)
    
    private let tableView = UITableView()
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetOldData()
        
        setupUI()
        setupBindings()
        setupTableView()
        bindLoading(to: viewModel.loading)
        
        let targetIds = memberIds ?? viewModel.myProfile.value?.friendIds ?? []
        if let i = self.listType, i == .allUsers {
            viewModel.fetchAlluser()
        } else {
            viewModel.fetchUsers(ids: targetIds, isFriend: (memberIds == nil))
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        var dropDownItems: [DropdownItem] = []
        guard let type = self.listType else { return }
        switch type {
        case .allUsers, .friends, .tripMemberForAnotherLooking:
            break
        case .tripMembers:
            dropDownItems.append(DropdownItem(title: "Kick member", icon: "person.fill.badge.minus", type: .destructive) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .kick
            })
        case .pendingRequest:
            dropDownItems.append(DropdownItem(title: "Accept Requests", icon: "person.fill.checkmark", type: .clear) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .acept
            })
            dropDownItems.append(DropdownItem(title: "Deny Requests", icon: "person.fill.xmark", type: .destructive) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .deny
            })
        }
        dropDownItems.append(DropdownItem(title: "Cancel action", icon: "xmark", type: .destructive) { [weak self] in
            guard let self = self else { return }
            self.currentMode = .normal
        })
        menuBtn.items = dropDownItems
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: menuBtn)
        
        self.navigationItem.leftBarButtonItem = leftItem
        if type != .friends && type != .allUsers && type != .tripMemberForAnotherLooking {
            self.navigationItem.rightBarButtonItem = rightItem
        }
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
    
    @MainActor
    private func handleKickPerson(trip: Trip, userId: String, name: String) async -> Bool {
        let confirm = await confirmAlert(type: .kick, title: "\(name)?")
        
        if confirm {
            self.tripViewModel.kickMember(userId: userId, trip: trip)
            return true
        }
        return false
    }
    
    @MainActor
    private func handleAceptPerson(trip: Trip, userId: String, name: String) async -> Bool {
        let confirm = await confirmAlert(type: .add, title: "\(name)?")
        
        if confirm {
            self.tripViewModel.acceptJoinRequest(userId: userId, trip: trip)
            return true
        }
        return false
    }
    
    @MainActor
    private func handleDenyPerson(trip: Trip, userId: String, name: String) async -> Bool {
        let confirm = await confirmAlert(type: .deny, title: "\(name)?")
        
        if confirm {
            self.tripViewModel.denyJoinRequest(userId: userId, trip: trip)
            return true
        }
        return false
    }
    
    // MARK: - BINDING
    private func setupBindings() {
        // 1. Xác định xem màn hình này đang cần data nào
        let targetPublisher: CurrentValueSubject<[User], Never>
        guard let type = self.listType else { return }
        switch type {
        case .allUsers:
            targetPublisher = self.viewModel.allUsers
        case .tripMembers, .tripMemberForAnotherLooking, .pendingRequest:
            targetPublisher = self.viewModel.profiles
        case .friends:
            targetPublisher = self.viewModel.friendProfiles
        }
        
        // 2. Chỉ subscribe đúng 1 lần duy nhất
        targetPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                guard let self = self else { return }
                self.displayData = t
                self.emptyState.isHidden = !self.displayData.isEmpty
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        tripViewModel.didTapChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                guard let self = self else { return }
                self.tripDetail = tripViewModel.trips.value.first(where: {$0.id == t})
                print(tripDetail?.members ?? "")
                print(tripDetail?.pendingRequests ?? "")
            }
            .store(in: &cancellables)
    }
    
    // Hàm này giúp dọn dẹp data cũ của Singleton
    private func resetOldData() {
        // 1. Xóa trên UI trước
        self.displayData = []
        self.tableView.reloadData()
        
        // 2. Reset trong ViewModel (Để nó không bắn lại data cũ khi ta vừa subscribe)
        // Lưu ý: Cậu cần đảm bảo biến subjects trong ViewModel có thể .send() được (nếu là CurrentValueSubject)
        guard let type = self.listType else { return }
        switch type {
        case .allUsers:
            viewModel.allUsers.send([])
        case .tripMembers, .tripMemberForAnotherLooking, .pendingRequest:
            viewModel.profiles.send([])
        case .friends:
            viewModel.friendProfiles.send([])
        }
    }
}

// MARK: - TABLEVIEW DATASOURCE & DELEGATE
extension FriendsOrMembersListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < displayData.count else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        // Configure giao diện ban đầu
        let user = displayData[indexPath.row]
        cell.configure(user: user)
        cell.updateMode(mode: currentMode)
        cell.selectionStyle = .none
        
        // --- GÁN CLOSURE ACTION ---
        cell.onTapAction = { [weak self, weak cell] in
            guard let self = self, let currentCell = cell else { return }
            
            // 1. Lấy indexPath hiện tại CHÍNH XÁC từ tableView để tránh lỗi cell reuse
            guard let currentIndexPath = self.tableView.indexPath(for: currentCell) else { return }
            
            // 2. Lấy ĐÚNG user tại thời điểm bấm chứ không dùng biến user cũ ở trên
            let currentUser = self.displayData[currentIndexPath.row]
            
            guard let trip = self.tripDetail else { return }
            guard let userId = currentUser.id else { return }
            
            print("Đang xử lý đúng user: \(currentUser.name) - ID: \(userId)")

            Task {
                var isConfirmed = false
                
                // 3. Gọi API xử lý và đợi kết quả Confirm
                switch self.currentMode {
                case .acept:
                    isConfirmed = await self.handleAceptPerson(trip: trip, userId: userId, name: currentUser.name)
                case .deny:
                    isConfirmed = await self.handleDenyPerson(trip: trip, userId: userId, name: currentUser.name)
                case .kick:
                    isConfirmed = await self.handleKickPerson(trip: trip, userId: userId, name: currentUser.name)
                case .normal:
                    return
                }
                
                // 4. CHỈ XOÁ UI KHI ĐÃ CONFIRM (isConfirmed == true)
                if isConfirmed {
                    self.displayData.remove(at: currentIndexPath.row)
                    self.tableView.deleteRows(at: [currentIndexPath], with: .fade)
                }
            }
        }
        
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
