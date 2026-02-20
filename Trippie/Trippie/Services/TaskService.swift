//
//  TaskService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Foundation
import FirebaseFirestore

class TaskService {
    static let shared = TaskService()
    private let db = Firestore.firestore()
    
    // MARK: - 1. LISTEN TO TASKS (REALTIME)
    func listenToTasks(tripId: String, completion: @escaping (Result<[TaskOfTrip], Error>) -> Void) -> ListenerRegistration {
        
        let query = db.collection("trips")
            .document(tripId)
            .collection("tasks")
        
        // Dùng addSnapshotListener thay vì getDocuments
        let listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            // 1. Map data thô từ Firestore
            var tasks = documents.compactMap { try? $0.data(as: TaskOfTrip.self) }
            
            // 2. Xử lý User Hydration (Lấy thông tin người tạo)
            // Vì listener chạy đồng bộ mà fetchUser lại là async, ta phải bọc vào Task
            Task {
                // Cache cục bộ trong lần listen này để tránh gọi thừa
                var userCache: [String: User] = [:]
                
                for i in 0..<tasks.count {
                    let creatorId = tasks[i].creatorId
                    
                    // Nếu user này đã fetch trong vòng lặp này rồi thì dùng lại luôn
                    if let cachedUser = userCache[creatorId] {
                        tasks[i].userName = cachedUser.name
                        tasks[i].userAvatar = cachedUser.avatarUrl
                        continue
                    }
                    
                    // Nếu chưa có, gọi Service (hoặc cache từ Service)
                    // Lưu ý: UserService nên có cơ chế cache memory để tránh spam server
                    do {
                        let user = try await UserService.shared.fetchUserById(id: creatorId)
                        userCache[creatorId] = user
                        tasks[i].userName = user.name
                        tasks[i].userAvatar = user.avatarUrl
                    } catch {
                        print("⚠️ Lỗi fetch user cho task: \(error.localizedDescription)")
                    }
                }
                
                // 3. Sắp xếp: Theo ngày (Day 1, 2..) -> Theo giờ
                let sortedTasks = tasks.sorted {
                    if $0.dayIndex == $1.dayIndex {
                        return $0.time < $1.time
                    }
                    return $0.dayIndex < $1.dayIndex
                }
                
                // 4. Trả về Main Thread
                DispatchQueue.main.async {
                    completion(.success(sortedTasks))
                }
            }
        }
        
        return listener
    }
    
    // MARK: - 2. CREATE TASK
    func createTask(tripId: String, task: TaskOfTrip) async throws {
        let collectionRef = db.collection("trips").document(tripId).collection("tasks")
        
        let newDocRef = collectionRef.document()
        var taskWithId = task
        taskWithId.id = newDocRef.documentID
        
        try newDocRef.setData(from: taskWithId)
        // Không cần return Task nữa vì Listener ở trên sẽ tự động bắn data mới về
    }
    
    // MARK: - 3. EDIT TASK
    func updateTask(tripId: String, task: TaskOfTrip, name: String, isEdit: Bool = true) async throws {
        guard let taskId = task.id else { return }
        
        var updatedTask = task
        if isEdit {
            updatedTask.editBy = name
            updatedTask.updatedAt = Date()
        }
        
        let docRef = db.collection("trips")
            .document(tripId)
            .collection("tasks")
            .document(taskId)
            
        try docRef.setData(from: updatedTask, merge: true)
    }
    
    // MARK: - 4. DELETE TASK
    func deleteTask(tripId: String, taskId: String) async throws {
        let docRef = db.collection("trips")
            .document(tripId)
            .collection("tasks")
            .document(taskId)
            
        try await docRef.delete()
    }
}
