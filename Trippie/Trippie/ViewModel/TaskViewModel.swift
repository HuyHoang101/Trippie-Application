//
//  TaskModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Combine
import Foundation
import FirebaseFirestore

@MainActor
class TaskViewModel {
    
    // MARK: - OUTPUT (Bindings)
    let tasks = CurrentValueSubject<[TaskOfTrip], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    let editingTask = CurrentValueSubject<TaskOfTrip?, Never>(nil)
    
    // MARK: - PRIVATE PROPERTIES
    private let taskService = TaskService.shared
    private var listener: ListenerRegistration? // Giữ chìa khoá kết nối
    
    // MARK: - INIT
    // Không còn static shared, mỗi lần dùng là new ra một cái mới
    init() {}
    
    // MARK: - REALTIME ACTIONS
    
    // 1. BẮT ĐẦU NGHE (Gọi khi vào màn hình)
    func startListening(tripId: String) {
        self.loading.send(true)
        
        // Đảm bảo ngắt cái cũ trước khi nghe cái mới
        stopListening()
        
        listener = taskService.listenToTasks(tripId: tripId) { [weak self] result in
            guard let self = self else { return }
            
            // Tắt loading khi nhận data đầu tiên
            if self.loading.value { self.loading.send(false) }
            
            switch result {
            case .success(let data):
                self.tasks.send(data)
            case .failure(let error):
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    // 2. NGẮT KẾT NỐI (Gọi khi back ra)
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - CRUD ACTIONS
    
    // MARK: - 3. CREATE / EDIT TASK (logic check conflict)
    // Thay đổi signature: Thêm async và kiểu trả về (Bool, String)
    func handSaveTask(task: TaskOfTrip, name: String) async -> (Bool, String) {
        self.loading.send(true)
        let isEdit = !(editingTask.value == nil)
        // --- BƯỚC 1: KIỂM TRA ĐIỀU KIỆN (VALIDATION) ---
        if isEdit, let tripId = editingTask.value?.tripId, let taskId = task.id {
            
            // Lấy task realtime mới nhất từ danh sách đang nghe
            // (tasks.value luôn được cập nhật bởi listener)
            let currentRealtimeTask = tasks.value.first(where: { $0.id == taskId })
            
            // CASE 1: Task không còn tồn tại trong list (Ai đó đã xoá)
            guard let liveTask = currentRealtimeTask else {
                self.loading.send(false)
                return (false, "This job no longer exists.")
            }
            
            // CASE 2: Task đã bị người khác sửa nội dung
            // So sánh 'updatedAt' của bản realtime với bản snapshot lúc mình bắt đầu sửa
            if let snapshot = editingTask.value, liveTask.updatedAt != snapshot.updatedAt {
                self.loading.send(false)
                return (false, "This task has just been edited.")
            }
        }
        
        // --- BƯỚC 2: GỌI SERVER ---
        do {
            if let tripId = editingTask.value?.tripId {
                // --- CASE EDIT ---
                try await taskService.updateTask(tripId: tripId, task: task, name: name, isEdit: isEdit)
                
                self.showToast(message: "Updated Task Successfully!", isSuccess: true)
                self.editingTask.send(nil) // Reset trạng thái edit
                
            } else {
                // --- CASE CREATE ---
                try await taskService.createTask(tripId: task.tripId, task: task)
                self.showToast(message: "Create Task Successfully!", isSuccess: true)
            }
            
            self.loading.send(false)
            return (true, "Success")
            
        } catch {
            self.loading.send(false)
            self.handleError(error, context: "Save Task")
            return (false, error.localizedDescription)
        }
    }

    
    
    func deleteTask(tripId: String, taskId: String) {
        self.loading.send(true)
        Task {
            do {
                try await taskService.deleteTask(tripId: tripId, taskId: taskId)
                self.showToast(message: "Delete Task Successfully!", isSuccess: true)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.handleError(error, context: "Delete Task")
            }
        }
    }
    
    // MARK: - HELPER
    private func showToast(message: String, isSuccess: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: .showGlobalToast,
                object: nil,
                userInfo: ["message": message, "isSuccess": isSuccess]
            )
        }
    }
    
    private func handleError(_ error: Error, context: String) {
        self.errorMessage.send(error.localizedDescription)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: .showGlobalToast,
                object: nil,
                userInfo: ["message": "\(context) failed: \(error.localizedDescription)", "isSuccess": false]
            )
        }
    }
}
