//
//  NotificationViewModel.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 20/2/26.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class NotificationViewModel {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading: Bool = false
    @Published var isFetchingMore: Bool = false // Để View biết đang load thêm
    @Published var errorMessage: String? = nil
    
    private var lastDocument: DocumentSnapshot? = nil
    var isEndReached: Bool = false // Báo cho View biết đã hết data chưa
    
    func fetchInitialNotifications() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let result = try await NotificationService.shared.fetchNotifications(lastDocument: nil)
                self.notifications = result.notifications
                self.lastDocument = result.lastDoc
                self.isEndReached = result.notifications.count < 10
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadNextPage() {
        guard !isEndReached, !isFetchingMore else { return }
        isFetchingMore = true
        
        Task {
            do {
                let result = try await NotificationService.shared.fetchNotifications(lastDocument: lastDocument)
                self.notifications.append(contentsOf: result.notifications)
                self.lastDocument = result.lastDoc
                self.isEndReached = result.notifications.count < 10
                self.isFetchingMore = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isFetchingMore = false
            }
        }
    }
}
