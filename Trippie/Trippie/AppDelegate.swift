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
