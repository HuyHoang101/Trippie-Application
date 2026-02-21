//
//  AppDelegate.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/19/26.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import FacebookCore
import FBSDKCoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            
        let userInfo = response.notification.request.content.userInfo
        
        // Quăng data sang cho NotificationNavigator xử lý
        NotificationNavigator.shared.handleTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            
        let userInfo = notification.request.content.userInfo
        
        // 1. Kiểm tra nếu đây là thông báo Chat
        if let type = userInfo["type"] as? String, type == "chat_message",
           let tripId = userInfo["tripId"] as? String {
            
            // 2. Hỏi ông quản lý xem có đang mở phòng chat này không?
            if ChatStateManager.shared.isListening(to: tripId) {
                print("🤫 Đang ở trong phòng chat \(tripId), chặn hiển thị thông báo rác!")
                // Trả về mảng rỗng [] -> Tức là Bịt miệng nó luôn (Không rung, không kêu, không banner)
                completionHandler([])
                return
            }
        }
        
        // 3. Nếu là thông báo khác (New Request, Trip Reminder...) HOẶC đang ở màn hình Home -> Cho phép hiện bình thường
        completionHandler([.banner, .sound, .badge])
    }
    
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: - FIREBASE MESSAGING DELEGATES

    // 2. Hàm này nhận APNs Token từ Apple và đưa cho Firebase
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 3. Hàm này hứng FCM Token từ Firebase và tự động gọi hàm lưu lên Server
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📍 Nhận được FCM Token: \(fcmToken ?? "nil")")
        // Tự động gọi hàm update của cậu
        Task {
            try? await UserService.shared.registerAppFCMToken()
        }
    }
}
