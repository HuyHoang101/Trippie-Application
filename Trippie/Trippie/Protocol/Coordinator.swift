//
//  Coordinator.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import UIKit

protocol Coordinator {
    var navigationController: UINavigationController { get set }
    func start()
}
