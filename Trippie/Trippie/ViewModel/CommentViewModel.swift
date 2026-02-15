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
    let newMessagesCount = CurrentValueSubject<Int, Never>(0)
    private var isFirstLoad = true
    
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
            
            let incomingSorted = Array(newComments.reversed())
            
            if self.isFirstLoad {
                // Lần đầu tiên listener chạy (tải lịch sử chat) -> Không đếm
                self.isFirstLoad = false
                self.comments.send(incomingSorted)
            } else {
                var currentList = self.comments.value
                var newlyAddedCount = 0
                
                for incoming in incomingSorted {
                    if let index = currentList.firstIndex(where: { $0.id == incoming.id }) {
                        // Nếu tin nhắn đã tồn tại -> Cập nhật nội dung (Dành cho trường hợp Edit/Xóa)
                        currentList[index] = incoming
                    } else {
                        // Nếu chưa tồn tại -> Đích thị là tin nhắn mới tinh -> Thêm vào cuối mảng
                        currentList.append(incoming)
                        newlyAddedCount += 1
                    }
                }
                if newlyAddedCount > 0 {
                    let currentUnread = self.newMessagesCount.value
                    self.newMessagesCount.send(currentUnread + newlyAddedCount)
                }
                currentList.sort { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
                self.comments.send(currentList)
            }
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
                let currentList = self.comments.value
                                
                // TẤM KHIÊN BẢO VỆ: Chỉ lấy những tin nhắn CŨ CHƯA TỪNG XUẤT HIỆN trên UI
                let uniqueOlderComments = olderComments.filter { older in
                    !currentList.contains(where: { $0.id == older.id })
                }
                
                let sortedOlder = Array(uniqueOlderComments.reversed())
                let newList = sortedOlder + currentList
                
                self.comments.send(newList)
                
            } catch {
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // 3. GỬI TIN NHẮN
    func sendComment(message: String = "", imgUrls: [String] = [], videoUrl: String = "", thumbnailUrl: String = "") {
        guard let tripId = currentTripId, !message.isEmpty || !imgUrls.isEmpty || !videoUrl.isEmpty else { return }
        guard let user = UserViewModel.shared.myProfile.value else { return }
        
        // Tạo model Comment
        let newComment = Comment(
            id: nil, // Firebase tự sinh
            userId: user.id ?? "",
            userName: user.name,
            userAvatar: user.avatarUrl, // Giả sử model User có field này
            role: .member, // Hoặc check logic owner
            imageUrls: imgUrls,
            videoUrl: videoUrl,
            videoThumbnail: thumbnailUrl,
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
