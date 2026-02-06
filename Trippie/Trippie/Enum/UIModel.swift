//
//  UIModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//
import UIKit

enum TrippieImageStyle {
    case circle // Tròn xoe (Avatar)
    case rounded(radius: CGFloat, corners: CACornerMask?) // Bo góc tuỳ chỉnh (Post ảnh)
}


enum InputStyle {
    case email
    case password
    case phoneNumber // Bàn phím số
    case date        // Chọn ngày tháng từ lịch
    case text
    case country
}


enum ConfirmActionType {
    case delete
    case cancel
    case deny
    case kick
    case add
    case follow
    case unfollow
    
    var color: UIColor {
        switch self {
        case .delete, .kick, .deny, .unfollow : return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        case .cancel: return #colorLiteral(red: 0.9529411793, green: 0.5595523814, blue: 0.2865278571, alpha: 1)
        case .add: return UIColor.button
        case .follow: return UIColor.authBackground2
        }
    }
    
    var iconName: String {
        switch self {
        case .delete: return "trash.fill"
        case .cancel: return "xmark.circle.fill"
        case .deny: return "hand.raised.fill"
        case .kick: return "person.fill.xmark"
        case .add: return "person.fill.checkmark"
        case .follow: return "person.badge.plus"
        case .unfollow: return "person.badge.minus"
        }
    }
    
    var verb: String {
        switch self {
        case .delete: return "delete"
        case .cancel: return "cancel"
        case .deny: return "deny"
        case .kick: return "kick"
        case .add: return "add"
        case .follow: return "follow"
        case .unfollow: return "unfollow"
        }
    }
}


struct DropdownItem {
    let title: String
    let icon: String?
    let type: ItemType
    let action: () -> Void
    
    enum ItemType {
        case normal
        case destructive
    }
}
