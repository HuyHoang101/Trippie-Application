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
    
    private let tripViewModel = TripViewModel.shared
    private let tripViewModel2 = TripFeedViewModel.shared

    var isFilter: Bool = false
    var isFilterMyTrip: Bool = false
   
    private let tableView = UITableView()
    private var cancellable = Set<AnyCancellable>()
    
    // Đã chỉnh lại để luôn trả về kiểu TripWithStatus
    private var displayData: [TripWithStatus] = []
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    
    
    // MARK: - PAGINATION PROPERTIES
    private var isFetchingHistory = false
    private var trippieLoadingView = TrippieLoadingView2()
    
    // MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTableView()
        setupNavBar()
        binding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    // MARK: - SETUP UI
    private func setupTableView() {
        if isFilterMyTrip {
            self.displayData = tripViewModel.filteredMyTrips.value
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        
        tableView.register(TripContainerCell.self, forCellReuseIdentifier: "TripContainerCell")
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 250
        
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
            trippieLoadingView.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
    
    private func setupNavBar() {
        if self.isFilter {
            navigationTitle = "Result: \(tripViewModel2.totalResultCount.value)"
        }
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
        // 1. Lắng nghe thay đổi CRUD (Chỉ reload đúng cell bị thay đổi)
        tripViewModel.didTapChange
            .sink { [weak self] changedID in
                RunLoop.main.perform {
                    guard let self = self else { return }
                    self.syncData(with: changedID)
                    
                    // Tìm vị trí của item vừa sync
                    if let index = self.displayData.firstIndex(where: { $0.trip.id == changedID }) {
                        // Cập nhật đúng 1 dòng với hiệu ứng mượt
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
            }
            .store(in: &cancellable)
        
        // 2. Lắng nghe data từ TripFeedViewModel (Khi isFilter = true)
        if isFilter {
            tripViewModel2.normalTrips
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newTrips in
                    guard let self = self else { return }
                    let searchText = self.tripViewModel2.searchText.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if searchText.isEmpty {
                        self.appendFeedData(newRawTrips: newTrips)
                        self.title = "Result: \(self.tripViewModel2.totalResultCount.value)"
                    }
                }
                .store(in: &cancellable)
            
            tripViewModel2.searchTrips
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newTrips in
                    guard let self = self else { return }
                    let searchText = self.tripViewModel2.searchText.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !searchText.isEmpty {
                        self.appendFeedData(newRawTrips: newTrips)
                        self.title = "Result: \(self.tripViewModel2.totalResultCount.value)"
                    }
                }
                .store(in: &cancellable)
        }
        
        if isFilterMyTrip {
            tripViewModel.filteredMyTrips
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newTrips in
                    self?.displayData = newTrips
                }
                .store(in: &cancellable)
        }
    }
    
    private func appendFeedData(newRawTrips: [Trip]) {
        let newData = newRawTrips.map { TripWithStatus(trip: $0, participation: nil) }
        let oldDataCount = self.displayData.count
        let newDataCount = newData.count
        
        // Ẩn loading ngay lập tức
        self.isFetchingHistory = false
        self.trippieLoadingView.isHidden = true
        
        // Kịch bản 1: Phân trang (Load thêm data ở đuôi)
        if newDataCount > oldDataCount && oldDataCount > 0 {
            let indexPaths = (oldDataCount..<newDataCount).map { IndexPath(row: $0, section: 0) }
            self.displayData = newData
            
            UIView.performWithoutAnimation {
                self.tableView.insertRows(at: indexPaths, with: .none)
            }
        }
        // Kịch bản 2: Lần đầu tiên kéo về, đổi filter, hoặc pull to refresh
        else {
            self.displayData = newData
            self.tableView.reloadData()
        }
    }
    
    private func syncData(with id: String) {
        if self.myTrip != nil {
            guard let index = self.myTrip?.firstIndex(where: { $0.trip.id == id }) else { return }
            if let freshItem = tripViewModel.myTrips.value.first(where: { $0.trip.id == id }) {
                self.myTrip?[index] = freshItem
            } else {
                self.myTrip?.remove(at: index)
            }
            return
        }
        
        if self.trip != nil {
            guard let index = self.trip?.firstIndex(where: { $0.id == id }) else { return }
            
            if let freshItem = tripViewModel.trips.value.first(where: { $0.id == id }) {
                self.trip?[index] = freshItem
            } else {
                self.trip?.remove(at: index)
            }
            return
        }
        
        if isFilterMyTrip {
            guard let index = self.tripViewModel.filteredMyTrips.value.firstIndex(where: { $0.trip.id == id }) else { return }
            if let freshItem = tripViewModel.myTrips.value.first(where: { $0.trip.id == id }) {
                self.displayData[index] = freshItem
            } else {
                self.displayData.remove(at: index)
            }
            return
        }
        
        if isFilter {
            guard let index = self.displayData.firstIndex(where: { $0.trip.id == id }) else { return }
            if let freshItem = tripViewModel.trips.value.first(where: { $0.id == id }) {
                self.displayData[index] = TripWithStatus(trip: freshItem, participation: nil)
            } else {
                self.displayData.remove(at: index)
            }
        }
    }
    
    private func formatData(from trip: [Trip]?) {
        self.displayData = trip?.map {
            TripWithStatus(trip: $0, participation: nil)
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
        cell.cellDidTap = { [weak self] in
            self?.pushToDetail(selectedTrip: item)
        }
        
        return cell
    }
    
    private func pushToDetail(selectedTrip: TripWithStatus) {
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
    
    // --- LOGIC CHẠM ĐÁY TỰ LOAD PAGINATION ---
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard isFilter else { return }
            guard displayData.count >= 8 else { return } // Tránh load khi data quá ít
            
            let offsetY = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let height = scrollView.frame.size.height
            
            
            if offsetY > 0 && (offsetY + height) >= (contentHeight - 5) && !isFetchingHistory && scrollView.isDragging {
                
                let searchText = tripViewModel2.searchText.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let isSearching = !searchText.isEmpty
                
                // Chặn lại nếu đã hết data
                if isSearching && tripViewModel2.isSearchEndReached { return }
                if !isSearching && tripViewModel2.isNormalEndReached { return }
                
                isFetchingHistory = true
                trippieLoadingView.isHidden = false
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isSearching {
                        self.tripViewModel2.loadNextSearchPage()
                    } else {
                        self.tripViewModel2.loadNextNormalPage()
                    }
                }
            }
        }
}
