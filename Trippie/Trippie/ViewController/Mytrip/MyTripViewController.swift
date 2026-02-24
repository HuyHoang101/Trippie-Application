//
//  MyTripViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class MyTripViewController: FadeBaseViewController {
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    private var viewModel = TripViewModel.shared
    private var cancellable = Set<AnyCancellable>()
    
    //MARK: - UI COMPONENT
    private let mainscroll = UIScrollView()
    
    private let subscroll = UIScrollView()
    private let subscroll1 = UIScrollView()
    private let subscroll2 = UIScrollView()
    private let subscroll3 = UIScrollView()
    
    private let hstack = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    private let hstack1 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    private let hstack2 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    private let hstack3 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    
    private let maincontent = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 0)
    
    private lazy var searchBar = UITextField.createInput(placeholder: "Searching...", iconName: "magnifyingglass") { [weak self] in
        self?.didTapSearch()
    }
    
    
    private let filterStack = UIStackView.customStack(xPadding: 12, yPadding: 20, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    
    private let label4 = UILabel.customLabel(text: "Your Trips on Feed board", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    private let label1 = UILabel.customLabel(text: "Current Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    private let label2 = UILabel.customLabel(text: "My Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    private let label3 = UILabel.customLabel(text: "Joined Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    
    private let viewAllButton1 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    private let viewAllButton2 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    private let viewAllButton3 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    private let viewAllButton4 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    
    private let hstack4 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    private let hstack5 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    private let hstack6 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    private let hstack7 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    
    private let label = UILabel.customLabel(text: "Travel Experience", font: AppTheme.Font.mainBold(size: 24), textColor: .label)
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        bindLoading(to: viewModel.loading)
        setupUI()
        setupAction()
        binding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    //MARK: - SETUP UI
    func setupUI() {
        setupBackground()
        viewModel.fetchMyTrips()
        searchBar.clipsToBounds = false
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowRadius = 3
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 0)
        searchBar.layer.shadowOpacity = 0.15
            
        view.addSubview(mainscroll)
        mainscroll.addSubview(maincontent)
        mainscroll.delegate = self
        mainscroll.alwaysBounceVertical = true
            
        // Đảm bảo tính năng bounce đang bật
        mainscroll.bounces = true
        
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])

        
        maincontent.addArrangedSubview(filterStack)
        maincontent.addArrangedSubview(hstack7)
        maincontent.addArrangedSubview(subscroll)
        maincontent.addArrangedSubview(hstack4)
        maincontent.addArrangedSubview(subscroll1)
        maincontent.addArrangedSubview(container)
        maincontent.addArrangedSubview(hstack5)
        maincontent.addArrangedSubview(subscroll2)
        maincontent.addArrangedSubview(hstack6)
        maincontent.addArrangedSubview(subscroll3)
        
        filterStack.addArrangedSubview(searchBar)
        
        hstack4.addArrangedSubview(label1)
        hstack4.addArrangedSubview(viewAllButton1)
        
        hstack5.addArrangedSubview(label2)
        hstack5.addArrangedSubview(viewAllButton2)
        
        hstack6.addArrangedSubview(label3)
        hstack6.addArrangedSubview(viewAllButton3)
        
        hstack7.addArrangedSubview(label4)
        hstack7.addArrangedSubview(viewAllButton4)
        
        subscroll.addSubview(hstack)
        subscroll1.addSubview(hstack1)
        subscroll2.addSubview(hstack2)
        subscroll3.addSubview(hstack3)
        
        mainscroll.translatesAutoresizingMaskIntoConstraints = false
        subscroll.translatesAutoresizingMaskIntoConstraints = false
        subscroll1.translatesAutoresizingMaskIntoConstraints = false
        subscroll2.translatesAutoresizingMaskIntoConstraints = false
        subscroll3.translatesAutoresizingMaskIntoConstraints = false
        
        mainscroll.showsVerticalScrollIndicator = false
                
        // Dùng vòng lặp gộp chung cấu hình cho cả 4 subscroll cực kỳ gọn gàng
        [subscroll, subscroll1, subscroll2, subscroll3].forEach { scroll in
            scroll.showsHorizontalScrollIndicator = false
            scroll.showsVerticalScrollIndicator = false
            
            // 1. Tắt bỏ "khoảng đệm tàng hình" mặc định của Apple
            scroll.contentInsetAdjustmentBehavior = .never
            
            // 2. Chặn đứng tính năng nảy lên xuống
            scroll.alwaysBounceVertical = false
            
            // 3. KHÓA HƯỚNG VUỐT: Đã vuốt ngang thì cấm tuyệt đối nhúc nhích dọc
            scroll.isDirectionalLockEnabled = true
        }
        
        NSLayoutConstraint.activate([
            mainscroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainscroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainscroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainscroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            maincontent.topAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.topAnchor),
            maincontent.leadingAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.leadingAnchor),
            maincontent.trailingAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.trailingAnchor),
            maincontent.bottomAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.bottomAnchor, constant: -10),
            
            maincontent.widthAnchor.constraint(equalTo: mainscroll.widthAnchor),
            
            hstack.topAnchor.constraint(equalTo: subscroll.contentLayoutGuide.topAnchor),
            hstack.leadingAnchor.constraint(equalTo: subscroll.contentLayoutGuide.leadingAnchor),
            hstack.trailingAnchor.constraint(equalTo: subscroll.contentLayoutGuide.trailingAnchor),
            hstack.bottomAnchor.constraint(equalTo: subscroll.contentLayoutGuide.bottomAnchor),
            subscroll.heightAnchor.constraint(equalTo: hstack.heightAnchor), // Đảo ngược: Ép ScrollView cao bằng nội dung
            subscroll.contentLayoutGuide.heightAnchor.constraint(equalTo: subscroll.frameLayoutGuide.heightAnchor), // Khóa chết trục dọc không cho vuốt
            
            hstack1.topAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.topAnchor),
            hstack1.leadingAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.leadingAnchor),
            hstack1.trailingAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.trailingAnchor),
            hstack1.bottomAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.bottomAnchor),
            subscroll1.heightAnchor.constraint(equalTo: hstack1.heightAnchor), // Đảo ngược: Ép ScrollView cao bằng nội dung
            subscroll1.contentLayoutGuide.heightAnchor.constraint(equalTo: subscroll1.frameLayoutGuide.heightAnchor), // Khóa chết trục dọc không cho vuốt
            
            hstack2.topAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.topAnchor),
            hstack2.leadingAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.leadingAnchor),
            hstack2.trailingAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.trailingAnchor),
            hstack2.bottomAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.bottomAnchor),
            subscroll2.heightAnchor.constraint(equalTo: hstack2.heightAnchor), // Đảo ngược: Ép ScrollView cao bằng nội dung
            subscroll2.contentLayoutGuide.heightAnchor.constraint(equalTo: subscroll2.frameLayoutGuide.heightAnchor), // Khóa chết trục dọc không cho vuốt
            
            hstack3.topAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.topAnchor),
            hstack3.leadingAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.leadingAnchor),
            hstack3.trailingAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.trailingAnchor),
            hstack3.bottomAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.bottomAnchor),
            subscroll3.heightAnchor.constraint(equalTo: hstack3.heightAnchor), // Đảo ngược: Ép ScrollView cao bằng nội dung
            subscroll3.contentLayoutGuide.heightAnchor.constraint(equalTo: subscroll3.frameLayoutGuide.heightAnchor), // Khóa chết trục dọc không cho vuốt
            
            searchBar.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        render()
        setupNavBar()
    }
    
    func render() {
        let tripOnFeedBoard = Array(viewModel.myTrips.value.filter {
            $0.trip.status != .completed &&
            $0.participation?.role == .owner
        })
        let currentTrips = Array(viewModel.myTrips.value.filter {
            let isActive = $0.participation?.personalStatus != .cancel &&
            $0.participation?.personalStatus != .completed
            let role = $0.participation?.role
            let isRoleMatch = (role == .owner && $0.trip.status == .completed) || (role == .member)
            
            return isActive && isRoleMatch
        })
        let myTrips = Array(viewModel.myTrips.value.filter {
            ($0.participation?.personalStatus == .cancel || $0.participation?.personalStatus == .completed) &&
            $0.participation?.role == .owner &&
            $0.trip.status == .completed
        })

        let joinTrips = Array(viewModel.myTrips.value.filter {
            ($0.participation?.personalStatus == .cancel || $0.participation?.personalStatus == .completed) &&
            $0.participation?.role == .member
        })
        
        hstack.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        hstack1.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        hstack2.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        hstack3.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        
        if tripOnFeedBoard.count == 0 {
            hstack7.isHidden = true
            hstack.isHidden = true
        } else {
            hstack7.isHidden = false
            hstack.isHidden = false
            let trip = tripOnFeedBoard.prefix(5)
            trip.forEach { t in
                let card = TripCardView()
                card.configure(mytrip: t, isOnFeedBoard: true)
                hstack.addArrangedSubview(card)
                card.translatesAutoresizingMaskIntoConstraints = false
                card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true
                card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8).isActive = true
                
                card.didTapCard = { [weak self] in
                    self?.pushToDetail(tripId: t.id)
                }
            }
        }
        
        if currentTrips.count == 0 {
            viewAllButton1.isHidden = true
            let emptyCard = UIView()
            hstack1.addArrangedSubview(emptyCard)
            emptyCard.layer.cornerRadius = 12
            emptyCard.clipsToBounds = true
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
            emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
            
            let emptylabel = UILabel.customLabel(text: "There isn't any plan now. Go to feed board to find out or create a new one.", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
            emptylabel.numberOfLines = 0
            emptyCard.addSubview(emptylabel)
            emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
            emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
            emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
            
            self.view.layoutIfNeeded()
            emptyCard.addDashedBorder()
        } else {
            viewAllButton1.isHidden = false
            let trip = currentTrips.prefix(5)
            trip.forEach { t in
                let card = TripCardView()
                card.configure(mytrip: t)
                hstack1.addArrangedSubview(card)
                card.translatesAutoresizingMaskIntoConstraints = false
                card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true
                card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8).isActive = true
                
                card.didTapCard = { [weak self] in
                    self?.pushToDetail(tripId: t.id)
                }
                
                card.didTapStatus = { [weak self] in
                    guard let part = t.participation else { return }
                    self?.openUpdateStatus(part)
                }
            }
        }
        
        
        let hasMyTrips = !myTrips.isEmpty
        let hasJoinTrips = !joinTrips.isEmpty
        
        // --- XỬ LÝ MY TRIPS ---
        if hasMyTrips {
            hstack5.isHidden = false     // Hiện thanh tiêu đề "My Trips"
            subscroll2.isHidden = false  // Hiện thanh cuộn
            
            let trip = myTrips.prefix(5)
            trip.forEach { t in
                let card = TripCardView()
                card.configure(mytrip: t)
                hstack2.addArrangedSubview(card)
                card.translatesAutoresizingMaskIntoConstraints = false
                card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true
                card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8).isActive = true
                
                card.didTapCard = { [weak self] in
                    self?.pushToDetail(tripId: t.id)
                }
                card.didTapStatus = { [weak self] in
                    guard let part = t.participation else { return }
                    self?.openUpdateStatus(part)
                }
            }
        } else {
            // Ẩn toàn bộ để UIStackView (maincontent) tự động thu gọn khoảng trống
            hstack5.isHidden = true
            subscroll2.isHidden = true
        }
        
        // --- XỬ LÝ JOINED TRIPS ---
        if hasJoinTrips {
            hstack6.isHidden = false     // Hiện thanh tiêu đề "Joined Trips"
            subscroll3.isHidden = false  // Hiện thanh cuộn
            
            let trip = joinTrips.prefix(5)
            trip.forEach { t in
                let card = TripCardView()
                card.configure(mytrip: t)
                hstack3.addArrangedSubview(card)
                card.translatesAutoresizingMaskIntoConstraints = false
                card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true
                card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8).isActive = true
                
                card.didTapCard = { [weak self] in
                    self?.pushToDetail(tripId: t.id)
                }
                card.didTapStatus = { [weak self] in
                    guard let part = t.participation else { return }
                    self?.openUpdateStatus(part)
                }
            }
        } else {
            // Ẩn toàn bộ
            hstack6.isHidden = true
            subscroll3.isHidden = true
        }
        
        // --- XỬ LÝ EMPTY STATE (Cả My Trips và Joined Trips đều rỗng) ---
        if !hasMyTrips && !hasJoinTrips {
            subscroll2.isHidden = false // Mở lại subscroll2 để chứa empty card
            
            let emptyCard = UIView()
            hstack2.addArrangedSubview(emptyCard)
            emptyCard.layer.cornerRadius = 12
            emptyCard.clipsToBounds = true
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
            emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
            
            let emptylabel = UILabel.customLabel(text: "You haven't completed any trip before.", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
            emptyCard.addSubview(emptylabel)
            emptylabel.numberOfLines = 0
            emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
            emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
            emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
            
            self.view.layoutIfNeeded()
            emptyCard.addDashedBorder()
        }
    }
    
    private func setupNavBar() {
        self.title = "My trips"
        
        let config = UIImage.SymbolConfiguration(weight: .semibold)

        let plusImage = UIImage(systemName: "plus", withConfiguration: config)

        let addButton = UIBarButtonItem(
            image: plusImage,
            style: .plain,
            target: self,
            action: #selector(handleAdd)
        )

        addButton.tintColor = .authBackground2
        self.navigationItem.rightBarButtonItem = addButton
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    //MARK: - SETUP ACTION
    func setupAction() {
        viewAllButton1.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
        viewAllButton2.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
        viewAllButton3.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
        viewAllButton4.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
    }
    
    @objc private func didTapSearch() {
        let vc = ListViewController()
        vc.navigationTitle = "Search: \(self.searchBar.text ?? "None")"
        vc.isFilterMyTrip = true
        viewModel.searchTextMyTrip.send(searchBar.text ?? "")
        self.navigationController?.pushViewController(vc, animated: true)
        searchBar.text = ""
    }
    
    @objc private func pushToLish(_ render: UIButton) {
        let listVC = ListViewController()
        
        switch render {
        case viewAllButton1:
            listVC.navigationTitle = "Current Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                let isActive = $0.participation?.personalStatus != .cancel &&
                $0.participation?.personalStatus != .completed
                let role = $0.participation?.role
                let isRoleMatch = (role == .owner && $0.trip.status == .completed) || (role == .member)
                
                return isActive && isRoleMatch
            }
        case viewAllButton2:
            listVC.navigationTitle = "My Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                ($0.participation?.personalStatus == .completed || $0.participation?.personalStatus == .cancel) &&
                $0.participation?.role == .owner &&
                $0.trip.status == .completed
            }
        case viewAllButton3:
            listVC.navigationTitle = "Joined Trips"
            // Sửa lại cho đồng bộ với logic ở render()
            listVC.myTrip = viewModel.myTrips.value.filter {
                ($0.participation?.personalStatus == .completed || $0.participation?.personalStatus == .cancel) &&
                $0.participation?.role == .member
            }
        default:
            listVC.navigationTitle = "My Trips on Feed Board"
            listVC.myTrip = viewModel.myTrips.value.filter {
                $0.participation?.role == .owner &&
                $0.trip.status != .completed
            }
            
        }
        navigationController?.pushViewController(listVC, animated: true)
    }
    
    private func openUpdateStatus(_ currentUserParticipation: Participation) {
        let modalVC = StatusModalViewController()
        modalVC.participation = currentUserParticipation // Chuyền cái struct Participation vào đây
        modalVC.modalPresentationStyle = .overFullScreen // Cực kỳ quan trọng để nền đen mờ hiển thị đúng
        modalVC.modalTransitionStyle = .crossDissolve

        self.present(modalVC, animated: false)
    }
    
    
    @objc private func handleAdd() {
        let formVC = HandSaveTrip()
        
        formVC.viewModel = self.viewModel
        self.navigationController?.pushViewController(formVC, animated: true)
    }
    
    private func pushToDetail(tripId: String) {
        let detailVC = DetailViewController()
        detailVC.id = tripId
        detailVC.navigationTitle = "Detail"
        detailVC.isFeedBoard = false
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    //MARK: - Binding
    private func binding() {
        viewModel.myTrips
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellable)
    }
}

extension MyTripViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Kiểm tra nếu là mainScroll và người dùng kéo xuống một khoảng (ví dụ -100)
        let offset = scrollView.contentOffset.y
        if offset < -70 {
            handleRefreshData()
        }
    }
    
    private func handleRefreshData() {

        self.viewModel.fetchMyTrips()

        // Gợi ý: cảm giác "haptic" khi kéo đủ lực
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
