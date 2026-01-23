//
//  MainTabCoordinator.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit

class MainTabCoordinator {
    var window: UIWindow
    var tabBarController: UITabBarController
    
    init(window: UIWindow) {
        self.window = window
        self.tabBarController = UITabBarController()
    }
    
    func start() {
        setupTabbarAppearance()
        
        let homeNav = createHomeNav()
        let myTripNav = createMyTripNav()
        let profileNav = createProfileNav()
        
        tabBarController.viewControllers = [homeNav, myTripNav, profileNav]
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    func createHomeNav() -> UINavigationController {
        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(systemName: "globe.asia.australia"), tag: 0)
        let nav = UINavigationController(rootViewController: homeVC)
        return nav
    }
    
    func createMyTripNav() -> UINavigationController {
        let mytripVC = MyTripViewController()
        mytripVC.tabBarItem = UITabBarItem(title: "My Trips", image: UIImage(systemName: "airplane.departure"), tag: 1)
        let nav = UINavigationController(rootViewController: mytripVC)
        return nav
    }
    
    func createProfileNav() -> UINavigationController {
        let profileVC = MyTripViewController()
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 2)
        let nav = UINavigationController(rootViewController: profileVC)
        return nav
    }
    
    private func setupTabbarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        UITabBar.appearance().tintColor = UIColor(named: "AuthBackground1")
        UITabBar.appearance().backgroundColor = .systemGray
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
