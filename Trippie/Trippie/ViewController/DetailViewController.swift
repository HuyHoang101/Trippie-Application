//
//  DetailViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//

import UIKit
import Combine

class DetailViewController: FadeBaseViewController {
    
    //MARK: - Property
    private let viewModel = TripViewModel.shared
    private var cancellable = Set<AnyCancellable>()
    var id: String?
    var isFeedBoard: Bool?
    var navigationTitle: String?
    
    //MARK: - UI COMPONENT
    private let coverImage = TrippieImageView(style: .rounded(radius: 14, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]), isShadow: false, borderColor: .clear)
    private let titleLabel = UILabel.customLabel(text: "Trip title", font: .systemFont(ofSize: 22, weight: .semibold), textColor: .label)
    private let ownerLabel = UILabel.customLabel(text: "Planer: None", font: .systemFont(ofSize: 16), textColor: .systemGray)
    private let locationLabel = UILabel.customLabel(text: "On the sun", font: .systemFont(ofSize: 16), textColor: .systemGray)
    private let dayindex = UILabel.customLabel(text: "0 days", font: .systemFont(ofSize: 16), textColor: .authBackground1, textAligment: .right)
    private let startDateLabel = UILabel.customLabel(text: "Start: 01/01/1999", font: .systemFont(ofSize: 16), textColor: .label)
    private let tripStyle = UILabel.boxStyle(text: "", font: .systemFont(ofSize: 12, weight: .semibold), background: UIColor.button, textColor: .white)
    private let personalStatus = TripStatusBadge()
    private let peopleJoinedLabel = UILabel.customLabel(text: "People joined: 0", font: .systemFont(ofSize: 16), textColor: .label)
    private let pendingRequests = UILabel.customLabel(text: "Pending requests: 0", font: .systemFont(ofSize: 16), textColor: .label)
    private let descriptionTitle = UILabel.customLabel(text: "Description", font: .systemFont(ofSize: 16, weight: .semibold), textColor: .label)
    private let descriptionLabel = UILabel.customLabel(text: "The planer hasn't added the description of trip yet.", font: .systemFont(ofSize: 16, weight: .regular), textColor: .darkGray)
    private let mainScroll = UIScrollView()
    private let mainContent = UIStackView.customStack(xPadding: 12, yPadding: 20, axis: .vertical, alignment: .fill, distribution: .fill)
    private let hstack1 = UIStackView.customStack(axis: .horizontal, alignment: .bottom, distribution: .fill)
    private let hstack2 = UIStackView.customStack(axis: .horizontal, alignment: .center, distribution: .fill)
    
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    
    //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        binding()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        coverImage.setImage(url: "")
        coverImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainScroll)
        mainScroll.addSubview(mainContent)
        
        mainContent.addArrangedSubview(coverImage)
        mainContent.addArrangedSubview(titleLabel)
        mainContent.addArrangedSubview(hstack1)
        mainContent.addArrangedSubview(hstack2)
        mainContent.addArrangedSubview(peopleJoinedLabel)
        mainContent.addArrangedSubview(pendingRequests)
        mainContent.addArrangedSubview(startDateLabel)
        mainContent.addArrangedSubview(descriptionTitle)
        mainContent.addArrangedSubview(descriptionLabel)
        
        hstack1.addArrangedSubview(locationLabel)
        hstack1.addArrangedSubview(dayindex)
        
        let spacer = UIView()
        hstack2.addArrangedSubview(ownerLabel)
        hstack2.addArrangedSubview(spacer)
        hstack2.addArrangedSubview(tripStyle)
        
        mainScroll.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainContent.topAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.topAnchor),
            mainContent.leadingAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.leadingAnchor),
            mainContent.trailingAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.trailingAnchor),
            mainContent.bottomAnchor.constraint(equalTo: mainScroll.contentLayoutGuide.bottomAnchor),
            
            mainContent.widthAnchor.constraint(equalTo: mainScroll.widthAnchor),
            coverImage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25)
        ])
        
        renderDetail()
        setupNavBar()
    }
    
    private func renderDetail() {
        let tripResult: Trip?
        let participation: Participation?
        
        if isFeedBoard == true {
            tripResult = viewModel.trips.value.first(where: { $0.id == self.id })
            participation = nil
        } else {
            let joined = viewModel.myTrips.value.first(where: { $0.trip.id == self.id })
            tripResult = joined?.trip
            participation = joined?.participation
        }
        
        guard let trip = tripResult else {
            print("DEBUG: Trip not found with ID: \(self.id ?? "nil")")
            return
        }
        
        // 3. Hiển thị các thành phần dùng chung
        titleLabel.text = trip.title
        locationLabel.text = "\(trip.location), \(trip.country)"
        coverImage.setImage(url: trip.coverImage)
        ownerLabel.text = "Planner: \(trip.ownerName)"
        tripStyle.text = trip.tripType.rawValue.toSentenceCase()
        dayindex.text = "\(trip.dayIndex) days"
        descriptionLabel.text = trip.description.isEmpty ? "No description yet." : trip.description
        peopleJoinedLabel.text = "People joined: \(trip.members.count)"
        
        // Định dạng ngày tháng
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        startDateLabel.text = "Start: \(formatter.string(from: trip.startTime))"
        
        // 4. Hiển thị các thành phần đặc thù (Status & Role)
        if let part = participation {
            // Trường hợp My Trip (Đã tham gia)
            personalStatus.isHidden = false
            personalStatus.configure(status: part.personalStatus)
            
            // Chỉ hiện request nếu là chủ phòng (Owner)
            pendingRequests.isHidden = (part.role != .owner)
            pendingRequests.text = "Pending requests: \(trip.pendingRequests.count)"
        } else {
            // Trường hợp Feed Board (Chưa tham gia)
            personalStatus.isHidden = true
            pendingRequests.isHidden = true
        }
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
    
    //MARK: - BINDING
    private func binding() {
        viewModel.trips
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.renderDetail()
            }
            .store(in: &cancellable)
        viewModel.myTrips
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.renderDetail()
            }
            .store(in: &cancellable)
    }
}
