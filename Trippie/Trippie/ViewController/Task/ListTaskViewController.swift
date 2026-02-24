//
//  ListTaskViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/4/26.
//
import UIKit
import Combine

class ListTaskViewController: FadeBaseViewController {
    var id: String?
    var navigationTitle: String?
    private var tripWithStatus: TripWithStatus?
    private let tripViewModel = TripViewModel.shared
    private let taskViewModel = TaskViewModel()
    private var displayData: [TaskOfTrip] = []
    private var currentMode: ListTaskMode = .normal {
        didSet {
            guard oldValue != currentMode else { return }
            
            // Thay vì reloadData(), ta chỉ animate những cell đang hiển thị
            guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
            
            let userId = AuthService.shared.currentUserId!
            let currentUserRole = tripWithStatus?.participation?.role
            
            for indexPath in indexPaths {
                guard let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell else { continue }
                let item = displayData[indexPath.row]
                
                // Logic phân quyền y chang trong cellForRowAt, nhưng bật animated = true
                if currentMode == .edit || currentMode == .normal {
                    cell.updateMode(mode: currentMode, animated: true)
                } else {
                    if currentUserRole == .owner || item.creatorId == userId {
                        cell.updateMode(mode: currentMode, animated: true)
                    } else {
                        cell.updateMode(mode: .normal, animated: true)
                    }
                }
            }
        }
    }
    private var cancellabel = Set<AnyCancellable>()
    
    //MARK: - UI COMPONENT
    private let ruleContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.authBackground2.cgColor
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowOpacity = 0.2
        v.layer.borderColor = UIColor.authBackground2.withAlphaComponent(0.5).cgColor
        v.layer.borderWidth = 0.5
        v.clipsToBounds = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let messageBtn = UIButton.customButton(image: UIImage(systemName: "message.fill"), backgroundColor: (UIColor.authBackground2.withAlphaComponent(0.5)))
    private let messageWrapper = UIView()
    
    private let ruleLabel = UILabel.customLabel(text: "Rule: Wellcome to our communication! Please be courteous with everyone. I will kick the spammers. Also this is place we will go :)", font: .systemFont(ofSize: 13), textColor: .label)
    private let ruleAuthor = UILabel.customLabel(text: "By Unknown User", font: .systemFont(ofSize: 12), textColor: .label)
    
    private let tableView = UITableView()
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    private let multipleChoice = UIButton.customButton(image: UIImage(systemName: "ellipsis"), backgroundColor: (UIColor.authBackground2.withAlphaComponent(0.5)))
    
    private let countLabel = UILabel.customLabel(text: "0", font: .systemFont(ofSize: 9, weight: .medium), textColor: .white)
    private let containerUI = UIView()
    private let commentViewModel = CommentViewModel()
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAction()
        binding()
        bindLoading(to: taskViewModel.loading)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        containerUI.addSubview(countLabel)
        taskViewModel.startListening(tripId: id ?? "")
        setupBackground()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskTableViewCell")
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 250
        
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        ruleLabel.numberOfLines = 0
        ruleLabel.textAlignment = .justified
        
