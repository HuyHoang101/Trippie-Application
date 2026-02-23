//
//  DetailViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/28/26.
//

import UIKit
import Combine

class DetailViewController: FadeBaseViewController {
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    //MARK: - Property
    private let viewModel = TripViewModel.shared
    private let imagesViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    var id: String?
    var isFeedBoard: Bool?
    var navigationTitle: String?
    private var tripDetailWithStatus: TripWithStatus?
    private var applyAction: ApplyTripAction = .join
    
    //MARK: - UI COMPONENT
    private let coverImage = ContainCoverImageOfTrip()
    private let titleLabel = UILabel.customLabel(text: "Trip title", font: .systemFont(ofSize: 22, weight: .semibold), textColor: .label)
    private let ownerLabel = UILabel.customLabel(text: "Planer: None", font: .systemFont(ofSize: 16), textColor: .systemGray)
    private let locationLabel = UILabel.customLabel(text: "On the sun", font: .systemFont(ofSize: 16), textColor: .systemGray)
    private let dayindex = UILabel.customLabel(text: "0 days", font: .systemFont(ofSize: 16), textColor: .authBackground1, textAligment: .right)
    private let startDateLabel = UILabel.customLabel(text: "Start: 01/01/1999", font: .systemFont(ofSize: 16), textColor: .label)
    private let tripStyle = UILabel.boxStyle(text: "bubby", font: .systemFont(ofSize: 12, weight: .semibold), background: UIColor.button, textColor: .white)
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
    private let menuBtn = DropdownButton()
    private var tripResult: Trip?
    private var participation: Participation?
    
