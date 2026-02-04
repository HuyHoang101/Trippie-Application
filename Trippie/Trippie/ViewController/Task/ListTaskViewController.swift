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
    private let tripViewModel = TripViewModel.shared
    private let taskViewModel = TaskViewModel()
    private var displayData: [TaskOfTrip] = []
    private var cancellabel = Set<AnyCancellable>()
    
    //MARK: - UI COMPONENT
    private let ruleContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowOpacity = 0.1
        v.clipsToBounds = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let ruleLabel = UILabel.customLabel(text: "Rule: Wellcome to our communication! Please be courteous with everyone. I will kick the spammers. Also this is place we will go :)", font: .systemFont(ofSize: 13), textColor: .label)
    private let ruleAuthor = UILabel.customLabel(text: "By Unknown User", font: .systemFont(ofSize: 12), textColor: .label)
    
    private let tableView = UITableView()
    
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAction()
        binding()
        bindLoading(to: taskViewModel.loading)
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
        
        view.addSubview(ruleContainer)
        view.addSubview(tableView)
        ruleContainer.addSubview(ruleLabel)
        ruleContainer.addSubview(ruleAuthor)
        
        NSLayoutConstraint.activate([
            ruleContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            ruleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            ruleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            ruleContainer.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -10),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ruleLabel.topAnchor.constraint(equalTo: ruleContainer.topAnchor, constant: 20),
            ruleLabel.leadingAnchor.constraint(equalTo: ruleContainer.leadingAnchor, constant: 20),
            ruleLabel.trailingAnchor.constraint(equalTo: ruleContainer.trailingAnchor, constant: -20),
            ruleLabel.bottomAnchor.constraint(equalTo: ruleAuthor.topAnchor, constant: -10),
            
            ruleAuthor.trailingAnchor.constraint(equalTo: ruleContainer.trailingAnchor, constant: -20),
            ruleAuthor.bottomAnchor.constraint(equalTo: ruleContainer.bottomAnchor, constant: 20)
        ])
        
        renderTask()
        renderRule()
    }
    
    private func renderTask() {
        displayData = taskViewModel.tasks.value
    }
    
    private func renderRule() {
        guard let id = self.id else { return }
        guard let trip = tripViewModel.myTrips.value.first(where: { $0.trip.id == id }) else  { return }
        
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
    
    
    
    //MARK: - BINDING
    private func binding() {
        
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
        
        cell.configure(with: item)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrip = displayData[indexPath.row]
        
    }
}
