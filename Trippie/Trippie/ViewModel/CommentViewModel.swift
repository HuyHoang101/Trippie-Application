//
//  CommentModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Foundation
import Combine

@MainActor
class CommentViewModel {
    
    // MARK: - OUTPUT (Bindings)
    // source-of-truth for TableView/CollectionView
    let comments = CurrentValueSubject<[Comment], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    
    // MARK: - PRIVATE PROPERTIES
    // singleton shared to manage listener
    private let commentService = CommentService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentTripId: String?
    
    // MARK: - INIT
    init() {}
    
    // MARK: - ACTIONS (LOGIC)
    
    // 1. BẮT ĐẦU CHAT (Vào màn hình)
    func joinChatRoom(tripId: String) {
        self.currentTripId = tripId
        self.loading.send(true)
        
        // Gọi Service lắng nghe
        commentService.listenToLatestComments(tripId: tripId) { [weak self] newComments in
            guard let self = self else { return }
            
            // LOGIC QUAN TRỌNG:
            // Service trả về: [Vừa xong, 1 phút trước, 2 phút trước...]
            // UI cần: [2 phút trước, 1 phút trước, Vừa xong]
            // -> Phải .reversed()
            let sortedComments = newComments.reversed()
            
            // Update UI
            self.comments.send(Array(sortedComments))
            self.loading.send(false)
        }
    }
    
    // 2. KÉO LÊN ĐỂ TẢI CŨ HƠN (Load More)
    func loadHistory() {
        guard let tripId = currentTripId else { return }
        
        Task {
            do {
                // Fetch tin nhắn cũ
                let olderComments = try await commentService.fetchOlderComments(tripId: tripId)
                
                if olderComments.isEmpty { return } // Hết dữ liệu
                
                // Logic ghép mảng: [Cũ Rích -> Cũ Vừa] + [Hiện Tại]
                let sortedOlder = olderComments.reversed()
                let currentList = self.comments.value
                let newList = sortedOlder + currentList
                
                self.comments.send(newList)
                
            } catch {
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // 3. GỬI TIN NHẮN
    func sendComment(message: String, user: User, mediaUrls: [String] = []) {
        guard let tripId = currentTripId, !message.isEmpty || !mediaUrls.isEmpty else { return }
        
        // Tạo model Comment
        let newComment = Comment(
            id: nil, // Firebase tự sinh
            userId: user.id ?? "",
            userName: user.name,
            userAvatar: user.avatarUrl, // Giả sử model User có field này
            role: .member, // Hoặc check logic owner
            mediaUrls: mediaUrls,
            message: message,
            createdAt: nil, // Server timestamp
            updatedAt: nil
        )
        
        // Gọi Service (Fire & Forget)
        // Không cần append thủ công vào list comments vì hàm listenToLatestComments ở trên sẽ tự bắt được event này
        Task {
            do {
                try await commentService.sendComment(tripId: tripId, comment: newComment)
            } catch {
                self.errorMessage.send("Gửi thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // 4. XOÁ TIN NHẮN (Soft Delete)
    func deleteComment(comment: Comment) {
        guard let tripId = currentTripId, let commentId = comment.id else { return }
        
        Task {
            do {
                try await commentService.softDeleteComment(tripId: tripId, commentId: commentId)
            } catch {
                self.errorMessage.send("Xoá thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    // 5. THOÁT MÀN HÌNH
    func leaveChatRoom() {
        commentService.removeListener()
        // Reset data để lần sau vào không bị hiện tin nhắn cũ của room trước
        comments.send([])
    }
    
}
