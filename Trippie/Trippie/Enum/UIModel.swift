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
    case time
    
}


enum ConfirmActionType {
    case deleteTrip
    case delete
    case cancel
    case cancelTaskEdit
    case cancelTaskDelete
    case deny
    case kick
    case add
    case follow
    case unfollow
    case remove
    case clear
    case leave
    
    var color: UIColor {
        switch self {
        case .leave, .deleteTrip, .delete, .kick, .deny, .unfollow, .remove : return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        case .cancel, .cancelTaskEdit, .cancelTaskDelete: return #colorLiteral(red: 0.9529411793, green: 0.5595523814, blue: 0.2865278571, alpha: 1)
        case .add: return UIColor.button
        case .follow: return UIColor.authBackground2
        case .clear: return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        }
    }
    
    var iconName: String {
        switch self {
        case .deleteTrip: return "trash.fill"
        case .delete: return "trash.fill"
        case .cancel: return "xmark.circle.fill"
        case .cancelTaskDelete: return "arrow.uturn.backward"
        case .cancelTaskEdit: return "arrow.uturn.backward"
        case .deny: return "hand.raised.fill"
        case .kick: return "person.fill.xmark"
        case .add: return "person.fill.checkmark"
        case .follow: return "person.badge.plus"
        case .unfollow: return "person.badge.minus"
        case .remove: return "arrow.down.document"
        case .clear: return "sparkles.rectangle.stack.fill"
        case .leave: return "figure.walk.departure"
        }
    }
    
    var verb: String {
        switch self {
        case .deleteTrip: return "delete this Trip?"
        case .delete: return "delete"
        case .cancel: return "cancel"
        case .cancelTaskEdit: return "go back to previous page? This task has been edited by someone."
        case .cancelTaskDelete: return "go back to previous page? This task has been deleted by someone."
        case .deny: return "deny"
        case .kick: return "kick"
        case .add: return "add"
        case .follow: return "follow"
        case .unfollow: return "unfollow"
        case .remove: return "remove this trip from the feed board?"
        case .clear: return "clear cache of the app?"
        case .leave: return "leave"
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
        case clear
        case destructive
    }
}


enum ListTaskMode {
    case normal
    case edit
    case delete
}

enum ApplyTripAction {
    case join
    case full
    case cancelJoin
    case leave
}


enum ActionAceptPersonJoinTrip {
    case acept
    case deny
    case kick
    case normal
}


enum UserListType {
    case allUsers       // Tìm kiếm tất cả user
    case tripMembers    // Thành viên trong chuyến đi
    case friends        // Bạn bè
    case pendingRequest
    case tripMemberForAnotherLooking
}
