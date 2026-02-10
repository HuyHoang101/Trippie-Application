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
    private var displayData: [TaskOfTrip] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    private var currentMode: ListTaskMode = .normal {
        didSet {
            tableView.reloadData() // Mỗi khi đổi mode thì reload lại bảng để hiện icon
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
    
    private let ruleLabel = UILabel.customLabel(text: "Rule: Wellcome to our communication! Please be courteous with everyone. I will kick the spammers. Also this is place we will go :)", font: .systemFont(ofSize: 13), textColor: .label)
    private let ruleAuthor = UILabel.customLabel(text: "By Unknown User", font: .systemFont(ofSize: 12), textColor: .label)
    
    private let tableView = UITableView()
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    private let multipleChoice = UIButton.customButton(image: UIImage(systemName: "ellipsis"), backgroundColor: (UIColor.authBackground2.withAlphaComponent(0.5)))
    
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
        taskViewModel.fetchTask(tripId: id ?? "")
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
        
        NSLayoutConstraint.activate([
            ruleContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            ruleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            ruleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            ruleContainer.bottomAnchor.constraint(equalTo: tableView.topAnchor, constant: -10),
            
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
        
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItem = rightItem
        
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
    
    
    
    //MARK: - SETUP ACTION
    private func setupAction() {
        
    }
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handlepushToCreateTask() {
        let creatTaskVC = HandsaveTask()
        creatTaskVC.id = self.id
        creatTaskVC.userRole = tripWithStatus?.participation?.role
        creatTaskVC.viewModel = taskViewModel
        self.navigationController?.pushViewController(creatTaskVC, animated: true)
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
            .receive(on: RunLoop.main)
            .sink { [weak self] t in
                self?.displayData = t
            }
            .store(in: &cancellabel)
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
        if currentMode == .edit || currentMode == .normal {
            cell.updateMode(mode: currentMode)
        } else {
            if item.userRole == .owner || item.creatorId == userId {
                cell.updateMode(mode: currentMode)
            } else {
                cell.updateMode(mode: .normal)
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
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        
        self.present(vc, animated: true)
    }
}
