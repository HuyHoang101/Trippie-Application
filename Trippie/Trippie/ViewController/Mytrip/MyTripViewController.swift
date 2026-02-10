//
//  MyTripViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit
import Combine

class MyTripViewController: FadeBaseViewController {
    
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
    
    private let searchBar = UITextField.createInput(placeholder: "Searching...", iconName: "magnifyingglass")
    
    private let filterButton = UIButton.customButton(image: UIImage(systemName: "slider.horizontal.3"), backgroundColor: UIColor(named: "AuthBackground1") ?? UIColor.purple, tintColor: .white, isCircle: false, padding: 13)
    
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
        filterStack.addArrangedSubview(filterButton)
        
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
        subscroll.showsHorizontalScrollIndicator = false
        subscroll1.showsHorizontalScrollIndicator = false
        subscroll2.showsHorizontalScrollIndicator = false
        subscroll3.showsHorizontalScrollIndicator = false
        
        NSLayoutConstraint.activate([
            mainscroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainscroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainscroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainscroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            maincontent.topAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.topAnchor, constant: 20),
            maincontent.leadingAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.leadingAnchor),
            maincontent.trailingAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.trailingAnchor),
            maincontent.bottomAnchor.constraint(equalTo: mainscroll.contentLayoutGuide.bottomAnchor, constant: -20),
            
            maincontent.widthAnchor.constraint(equalTo: mainscroll.widthAnchor),
            
            hstack.topAnchor.constraint(equalTo: subscroll.contentLayoutGuide.topAnchor),
            hstack.leadingAnchor.constraint(equalTo: subscroll.contentLayoutGuide.leadingAnchor),
            hstack.trailingAnchor.constraint(equalTo: subscroll.contentLayoutGuide.trailingAnchor),
            hstack.bottomAnchor.constraint(equalTo: subscroll.contentLayoutGuide.bottomAnchor),
            hstack.heightAnchor.constraint(equalTo: subscroll.heightAnchor),
            
            hstack1.topAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.topAnchor),
            hstack1.leadingAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.leadingAnchor),
            hstack1.trailingAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.trailingAnchor),
            hstack1.bottomAnchor.constraint(equalTo: subscroll1.contentLayoutGuide.bottomAnchor),
            hstack1.heightAnchor.constraint(equalTo: subscroll1.heightAnchor),
            
            hstack2.topAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.topAnchor),
            hstack2.leadingAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.leadingAnchor),
            hstack2.trailingAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.trailingAnchor),
            hstack2.bottomAnchor.constraint(equalTo: subscroll2.contentLayoutGuide.bottomAnchor),
            hstack2.heightAnchor.constraint(equalTo: subscroll2.heightAnchor),
            
            hstack3.topAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.topAnchor),
            hstack3.leadingAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.leadingAnchor),
            hstack3.trailingAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.trailingAnchor),
            hstack3.bottomAnchor.constraint(equalTo: subscroll3.contentLayoutGuide.bottomAnchor),
            hstack3.heightAnchor.constraint(equalTo: subscroll3.heightAnchor),
            
            searchBar.heightAnchor.constraint(equalToConstant: 50),
            filterButton.widthAnchor.constraint(equalTo: filterButton.heightAnchor)
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
            $0.participation?.personalStatus == PersonalStatus.cancel &&
            $0.participation?.personalStatus == PersonalStatus.completed &&
            $0.participation?.role == UserRole.owner &&
            $0.trip.status == .completed
        })
        let joinTrips = Array(viewModel.myTrips.value.filter {
            $0.participation?.personalStatus == PersonalStatus.cancel &&
            $0.participation?.personalStatus == PersonalStatus.completed &&
            $0.participation?.role == UserRole.member
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
            }
        }
        
        if myTrips.count == 0 {
            viewAllButton2.isHidden = true
            let emptyCard = UIView()
            hstack2.addArrangedSubview(emptyCard)
            emptyCard.layer.cornerRadius = 12
            emptyCard.clipsToBounds = true
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
            emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
            
            let emptylabel = UILabel.customLabel(text: "You haven't completed any trip that you created before.", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
            emptyCard.addSubview(emptylabel)
            emptylabel.numberOfLines = 0
            emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
            emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
            emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
            
            self.view.layoutIfNeeded()
            emptyCard.addDashedBorder()
        } else {
            viewAllButton2.isHidden = false
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
            }
        }
        
        if joinTrips.count == 0 {
            viewAllButton3.isHidden = true
            let emptyCard = UIView()
            hstack3.addArrangedSubview(emptyCard)
            emptyCard.layer.cornerRadius = 12
            emptyCard.clipsToBounds = true
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -25).isActive = true
            emptyCard.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.48).isActive = true
            
            let emptylabel = UILabel.customLabel(text: "You haven't completed any trip that you joined before.", font: AppTheme.Font.mainMedium(size: 16), textColor: .secondaryLabel, textAligment: .center)
            emptyCard.addSubview(emptylabel)
            emptylabel.numberOfLines = 0
            emptylabel.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor).isActive = true
            emptylabel.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: 40).isActive = true
            emptylabel.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -40).isActive = true
            
            self.view.layoutIfNeeded()
            emptyCard.addDashedBorder()
        } else {
            viewAllButton3.isHidden = false
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
            }
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
    
    @objc func pushToLish(_ render: UIButton) {
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
                $0.participation?.personalStatus == .completed &&
                $0.participation?.personalStatus == .cancel &&
                $0.participation?.role == .owner &&
                $0.trip.status == .completed
            }
        case viewAllButton3:
            listVC.navigationTitle = "Joined Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                $0.participation?.personalStatus != .completed &&
                $0.participation?.personalStatus != .cancel &&
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
    func binding() {
        viewModel.myTrips
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellable)
    }
}
