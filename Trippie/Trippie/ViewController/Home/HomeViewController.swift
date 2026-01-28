//
//  HomeViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class HomeViewController: FadeBaseViewController {
    
    private var viewModel = TripViewModel.shared
    private var cancellable = Set<AnyCancellable>()
    
    //MARK: - UI COMPONENT
    private let welcomlabel = UILabel.customLabel(text: "Let's pack for your trip", font: AppTheme.Font.mainMedium(size: 36), textColor: .label)
    
    private let welcomlabel2 = UILabel.customLabel(text: "Use one of our suggestions or make a list of what a pack", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel)
    
    private let searchBar = UITextField.createInput(placeholder: "Searching...", iconName: "magnifyingglass")
    
    private let filterButton = UIButton.customButton(image: UIImage(systemName: "slider.horizontal.3"), backgroundColor: UIColor(named: "AuthBackground1") ?? UIColor.purple, tintColor: .white, isCircle: false, padding: 13)
    
    private let Newest = UIButton.customButton(text: "Newest", font: UIFont.systemFont(ofSize: 13, weight: .regular), backgroundColor: UIColor(named: "AuthBackground1") ?? UIColor.purple, isCircle: false, isBorder: true)
    
    private let Vietnam = UIButton.customButton(text: "Vietnam", font: UIFont.systemFont(ofSize: 13, weight: .regular), backgroundColor: .white, textColor: .secondaryLabel, isCircle: false, isBorder: true, borderColor: .secondaryLabel)
    
    private let Recommend = UIButton.customButton(text: "Recommend", font: UIFont.systemFont(ofSize: 13, weight: .regular), backgroundColor: .white, textColor: .secondaryLabel, isCircle: false, isBorder: true, borderColor: .secondaryLabel)
    
    private let mainScroll = UIScrollView()
    
    private let subScroll = UIScrollView()
    
    private let mainview = UIView()
    
    private let vstack1 = UIStackView.customStack(xPadding: 12, yPadding: 8, axis: .vertical, alignment: .leading, distribution: .fill, stackSpacing: 12)
    
    private let hstack1 = UIStackView.customStack(xPadding: 12, yPadding: 8, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 10)
    
    private let hstack2 = UIStackView.customStack(xPadding: 12, yPadding: 8, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 6)
    
    private let titleLabel1 = UILabel.customLabel(text: "Earliest place", font: AppTheme.Font.mainBold(size: 22), textColor: .label)
    
    private let viewAllButton = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    
    private let hstack3 = UIStackView.customStack(yPadding: 8, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 16)
    
    private let vstack2 = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill)
    private let titleLable2 = UILabel.customLabel(text: "You might like", font: AppTheme.Font.mainBold(size: 22), textColor: .label)
    
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
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //MARK: - SET UP UI
    func setupUI() {
        setupBackground()
        viewModel.fetchTripForFeedTable()
        viewModel.titleFilter.send("Earliest")
        searchBar.clipsToBounds = false
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowRadius = 3
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 0)
        searchBar.layer.shadowOpacity = 0.15
        
        mainScroll.delegate = self
        mainScroll.alwaysBounceVertical = true
        mainScroll.showsVerticalScrollIndicator = false
        subScroll.showsHorizontalScrollIndicator = false
        
        mainScroll.translatesAutoresizingMaskIntoConstraints = false
        subScroll.translatesAutoresizingMaskIntoConstraints = false
        mainview.translatesAutoresizingMaskIntoConstraints = false
        welcomlabel.numberOfLines = 2
        welcomlabel2.numberOfLines = 2
        
        
        view.addSubview(mainScroll)
        mainScroll.addSubview(mainview)
        
        mainview.addSubview(vstack1)
        mainview.addSubview(hstack1)
        mainview.addSubview(hstack2)
        mainview.addSubview(titleLabel1)
        mainview.addSubview(viewAllButton)
        mainview.addSubview(subScroll)
        mainview.addSubview(titleLable2)
        mainview.addSubview(vstack2)
        
        vstack1.addArrangedSubview(welcomlabel)
        vstack1.addArrangedSubview(welcomlabel2)
        
        hstack1.addArrangedSubview(searchBar)
        hstack1.addArrangedSubview(filterButton)
        
        hstack2.addArrangedSubview(Newest)
        hstack2.addArrangedSubview(Vietnam)
        hstack2.addArrangedSubview(Recommend)
        
        subScroll.addSubview(hstack3)
        renderTrips()
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hstack2.addArrangedSubview(spacer)
        
        NSLayoutConstraint.activate([
            mainScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainview.leadingAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.leadingAnchor),
            mainview.trailingAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.trailingAnchor),
            mainview.topAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.topAnchor, constant: 20),
            mainview.bottomAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.bottomAnchor),
            
            mainview.widthAnchor.constraint(equalTo: mainScroll.widthAnchor),
            
            vstack1.topAnchor.constraint(equalTo: mainview.topAnchor),
            vstack1.leadingAnchor.constraint(equalTo: mainview.leadingAnchor),
            vstack1.trailingAnchor.constraint(equalTo: mainview.trailingAnchor),
            
            hstack1.topAnchor.constraint(equalTo: vstack1.bottomAnchor),
            hstack1.leadingAnchor.constraint(equalTo: mainview.leadingAnchor),
            hstack1.trailingAnchor.constraint(equalTo: mainview.trailingAnchor),
            
            hstack2.topAnchor.constraint(equalTo: hstack1.bottomAnchor),
            hstack2.leadingAnchor.constraint(equalTo: mainview.leadingAnchor),
            hstack2.trailingAnchor.constraint(equalTo: mainview.trailingAnchor),
            hstack2.bottomAnchor.constraint(equalTo: titleLabel1.topAnchor, constant: -16),
            
            titleLabel1.leadingAnchor.constraint(equalTo: mainview.leadingAnchor, constant: 12),
            titleLabel1.trailingAnchor.constraint(lessThanOrEqualTo: viewAllButton.trailingAnchor, constant: -12),
            
            viewAllButton.bottomAnchor.constraint(equalTo: titleLabel1.bottomAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: mainview.trailingAnchor, constant: -12),
            
            subScroll.topAnchor.constraint(equalTo: titleLabel1.bottomAnchor, constant: 8),
            subScroll.leadingAnchor.constraint(equalTo: mainview.leadingAnchor, constant: 12),
            subScroll.trailingAnchor.constraint(equalTo: mainview.trailingAnchor, constant: -12),
            subScroll.bottomAnchor.constraint(equalTo: titleLable2.topAnchor, constant: -16),
            
            hstack3.topAnchor.constraint(equalTo: subScroll.contentLayoutGuide.topAnchor),
            hstack3.bottomAnchor.constraint(equalTo: subScroll.contentLayoutGuide.bottomAnchor),
            hstack3.trailingAnchor.constraint(equalTo: subScroll.contentLayoutGuide.trailingAnchor),
            hstack3.leadingAnchor.constraint(equalTo: subScroll.contentLayoutGuide.leadingAnchor),
            
            hstack3.heightAnchor.constraint(equalTo: subScroll.heightAnchor),
            subScroll.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48),
            
            titleLable2.leadingAnchor.constraint(equalTo: mainview.leadingAnchor, constant: 12),
            titleLable2.trailingAnchor.constraint(equalTo: mainview.trailingAnchor, constant: 12),
            
            vstack2.topAnchor.constraint(equalTo: titleLable2.bottomAnchor, constant: 16),
            vstack2.trailingAnchor.constraint(equalTo: mainview.trailingAnchor, constant: -12),
            vstack2.leadingAnchor.constraint(equalTo: mainview.leadingAnchor, constant: 12),
            vstack2.bottomAnchor.constraint(equalTo: mainview.bottomAnchor, constant: -20),
            
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor)
        ])
    }
    
    private func renderTrips(forList: Bool = true){
        let trip = Array(viewModel.tripForFilter.prefix(5))
        hstack3.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if trip.count == 0 {
            let emptyCard = UIView()
            hstack3.addArrangedSubview(emptyCard)
            emptyCard.layer.cornerRadius = 12
            emptyCard.clipsToBounds = true
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
            emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
            
            let emptylabel = UILabel.customLabel(text: "Empty content, disconection, or server error", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
            emptylabel.numberOfLines = 0
            emptyCard.addSubview(emptylabel)
            emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
            emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
            emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
            
            self.view.layoutIfNeeded()
            emptyCard.addDashedBorder()
        } else {
            trip.forEach { t in
                let card = FeedCard(trip: t)
                hstack3.addArrangedSubview(card)
                card.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
                    card.heightAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.8)
                ])
            }
        }
        if forList {
            let trip2 = Array(viewModel.randomTrips.value.prefix(5))
            vstack2.arrangedSubviews.forEach { $0.removeFromSuperview() }
            if trip2.count == 0 {
                let emptyCard = UIView()
                vstack2.addArrangedSubview(emptyCard)
                emptyCard.layer.cornerRadius = 12
                emptyCard.clipsToBounds = true
                emptyCard.translatesAutoresizingMaskIntoConstraints = false
                emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
                emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
                
                let emptylabel = UILabel.customLabel(text: "Empty content, disconection, or server error", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
                emptylabel.numberOfLines = 0
                emptyCard.addSubview(emptylabel)
                emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
                emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
                emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
                
                self.view.layoutIfNeeded()
                emptyCard.addDashedBorder()
            } else {
                trip2.forEach { t in
                    let row = UniversalTripCard()
                    let tripWithStatus = TripWithStatus(trip: t, participation: Participation(userId: "", tripId: "", personalStatus: .upcoming, role: .member))
                    row.configure(trip: tripWithStatus, isListMode: false, isFullTitle: true)
                    vstack2.addArrangedSubview(row)
                    row.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        row.widthAnchor.constraint(equalTo: vstack2.widthAnchor)
                    ])
                }
            }
        }
    }
    
    //MARK: - SETUP ACTION
    private func setupAction() {
        Newest.addTarget(self, action: #selector(handleFilterTap), for: .touchUpInside)
        Vietnam.addTarget(self, action: #selector(handleFilterTap), for: .touchUpInside)
        Recommend.addTarget(self, action: #selector(handleFilterTap), for: .touchUpInside)
        viewAllButton.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
    }
    
    @objc private func multiplechoice(_ string: String) {
        // 1. Định nghĩa hai trạng thái Style
        
        // Style cho nút ĐƯỢC CHỌN (Sáng)
        let selectedUpdate: (UIButton) -> Void = { btn in
            var config = btn.configuration
            config?.baseBackgroundColor = UIColor(named: "AuthBackground1")
            config?.baseForegroundColor = .white
            config?.background.strokeColor = .clear
            btn.configuration = config
        }
        
        // Style cho nút KHÔNG ĐƯỢC CHỌN (Tối)
        let deselectedUpdate: (UIButton) -> Void = { btn in
            var config = btn.configuration
            config?.baseBackgroundColor = .clear
            config?.baseForegroundColor = .secondaryLabel
            config?.background.strokeColor = .secondaryLabel.withAlphaComponent(0.5)
            config?.background.strokeWidth = 0.7
            btn.configuration = config
        }
        
        // 2. Switch case dựa trên string truyền vào
        switch string {
        case "Newest":
            selectedUpdate(Newest)
            deselectedUpdate(Vietnam)
            deselectedUpdate(Recommend)
            titleLabel1.text = "Earliest trips"
            viewModel.titleFilter.send("Earliest")
            
        case "Vietnam":
            deselectedUpdate(Newest)
            selectedUpdate(Vietnam)
            deselectedUpdate(Recommend)
            titleLabel1.text = "Vietnam popular place"
            viewModel.titleFilter.send("Vietnam")
            
        case "Recommend":
            deselectedUpdate(Newest)
            deselectedUpdate(Vietnam)
            selectedUpdate(Recommend)
            titleLabel1.text = "Recommend for you"
            viewModel.titleFilter.send("Recommend")
            
        default:
            break
        }
    }
    
    @objc private func handleFilterTap(_ sender: UIButton) {

        if let title = sender.configuration?.title {
            self.multiplechoice(title)
        }
    }
    
    @objc private func pushToLish(_ sender: UIButton) {
        let listVC = ListViewController()

        switch sender {
        case viewAllButton:
            listVC.navigationTitle = titleLabel1.text
            listVC.trip = viewModel.tripForFilter
        default:
            listVC.navigationTitle = "All Trips"
            listVC.trip = viewModel.trips.value
        }
        navigationController?.pushViewController(listVC, animated: true)
    }
    
    //MARK: -BINDING
    private func binding() {
        viewModel.trips
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink{ [weak self] _ in
                self?.renderTrips()
            }
            .store(in: &cancellable)
        viewModel.titleFilter
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink{ [weak self] _ in
                self?.renderTrips(forList: false)
            }
            .store(in: &cancellable)
        viewModel.randomTrips
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink{ [weak self] _ in
                self?.renderTrips(forList: false)
            }
            .store(in: &cancellable)
    }
}


extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Kiểm tra nếu là mainScroll và người dùng kéo xuống một khoảng (ví dụ -100)
        let offset = scrollView.contentOffset.y
        if offset < -100 {
            handleRefreshData()
        }
    }
    
    private func handleRefreshData() {

        viewModel.fetchTripForFeedTable()
        // Gợi ý: cảm giác "haptic" khi kéo đủ lực
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
