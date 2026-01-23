//
//  TaskModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/22/26.
//

import Combine
import Foundation

@MainActor
class TaskViewModel {
    
    // MARK: - OUTPUT (Bindings)
    // source-of-truth for TableView/CollectionView
    let tasks = CurrentValueSubject<[TaskOfTrip], Never>([])
    let loading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = PassthroughSubject<String, Never>()
    let editingTask = CurrentValueSubject<TaskOfTrip?, Never>(nil)
    
    
    // MARK: - PRIVATE PROPERTIES
    // singleton shared
    private let taskService = TaskService.shared
    private let cancellables = Set<AnyCancellable>()
    
    
    // MARK: - INIT
    init() {}
    
    
    // MARK: - ACTIONS (LOGIC)
    
    //1. FETCH TASK
    func fetchTask(tripId: String) {
        self.loading.send(true)
        
        Task {
            do {
                let resultTasks = try await taskService.fetchTaskByTripId(tripId: tripId)
                
                self.tasks.send(resultTasks)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    //2. CREATE/EDIT TASK
    func handSaveTask(task: TaskOfTrip, name: String) {
        self.loading.send(true)
        
        Task {
            do {
                if let tripId = editingTask.value?.tripId {
                    
                    let result = try await taskService.updateTask(tripId: tripId, task: task, name: name)
                    
                    var updatedTasks = tasks.value
                    updatedTasks.removeAll(where: {$0.id == result.id})
                    updatedTasks.append(result)
                    
                    let finalTasks = updatedTasks.sorted {
                        if $0.dayIndex == $1.dayIndex {
                            return $0.time < $1.time
                        }
                        return $0.dayIndex < $1.dayIndex
                    }
                    tasks.send(finalTasks)
                    editingTask.send(nil)
                    self.loading.send(false)
                    
                } else {
                    
                    let result = try await taskService.createTask(tripId: task.tripId, task: task)
                    
                    var updatedTasks = tasks.value
                    updatedTasks.append(result)
                    
                    let finalTasks = updatedTasks.sorted {
                        if $0.dayIndex == $1.dayIndex {
                            return $0.time < $1.time
                        }
                        return $0.dayIndex < $1.dayIndex
                    }
                    tasks.send(finalTasks)
                    self.loading.send(false)
                    
                }
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
    
    //3. DELETE TASK
    func deleteTask(tripId:String, taskId: String) {
        self.loading.send(true)
        Task {
            do {
                try await taskService.deleteTask(tripId: tripId, taskId: taskId)
                var updatedTask = tasks.value
                updatedTask.removeAll(where: {$0.id == taskId})
                tasks.send(updatedTask)
                self.loading.send(false)
            } catch {
                self.loading.send(false)
                self.errorMessage.send(error.localizedDescription)
            }
        }
    }
}
