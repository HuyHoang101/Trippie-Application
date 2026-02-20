//
//  UIApplication+Ext.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 19/2/26.
//


import UIKit

// Công cụ giúp tìm ra màn hình nào đang hiện trên cùng của App
extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
