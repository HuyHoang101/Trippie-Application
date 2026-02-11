//
//  ListViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//

import UIKit
import Combine

class ListViewController: FadeBaseViewController {
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    // MARK: - DATA
    var trip: [Trip]? {
        didSet {
            self.formatData(from: trip)
        }
    }
    
    var myTrip: [TripWithStatus]? {
        didSet {
            self.displayData = myTrip ?? []
            if isViewLoaded {
                self.tableView.reloadData()
            }
        }
    }
    
    var navigationTitle: String?
   
    private let tableView = UITableView()
    private var cancellable = Set<AnyCancellable>()
    
    // Đã chỉnh lại để luôn trả về kiểu TripWithStatus
    private var displayData: [TripWithStatus] = []
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    // MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTableView()
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    // MARK: - SETUP UI
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(TripContainerCell.self, forCellReuseIdentifier: "TripContainerCell")
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 250
        
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
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
        navigationController?.popViewController(animated: true)
    }
    
    private func binding() {
        TripViewModel.shared.didTapChange
            .sink { [weak self] changedID in
                RunLoop.main.perform {
                    self?.syncData(with: changedID)
                    self?.tableView.reloadData()
                }
            }
            .store(in: &cancellable)
    }
    
    private func syncData(with id: String) {
        if self.myTrip != nil {
            guard let index = self.myTrip?.firstIndex(where: { $0.trip.id == id }) else { return }
            if let freshItem = TripViewModel.shared.myTrips.value.first(where: { $0.trip.id == id }) {
                self.myTrip?[index] = freshItem
            } else {
                self.myTrip?.remove(at: index)
            }
            return
        }

        if self.trip != nil {
            guard let index = self.trip?.firstIndex(where: { $0.id == id }) else { return }
            
            if let freshItem = TripViewModel.shared.trips.value.first(where: { $0.id == id }) {
                self.trip?[index] = freshItem
            } else {
                self.trip?.remove(at: index)
            }
        }
    }
    
    private func formatData(from trip: [Trip]?) {
        self.displayData = trip?.map {
            TripWithStatus(trip: $0, participation: Participation(id: "", userId: "", tripId: "", personalStatus: .upcoming, role: .member))
        } ?? []
        if isViewLoaded {
            self.tableView.reloadData()
        }
    }
}

// MARK: - TABLEVIEW DATASOURCE
extension ListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TripContainerCell", for: indexPath) as? TripContainerCell else {
            return UITableViewCell()
        }
        
        let item = displayData[indexPath.row]
        
        cell.bindData(trip: item)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrip = displayData[indexPath.row]
        let detailVC = DetailViewController()
        detailVC.id = selectedTrip.trip.id
        detailVC.navigationTitle = "Detail: \(navigationTitle ?? selectedTrip.trip.location)"
        if let partId = selectedTrip.participation?.id, !partId.isEmpty {
            detailVC.isFeedBoard = false
        } else {
            detailVC.isFeedBoard = true
        }
        self.navigationController?.pushViewController(detailVC, animated: true)
        
    }
}
