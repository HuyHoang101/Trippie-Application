//
//  NotificationService.swift
//  TrippieNotificationService
//
//  Created by hoang.nguyenh on 2/23/26.
//

import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            return
        }
        
        bestAttemptContent.title = "✅ " + bestAttemptContent.title
        
        let userInfo = request.content.userInfo
        
        // 1. Kiểm tra xem có phải thông báo Chat không
        guard let type = userInfo["type"] as? String, type == "chat_message" else {
            // Không phải chat thì hiện thông báo bình thường
            contentHandler(bestAttemptContent)
            return
        }
        
        // 2. Lấy thông tin người gửi từ Data payload
        let senderName = userInfo["senderName"] as? String ?? "Someone"
        let senderAvatarURL = userInfo["senderAvatar"] as? String ?? ""
        
        // 3. Chuẩn bị Avatar (Phải tải ảnh về máy trước khi nhét vào thông báo)
        var senderImage: INImage? = nil
        if let url = URL(string: senderAvatarURL),
           let imageData = try? Data(contentsOf: url) {
            senderImage = INImage(imageData: imageData)
        }
        
        // 4. Tạo đối tượng Người Gửi (INPerson)
        let senderHandle = INPersonHandle(value: userInfo["senderId"] as? String ?? "unknown", type: .unknown)
        let sender = INPerson(personHandle: senderHandle,
                              nameComponents: createNameComponents(from: senderName),
                              displayName: senderName,
                              image: senderImage,
                              contactIdentifier: nil,
                              customIdentifier: nil)
        
        // 5. Khởi tạo Intent để vẽ giao diện Chat
        let intent = INSendMessageIntent(recipients: nil,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: bestAttemptContent.body,
                                         speakableGroupName: nil,
                                         conversationIdentifier: userInfo["tripId"] as? String,
                                         serviceName: nil,
                                         sender: sender,
                                         attachments: nil)
        
        // 6. Cập nhật diện mạo thông báo (Ép iOS dùng giao diện Communication)
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { _ in
            do {
                let updatedContent = try bestAttemptContent.updating(from: intent)
                contentHandler(updatedContent)
            } catch {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Nếu tải ảnh quá lâu (quá 30s), iOS sẽ gọi hàm này. Ta cho hiện luôn thông báo cơ bản.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // Hàm phụ trợ cắt tên
    private func createNameComponents(from name: String) -> PersonNameComponents {
        var components = PersonNameComponents()
        components.givenName = name
        return components
    }
}