        view.addSubview(ruleContainer)
        view.addSubview(tableView)
        ruleContainer.addSubview(ruleLabel)
        ruleContainer.addSubview(ruleAuthor)
        messageWrapper.addSubview(messageBtn)
        messageWrapper.addSubview(containerUI)
        containerUI.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ruleContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            ruleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ruleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ruleContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: -10),
            
            // ✅ 1. Ép cứng kích thước Wrapper an toàn tuyệt đối với Navigation Bar
            messageWrapper.widthAnchor.constraint(equalToConstant: 43),
            messageWrapper.heightAnchor.constraint(equalToConstant: 43),

            // ✅ 2. Neo nút xanh vào góc Dưới-Trái của Wrapper
            messageBtn.leadingAnchor.constraint(equalTo: messageWrapper.leadingAnchor, constant: 3),
            messageBtn.bottomAnchor.constraint(equalTo: messageWrapper.bottomAnchor, constant: -3),
            messageBtn.widthAnchor.constraint(equalToConstant: 36), // Nhỏ lại xíu để nhường chỗ
            messageBtn.heightAnchor.constraint(equalToConstant: 36),

            // ✅ 3. Neo cục đỏ vào góc Trên-Phải của Wrapper
            containerUI.trailingAnchor.constraint(equalTo: messageWrapper.trailingAnchor),
            containerUI.topAnchor.constraint(equalTo: messageWrapper.topAnchor),
            containerUI.widthAnchor.constraint(equalToConstant: 18),
            containerUI.heightAnchor.constraint(equalToConstant: 18),
            
            countLabel.centerXAnchor.constraint(equalTo: containerUI.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: containerUI.centerYAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ruleLabel.topAnchor.constraint(equalTo: ruleContainer.topAnchor, constant: 12),
            ruleLabel.leadingAnchor.constraint(equalTo: ruleContainer.leadingAnchor, constant: 20),
            ruleLabel.trailingAnchor.constraint(equalTo: ruleContainer.trailingAnchor, constant: -20),
            ruleLabel.bottomAnchor.constraint(equalTo: ruleAuthor.safeAreaLayoutGuide.topAnchor, constant: -10),
            
            ruleAuthor.trailingAnchor.constraint(equalTo: ruleContainer.trailingAnchor, constant: -20),
            ruleAuthor.bottomAnchor.constraint(equalTo: ruleContainer.bottomAnchor, constant: -12)
        ])
        
        renderTask()
        renderRule()
        setupNavBar()
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let menuBtn = DropdownButton()
        
        // 2. Gán items
        menuBtn.items = [
            DropdownItem(title: "Add Task", icon: "plus", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.handlepushToCreateTask()
            },
            DropdownItem(title: "Edit Task", icon: "pencil.line", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .edit
            },
            DropdownItem(title: "Delete Task", icon: "trash", type: .destructive) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .delete
            },
            DropdownItem(title: "Cancel Action", icon: "xmark", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.currentMode = .normal
            }
        ]
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: menuBtn)
        let rightItem2 = UIBarButtonItem(customView: messageWrapper)
        
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItems = [rightItem, rightItem2]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func renderTask() {
        displayData = taskViewModel.tasks.value
    }
    
    private func renderRule() {
        guard let id = self.id else { return }
        guard let trip = tripViewModel.myTrips.value.first(where: { $0.trip.id == id }) else  { return }
        self.commentViewModel.joinChatRoom(tripId: id)
        self.commentViewModel.fetchAllImage(tripId: id)
        self.commentViewModel.fetchAllVideo(tripId: id)
        ChatStateManager.shared.startListening(tripId: id)
        containerUI.isHidden = true
        containerUI.backgroundColor = .systemRed
        containerUI.layer.cornerRadius = 9
        self.tripWithStatus = trip
        
        ruleAuthor.text = "By \(trip.trip.ownerName)"
        
        let ruleValue = trip.trip.tripRule ?? "None"

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13)
        ]
        let attributedText = NSMutableAttributedString(string: "Rule: ", attributes: boldAttributes)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13)
        ]
        let normalText = NSAttributedString(string: ruleValue, attributes: normalAttributes)

        // Nối lại và gán
        attributedText.append(normalText)
        ruleLabel.attributedText = attributedText
    }
    
    private func setupCountLabel() {
        let count = commentViewModel.newMessagesCount.value
        if count > 0 {
            containerUI.isHidden = false
            if count < 100 {
                countLabel.text = "\(count)"
            } else {
                countLabel.text = "99+"
            }
        } else {
            containerUI.isHidden = true
        }
    }
    
    
    //MARK: - SETUP ACTION
    private func setupAction() {
        messageBtn.addTarget(self, action: #selector(didTapView), for: .touchUpInside)
    }
    
    @objc private func handleBack() {
        self.commentViewModel.newMessagesCount.send(0)
        self.commentViewModel.leaveChatRoom()
        guard let id = self.id else { return }
        ChatStateManager.shared.stopListening(tripId: id)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handlepushToCreateTask() {
        let creatTaskVC = HandsaveTask()
        creatTaskVC.id = self.id
        creatTaskVC.userRole = tripWithStatus?.participation?.role
        creatTaskVC.viewModel = taskViewModel
        self.navigationController?.pushViewController(creatTaskVC, animated: true)
    }
    
    @objc private func didTapView() {
        guard let tripWithStatus = tripViewModel.myTrips.value.first(where: { $0.trip.id == id }) else  { return }
        let vc = GroupMessageViewController()
        guard let trip = self.tripWithStatus?.trip else { return }
        vc.tripId = trip.id
        vc.navigationTitle = "\(trip.location), \(trip.country)"
        vc.commentViewModel = self.commentViewModel
        vc.tripWithStatus = tripWithStatus
        self.navigationController?.pushViewController(vc, animated: true)
        self.commentViewModel.newMessagesCount.send(0)
    }
    
    private func handleEditAction(task: TaskOfTrip) {
        let editTaskVC = HandsaveTask()
        editTaskVC.id = self.id
        editTaskVC.userRole = tripWithStatus?.participation?.role
        editTaskVC.viewModel = taskViewModel
        
        self.taskViewModel.editingTask.send(task)
        
        self.navigationController?.pushViewController(editTaskVC, animated: true)
        
        self.currentMode = .normal
    }
    
    @MainActor
    private func handleDeleteAction(task: TaskOfTrip) async {
        guard let tripId = self.id, let taskId = task.id else { return }
        
        let confirm = await confirmAlert(type: .delete, title: "task Day \(task.dayIndex) - \(task.time)?")
        
        if confirm {
            self.taskViewModel.deleteTask(tripId: tripId, taskId: taskId)
            self.currentMode = .normal
        } else {
            return
        }
    }
    
    //MARK: - BINDING
    private func binding() {
        taskViewModel.tasks
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                guard let self = self else { return }
                                // Gọi hàm update thông minh
                self.updateTableViewSmartly(newTasks: t)
            }
            .store(in: &cancellabel)
        
        commentViewModel.newMessagesCount
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupCountLabel()
            }
            .store(in: &cancellabel)
    }
    
    private func updateTableViewSmartly(newTasks: [TaskOfTrip]) {
        let oldTasks = displayData
        
        // 1. Lần đầu load data (Data cũ rỗng) -> Reload thường
        if oldTasks.isEmpty {
            self.displayData = newTasks
            self.tableView.reloadData()
            return
        }
        
        // 2. Tính toán sự thay đổi (Insert / Delete) dựa trên ID
        // Yêu cầu: TaskOfTrip phải có id duy nhất
        // VD: [A,B,C] [A,C,D]
        // change: xoá b vị trí 1, thêm d vị trí 2
        let changes = newTasks.difference(from: oldTasks) { $0.id == $1.id }
        
        // 3. Thực hiện update theo lô (Batch Updates) để mượt và giữ vị trí cuộn
        self.tableView.performBatchUpdates({
            // Cập nhật nguồn dữ liệu MỚI
            self.displayData = newTasks
            
            for change in changes {
                switch change {
                case .remove(let offset, _, _):
                    // Xoá dòng cũ (Animation fade để mượt)
                    self.tableView.deleteRows(at: [IndexPath(row: offset, section: 0)], with: .fade)
                    
                case .insert(let offset, _, _):
                    // Thêm dòng mới
                    self.tableView.insertRows(at: [IndexPath(row: offset, section: 0)], with: .fade)
                }
            }
        }, completion: { _ in
            // 4. Xử lý phần EDIT (Nội dung thay đổi nhưng ID giữ nguyên)
            // Logic: Sau khi thêm/xoá xong, check xem có dòng nào ID giống nhau nhưng nội dung khác nhau không
            
            var indexPathsToReload: [IndexPath] = []
            
            for (index, newTask) in newTasks.enumerated() {
                // Tìm task cũ có cùng ID (nếu tồn tại)
                if let oldTask = oldTasks.first(where: { $0.id == newTask.id }) {
                    
                    // So sánh các trường quan trọng để xem có cần reload không
                    // Ví dụ: title, time, updatedAt, hoặc status
                    if oldTask.updatedAt != newTask.updatedAt ||
                       oldTask.dayIndex != newTask.dayIndex ||
                       oldTask.time != newTask.time ||
                       oldTask.status != newTask.status {
                        
                        indexPathsToReload.append(IndexPath(row: index, section: 0))
                    }
                }
            }
            
            // Reload nhẹ nhàng các dòng bị sửa (với animation .none để không bị chớp)
            if !indexPathsToReload.isEmpty {
                self.tableView.reloadRows(at: indexPathsToReload, with: .none)
            }
        })
    }
}


// MARK: - TABLEVIEW DATASOURCE
extension ListTaskViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as? TaskTableViewCell else {
            return UITableViewCell()
        }
        
        let item = displayData[indexPath.row]
        let userId = AuthService.shared.currentUserId!
        
        cell.configure(with: item, id: userId)
        let currentUserRole = tripWithStatus?.participation?.role
                
        if currentMode == .edit || currentMode == .normal {
            cell.updateMode(mode: currentMode, animated: false)
        } else {
            if currentUserRole == .owner || item.creatorId == userId {
                cell.updateMode(mode: currentMode, animated: false)
            } else {
                cell.updateMode(mode: .normal, animated: false) // Giấu nút xoá đi
            }
        }
        cell.onTapAction = { [weak self] in
            guard let self = self else { return }
            if self.currentMode == .edit {
                self.handleEditAction(task: item)
            } else if self.currentMode == .delete {
                Task {
                    await self.handleDeleteAction(task: item)
                }
            }
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if currentMode != .normal { return }
        let row = displayData[indexPath.row]
        let vc = TaskDetailModalViewController()
        vc.task = row
        vc.viewModel = self.taskViewModel
        vc.participation = self.tripWithStatus?.participation
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        
        self.present(vc, animated: true)
    }
}
