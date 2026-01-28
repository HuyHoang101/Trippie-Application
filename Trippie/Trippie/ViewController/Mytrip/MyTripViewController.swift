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
    
    private let subscroll1 = UIScrollView()
    private let subscroll2 = UIScrollView()
    private let subscroll3 = UIScrollView()
    
    private let hstack1 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    private let hstack2 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    private let hstack3 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    
    private let maincontent = UIStackView.customStack(axis: .vertical, alignment: .fill, distribution: .fill, stackSpacing: 0)
    
    private let searchBar = UITextField.createInput(placeholder: "Searching...", iconName: "magnifyingglass")
    
    private let filterButton = UIButton.customButton(image: UIImage(systemName: "slider.horizontal.3"), backgroundColor: UIColor(named: "AuthBackground1") ?? UIColor.purple, tintColor: .white, isCircle: false, padding: 13)
    
    private let filterStack = UIStackView.customStack(xPadding: 12, yPadding: 20, axis: .horizontal, alignment: .center, distribution: .fill, stackSpacing: 12)
    
    private let label1 = UILabel.customLabel(text: "Current Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    private let label2 = UILabel.customLabel(text: "My Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    private let label3 = UILabel.customLabel(text: "Joined Trips", font: AppTheme.Font.mainMedium(size: 18), textColor: .secondaryLabel)
    
    private let viewAllButton1 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    private let viewAllButton2 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    private let viewAllButton3 = UIButton.customButton(text: "View all", font: UIFont.systemFont(ofSize: 15), backgroundColor: .clear, textColor: .secondaryLabel, isPadding: false)
    
    private let hstack4 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    private let hstack5 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    private let hstack6 = UIStackView.customStack(xPadding: 12, yPadding: 10, axis: .horizontal, alignment: .center, distribution: .fill)
    
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
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
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
        
        subscroll1.addSubview(hstack1)
        subscroll2.addSubview(hstack2)
        subscroll3.addSubview(hstack3)
        
        mainscroll.translatesAutoresizingMaskIntoConstraints = false
        subscroll1.translatesAutoresizingMaskIntoConstraints = false
        subscroll2.translatesAutoresizingMaskIntoConstraints = false
        subscroll3.translatesAutoresizingMaskIntoConstraints = false
        
        mainscroll.showsVerticalScrollIndicator = false
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

    }
    
    func render() {
        let currentTrips = Array(viewModel.myTrips.value.filter {
            $0.participation.personalStatus != PersonalStatus.cancel &&
            $0.participation.personalStatus != PersonalStatus.completed
        })
        let myTrips = Array(viewModel.myTrips.value.filter {
            $0.participation.personalStatus == PersonalStatus.cancel &&
            $0.participation.personalStatus == PersonalStatus.completed &&
            $0.participation.role == UserRole.owner
        })
        let joinTrips = Array(viewModel.myTrips.value.filter {
            $0.participation.personalStatus == PersonalStatus.cancel &&
            $0.participation.personalStatus == PersonalStatus.completed &&
            $0.participation.role == UserRole.member
        })
        
        hstack1.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        hstack2.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        hstack3.arrangedSubviews.forEach{ $0.removeFromSuperview() }
        
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
            }
        }
    }
    
    //MARK: - SETUP ACTION
    func setupAction() {
        viewAllButton1.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
        viewAllButton2.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
        viewAllButton3.addTarget(self, action: #selector(pushToLish), for: .touchUpInside)
    }
    
    @objc func pushToLish(_ render: UIButton) {
        let listVC = ListViewController()
        
        switch render {
        case viewAllButton1:
            listVC.navigationTitle = "Current Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                $0.participation.personalStatus != .completed &&
                $0.participation.personalStatus != .cancel
            }
        case viewAllButton2:
            listVC.navigationTitle = "My Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                $0.participation.personalStatus == .completed &&
                $0.participation.personalStatus == .cancel &&
                $0.participation.role == .owner
            }
        case viewAllButton3:
            listVC.navigationTitle = "Joined Trips"
            listVC.myTrip = viewModel.myTrips.value.filter {
                $0.participation.personalStatus != .completed &&
                $0.participation.personalStatus != .cancel &&
                $0.participation.role == .member
            }
        default:
            listVC.navigationTitle = "All of my Trips"
            listVC.myTrip = viewModel.myTrips.value
            
        }
        navigationController?.pushViewController(listVC, animated: true)
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