        //MARK: - LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        action()
        binding()
        bindLoading(to: viewModel.loading)
        fetchtrip()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    //MARK: - SETUP UI
    private func setupUI() {
        setupBackground()
        containerAppliedButton.isHidden = true 
        coverImage.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .justified
        
        view.addSubview(mainScroll)
        mainScroll.addSubview(mainContent)
        mainScroll.delegate = self
        mainScroll.alwaysBounceVertical = true
            
        // Đảm bảo tính năng bounce đang bật
        mainScroll.bounces = true
        
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
    
    private func fetchtrip() {
        guard let id = self.id else { return }
        if isFeedBoard == true {
            viewModel.fetchTripById(tripId: id)
            self.participation = nil
        } else {
            viewModel.fetchMyTripById(tripId: id)
        }
    }
    
    private func renderDetail() {
        guard let trip = tripResult else { return }
        self.tripDetailWithStatus = TripWithStatus(trip: trip, participation: participation)
        // 3. Hiển thị các thành phần dùng chung
        titleLabel.text = trip.title
        locationLabel.text = "\(trip.location), \(trip.country)"
        let prefixImages = Array(trip.coverImage.prefix(5))
        let urls = prefixImages.isEmpty ? ["."] : prefixImages
        coverImage.setData(from: urls)
        ownerLabel.text = "Planner: \(trip.ownerName)"
        tripStyle.text = trip.tripType.rawValue.toSentenceCase()
        dayindex.text = "\(trip.dayIndex) days"
        descriptionLabel.text = trip.description.isEmpty ? "No description yet." : trip.description
        peopleJoinedLabel.text = "People joined: \(trip.members.count)"
        
        // Định dạng ngày tháng
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        startDateLabel.text = "Start: \(formatter.string(from: trip.startTime))"
        
        guard let id = AuthService.shared.currentUserId else {return}
        
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
            
            appliedLabel.numberOfLines = 0
            
            if id == trip.ownerId {
                containerAppliedButton.isHidden = true
            } else if trip.pendingRequests.contains(id) {
                containerAppliedButton.isHidden = false
                applyButton.configuration?.title = "Cancel"
                applyButton.configuration?.baseBackgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
                applyButton.isEnabled = true
                appliedLabel.text = "You had sent the request for planner of this trip, waiting for their replied."
                applyAction = .cancelJoin
            } else if trip.members.contains(id) {
                containerAppliedButton.isHidden = false
                applyButton.configuration?.title = "Leave Trip"
                applyButton.configuration?.baseBackgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                applyButton.isEnabled = true
                appliedLabel.text = "You are already a member of this trip."
                applyAction = .leave
            } else if trip.maxMember == trip.currentMember {
                containerAppliedButton.isHidden = false
                applyButton.configuration?.title = "Apply"
                applyButton.configuration?.baseBackgroundColor = .button.withAlphaComponent(0.5)
                applyButton.isEnabled = false
                appliedLabel.text = "Unfortunately, all slots are filled! See you on the next trip!"
                applyAction = .full
            } else {
                containerAppliedButton.isHidden = false
                applyButton.configuration?.title = "Apply"
                applyButton.configuration?.baseBackgroundColor = .button
                applyButton.isEnabled = true
                appliedLabel.text = "This trip would be even better with you. Join the trip now!"
                applyAction = .join
            }
        }
        var dropDownMenus: [DropdownItem] = []
        
        if id == trip.ownerId  && !(isFeedBoard ?? true){
            dropDownMenus.append(DropdownItem(title: "All images", icon: "photo.on.rectangle.angled", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToAllImage(isOwner: true)
            })
            if trip.status != .completed {
                dropDownMenus.append(DropdownItem(title: "Remove from Feed", icon: "arrow.down.document", type: .normal) { [weak self] in
                    guard let self = self else { return }
                    Task {
                        await self.didTapRemoveFormFeed()
                    }
                })
            }
            dropDownMenus.append(DropdownItem(title: "Edit Trip", icon: "pencil.line", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToHandSaveTrip()
            })
            dropDownMenus.append(DropdownItem(title: "Members Joined", icon: "person.2.badge.gearshape", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToMembers(isOwner: true)
            })
            dropDownMenus.append(DropdownItem(title: "Pending Requests", icon: "person.checkmark.and.xmark", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToPendingRequests()
            })
            dropDownMenus.append(DropdownItem(title: "Delete the trip", icon: "trash", type: .destructive) { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.didTapDeleteTheTrip()
                }
            })
        } else {
            dropDownMenus.append(DropdownItem(title: "All images", icon: "photo.on.rectangle.angled", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToAllImage(isOwner: false)
            })
            dropDownMenus.append(DropdownItem(title: "Members Joined", icon: "person.3.sequence", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.pushToMembers(isOwner: false)
            })
        }
        self.menuBtn.items = dropDownMenus
    }
    
    private func setupNavBar() {
        self.title = navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        let rightItem = UIBarButtonItem(customView: questionBtn)
        let rightItem2 = UIBarButtonItem(customView: menuBtn)
        self.navigationItem.leftBarButtonItem = leftItem
        self.navigationItem.rightBarButtonItems = [rightItem2, rightItem]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    
    //MARK: - ACTION
    private func action() {
        questionBtn.addTarget(self, action: #selector(openExplainationSheet), for: .touchUpInside)
        planBtn.addTarget(self, action: #selector(pushToTask), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(appliedAction), for: .touchUpInside)
    }
    
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
        TripViewModel.shared.singleTrip.send(nil)
        TripViewModel.shared.singleMyTrip.send(nil)
    }
    
    @objc private func appliedAction() {
        guard let trip = self.tripDetailWithStatus?.trip else { return }
        switch applyAction {
        case .join:
            viewModel.joinTrip(trip: trip)
        case .full:
            return
        case .cancelJoin:
            viewModel.cancelJoinRequest(trip: trip)
        case .leave:
            Task {
                do {
                    await doLeaveTrip(trip: trip)
                }
            }
        }
    }
    
    @MainActor
    private func doLeaveTrip(trip: Trip) async {
        let confirmAlert = await self.confirmAlert(type: .leave, title: "this Trip?")
        
        if confirmAlert {
            self.viewModel.leaveTrip(trip: trip)
        }
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
    
    @objc private func pushToPendingRequests() {
        let userListVC = FriendsOrMembersListViewController()
        userListVC.navigationTitle = "Pending Requests"
        userListVC.listType = .pendingRequest
        userListVC.tripDetail = self.tripDetailWithStatus?.trip
        userListVC.memberIds = self.tripDetailWithStatus?.trip.pendingRequests
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc private func pushToMembers(isOwner: Bool) {
        let userListVC = FriendsOrMembersListViewController()
        userListVC.navigationTitle = "All Members"
        guard let ownerId = self.tripDetailWithStatus?.trip.ownerId ,let ids = self.tripDetailWithStatus?.trip.members else { return }
        if isOwner {
            userListVC.listType = .tripMembers
            userListVC.memberIds = ids
        } else {
            userListVC.listType = .tripMemberForAnotherLooking
            var memIds = [ownerId]
            memIds.append(contentsOf: ids)
            userListVC.memberIds = memIds
            
        }
        userListVC.tripDetail = self.tripDetailWithStatus?.trip
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc private func didTapRemoveFormFeed() async {
        guard var trip = tripDetailWithStatus else { return }
        viewModel.editingTrip.send(trip)
        trip.trip.status = .completed
        let confirmAlert = await confirmAlert(type: .remove, title: "This action cannot be undone!")
        if confirmAlert {
            self.viewModel.handleSave(trip: trip.trip)
        }
    }
    
    @objc private func didTapDeleteTheTrip() async {
        guard let trip = tripDetailWithStatus else { return }
        let confirmAlert = await confirmAlert(type: .deleteTrip, title: "This action cannot be undone!")
        if confirmAlert {
            self.imagesViewModel.uploadedUrls = trip.trip.coverImage
            self.viewModel.deleteTrip(tripId: trip.trip.id!)
            self.imagesViewModel.deleteAllImages()
            self.handleBack()
        }
    }
    
    @objc private func pushToHandSaveTrip() {
        let vc = HandSaveTrip()
        vc.viewModel = viewModel
        self.viewModel.editingTrip.send(tripDetailWithStatus)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func pushToAllImage(isOwner: Bool) {
        let vc = AllPhotosViewController()
        vc.imageUrls = (self.tripDetailWithStatus?.trip.coverImage)!
        vc.isOwnerOpen = isOwner
        vc.trip = self.tripDetailWithStatus
        vc.navigationTitle = "All Images"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - BINDING
    private func binding() {
        viewModel.didTapChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchtrip()
            }
            .store(in: &cancellable)
        viewModel.singleTrip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] t in
                self?.tripResult = t
                self?.renderDetail()
            }
            .store(in: &cancellable)
        viewModel.singleMyTrip
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tws in
                self?.tripResult = tws?.trip
                self?.participation = tws?.participation
                self?.renderDetail()
            }
            .store(in: &cancellable)
    }
}


extension DetailViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Kiểm tra nếu là mainScroll và người dùng kéo xuống một khoảng (ví dụ -100)
        let offset = scrollView.contentOffset.y
        if offset < -70 {
            handleRefreshData()
        }
    }
    
    private func handleRefreshData() {
        guard let id = self.id else { return }
        if let i = isFeedBoard, i {
            self.viewModel.fetchTripById(tripId: id)
        } else {
            self.viewModel.fetchMyTripById(tripId: id)
        }
        // Gợi ý: cảm giác "haptic" khi kéo đủ lực
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
