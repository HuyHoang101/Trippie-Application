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
    private let applyButton = UIButton.customButton(text: "Apply", backgroundColor: UIColor.button, isCircle: false)
    private let containerAppliedButton = UIStackView.customStack(xPadding: 20, yPadding: 20, background: .white, axis: .horizontal, alignment: .center, distribution: .fill, cornerRadius: 12, isShadow: true)
    private let appliedLabel = UILabel.customLabel(text: "This trip would be even better with you. Join the trip now!", font: .systemFont(ofSize: 13), textColor: .black)
    private let planBtn = UIButton.customButton(text: "📆 View the detailed schedule  ＞", font: .systemFont(ofSize: 14), backgroundColor: .clear, textColor: .systemBlue, isCircle: false, xPadding: 0, yPadding: 2, alignment: .left)
    
    
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
    private let questionBtn = UIButton.customButton(image: UIImage(systemName: "questionmark"), backgroundColor: UIColor(named: "AuthBackground2")?.withAlphaComponent(0.5) ?? .systemGray.withAlphaComponent(0.5))
        //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        action()
        binding()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        coverImage.setImage(url: "")
        coverImage.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .justified
        
        view.addSubview(mainScroll)
        mainScroll.addSubview(mainContent)
        
        mainContent.addArrangedSubview(coverImage)
        mainContent.addArrangedSubview(titleLabel)
        mainContent.addArrangedSubview(hstack1)
        mainContent.addArrangedSubview(hstack2)
        mainContent.addArrangedSubview(peopleJoinedLabel)
        mainContent.addArrangedSubview(pendingRequests)
        mainContent.addArrangedSubview(startDateLabel)
        mainContent.addArrangedSubview(planBtn)
        mainContent.addArrangedSubview(descriptionTitle)
        mainContent.addArrangedSubview(descriptionLabel)
        
        
        mainContent.addArrangedSubview(containerAppliedButton)
        containerAppliedButton.addArrangedSubview(appliedLabel)
        containerAppliedButton.addArrangedSubview(applyButton)
        
        hstack1.addArrangedSubview(locationLabel)
        hstack1.addArrangedSubview(dayindex)
        
        let spacer = UIView()
        hstack2.addArrangedSubview(ownerLabel)
        hstack2.addArrangedSubview(spacer)
        hstack2.addArrangedSubview(tripStyle)
        
        coverImage.addSubview(personalStatus)
        
        mainScroll.translatesAutoresizingMaskIntoConstraints = false
        personalStatus.translatesAutoresizingMaskIntoConstraints = false
        
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
            coverImage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),
            
            personalStatus.topAnchor.constraint(equalTo: coverImage.topAnchor, constant: 20),
            personalStatus.trailingAnchor.constraint(equalTo: coverImage.trailingAnchor, constant: -20)
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
        coverImage.setImage(url: trip.coverImage.first)
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
            if part.role == .owner && trip.status != .completed {
                personalStatus.isHidden = true
            } else {
                personalStatus.isHidden = false
            }
            personalStatus.configure(status: part.personalStatus)
            planBtn.isHidden = false
            
            // Chỉ hiện request nếu là chủ phòng (Owner)
            pendingRequests.isHidden = (part.role != .owner)
            pendingRequests.text = "Pending requests: \(trip.pendingRequests.count)"
            containerAppliedButton.isHidden = true
        } else {
            // Trường hợp Feed Board (Chưa tham gia)
            personalStatus.isHidden = true
            pendingRequests.isHidden = true
            planBtn.isHidden = true
            
            var config = UIButton.Configuration.filled()
            var container = AttributeContainer()
            container.font = UIFont.systemFont(ofSize: 13)
            appliedLabel.numberOfLines = 0
            
            guard let id = AuthService.shared.currentUserId else {return}
            if id == trip.ownerId {
                containerAppliedButton.isHidden = true
            } else if trip.pendingRequests.contains(id) {
                containerAppliedButton.isHidden = false
                config.attributedTitle = AttributedString("Cancel", attributes: container)
                config.baseBackgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
                applyButton.configuration = config
                appliedLabel.text = "You was send the request for planner of this trip, waiting for their replied."
            } else if trip.members.contains(id) {
                containerAppliedButton.isHidden = false
                config.attributedTitle = AttributedString("Leave trip", attributes: container)
                config.baseBackgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                applyButton.configuration = config
                appliedLabel.text = "You are already a member of this trip."
            } else if trip.maxMember == trip.currentMember {
                containerAppliedButton.isHidden = false
                config.attributedTitle = AttributedString("Apply", attributes: container)
                config.baseBackgroundColor = .button
                applyButton.configuration = config
                applyButton.isEnabled = false
                appliedLabel.text = "Unfortunately, all slots are filled! See you on the next trip!"
            } else {
                containerAppliedButton.isHidden = false
                config.attributedTitle = AttributedString("Apply", attributes: container)
                config.baseBackgroundColor = .button
                applyButton.configuration = config
                appliedLabel.text = "This trip would be even better with you. Join the trip now!"
            }
        }
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: questionBtn)
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItem = rightItem
        
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
    
    
    //MARK: - ACTION
    private func action() {
        questionBtn.addTarget(self, action: #selector(openExplainationSheet), for: .touchUpInside)
        planBtn.addTarget(self, action: #selector(pushToTask), for: .touchUpInside)
    }
    
    private func appliedAction() {
        
    }
    
    @objc private func openExplainationSheet() {
        let explaination = TripStyleExplaination()
        if let sheet = explaination.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        self.present(explaination, animated: true)
    }
    
    @objc private func pushToTask() {
        let taskVC = ListTaskViewController()
        taskVC.id = self.id
        taskVC.navigationTitle = self.locationLabel.text
        self.navigationController?.pushViewController(taskVC, animated: true)
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
