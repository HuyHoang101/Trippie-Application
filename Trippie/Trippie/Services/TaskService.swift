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
    
    // MARK: - 1. FETCH TASKS (BY TRIP ID)
    func fetchTaskByTripId(tripId: String) async throws -> [TaskOfTrip] {
        let snapshot = try await db.collection("trips")
            .document(tripId)
            .collection("tasks")
            .getDocuments()
        
        let tasks = snapshot.documents.compactMap { try? $0.data(as: TaskOfTrip.self) }
        
        // Sort: day (Day 1, Day 2...) and time (07:00, 12:00...)
        return tasks.sorted {
            if $0.dayIndex == $1.dayIndex {
                return $0.time < $1.time
            }
            return $0.dayIndex < $1.dayIndex
        }
    }
    
    // MARK: - 2. CREATE TASK
    func createTask(tripId: String, task: TaskOfTrip) async throws -> TaskOfTrip {
        let collectionRef = db.collection("trips").document(tripId).collection("tasks")
                
        // 1. Tạo một Document Reference mới (Lúc này ID đã được sinh ra ở máy Client)
        let newDocRef = collectionRef.document()
        
        // 2. Gán ID vừa sinh ra vào Task object
        var taskWithId = task
        taskWithId.id = newDocRef.documentID
        
        // 3. Lưu dữ liệu lên Firestore
        try newDocRef.setData(from: taskWithId)
        
        // 4. Trả về Task
        return taskWithId
    }
    
    // MARK: - 3. EDIT TASK
    func updateTask(tripId: String, task: TaskOfTrip, name: String) async throws -> TaskOfTrip {
        guard let taskId = task.id else {
            throw NSError(domain: "TaskService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Task ID not found"])
        }
        
        var updatedTask = task
        updatedTask.updatedAt = Date() // Cập nhật thời gian sửa
        updatedTask.editBy = name
        
        let docRef = db.collection("trips")
            .document(tripId)
            .collection("tasks")
            .document(taskId)
            
        try docRef.setData(from: updatedTask, merge: true)
        
        return updatedTask
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
