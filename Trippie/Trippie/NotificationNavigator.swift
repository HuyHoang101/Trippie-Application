//
//  NotificationNavigator.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 19/2/26.
//

import UIKit
import FirebaseAuth // Để check xem đã đăng nhập chưa

class NotificationNavigator {
    static let shared = NotificationNavigator()
    
    // Biến để lưu tạm thông báo nếu app vừa mới khởi động (đang ở Splash)
    var pendingUserInfo: [AnyHashable: Any]?
    
    // Hàm này sẽ được gọi khi người dùng BẤM vào thông báo
    func handleTap(userInfo: [AnyHashable: Any]) {
        // 1. Phải chắc chắn đã đăng nhập
        guard Auth.auth().currentUser != nil else { return }
        
        // 2. Tìm xem app đang hiển thị màn hình nào
        guard let topVC = UIApplication.topViewController() else { return }
        
        // 3. NẾU ĐANG Ở SPLASH SCREEN -> Lưu tạm lại chờ Splash xong mới xử lý
        if topVC is SplashViewController {
            self.pendingUserInfo = userInfo
            return
        }
        
        // 4. NẾU ĐÃ VÀO APP RỒI -> Xử lý push màn hình luôn
        executeNavigation(userInfo: userInfo, from: topVC)
    }
    
    // Hàm này sẽ được AppCoordinator gọi sau khi Splash chạy xong
    func executePendingNotificationIfNeeded() {
        if let userInfo = pendingUserInfo {
            if let topVC = UIApplication.topViewController() {
                executeNavigation(userInfo: userInfo, from: topVC)
            }
            // Xử lý xong thì dọn dẹp biến tạm
            pendingUserInfo = nil
        }
    }
    
    // Hàm lõi: Quyết định Push vào đâu dựa vào "type"
    private func executeNavigation(userInfo: [AnyHashable: Any], from topVC: UIViewController) {
        guard let type = userInfo["type"] as? String,
              let tripId = userInfo["tripId"] as? String else { return }
        
        // Chờ 0.5s để UI của Main/Home kịp dựng lên hoàn toàn rồi mới push
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            switch type {
            case "chat_message":
                print("🔵 Push vào phòng Chat của Trip: \(tripId)")
                // VD:
                // let chatVC = ChatViewController(tripId: tripId)
                // topVC.navigationController?.pushViewController(chatVC, animated: true)
                
                let chatVC = GroupMessageViewController()
                chatVC.tripId = tripId
                
                let viewModel = CommentViewModel()
                viewModel.joinChatRoom(tripId: tripId)
                viewModel.fetchAllImage(tripId: tripId)
                viewModel.fetchAllVideo(tripId: tripId)
                
                chatVC.commentViewModel = viewModel
                chatVC.navigationTitle = "Message"
                
                topVC.navigationController?.pushViewController(chatVC, animated: true)
                
            case "new_request", "status_change":
                print("🟢 Push vào chi tiết Trip / Yêu cầu tham gia của Trip: \(tripId)")
                let detailVC = DetailViewController()
                detailVC.id = tripId
                detailVC.isFeedBoard = true
                detailVC.navigationTitle = "Trip Detail"
                
                topVC.navigationController?.pushViewController(detailVC, animated: true)

            case "trip_reminder":
                print("🟠 Push vào màn hình Checklist/Hành trang của Trip: \(tripId)")
                let detailVC = DetailViewController()
                detailVC.id = tripId
                detailVC.isFeedBoard = false
                detailVC.navigationTitle = "Trip Detail"
                
                topVC.navigationController?.pushViewController(detailVC, animated: true)
            default:
                break
            }
        }
    }
}
