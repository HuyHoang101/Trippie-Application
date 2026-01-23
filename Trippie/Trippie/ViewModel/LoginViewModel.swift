//
//  LoginViewModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import Foundation
import Combine
import FirebaseAuth

class LoginViewModel {
    
    // MARK: - OUTPUT
    
    let loading = CurrentValueSubject<Bool, Never>(false)

    let errorMessage = PassthroughSubject<String, Never>()

    let loginSuccess = PassthroughSubject<Void, Never>()
    
    // Validate message
    let emailvalidation = PassthroughSubject<String, Never>()
    let passwordvalidation = PassthroughSubject<String, Never>()
    
    // MARK: - PROPERTIES
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ACTIONS
    func login(email: String, pass: String) {
        // 1. Validate cơ bản trước khi gọi Service
        guard validateInput(email: email, pass: pass) else { return }
        
        // 2. Bắt đầu Loading
        loading.send(true)
        
        // 3. Gọi Service (Async/Await)
        Task {
            do {
                // Giả lập delay 1 xíu để kịp nhìn thấy animation xe bus (tuỳ chọn)
                // try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                try await AuthService.shared.login(email: email, pass: pass)
                
                // Thành công -> Báo về Main Thread
                await MainActor.run {
                    self.loading.send(false)
                    self.loginSuccess.send()
                }
            } catch {
                // Thất bại -> Xử lý lỗi
                await MainActor.run {
                    self.loading.send(false)
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - HELPER
    private func validateInput(email: String, pass: String) -> Bool {
        if email.isEmpty {
            emailvalidation.send("Please, enter your email.")
            return false
        }
        if pass.isEmpty {
            passwordvalidation.send("Please, enter your password.")
            return false
        }
        // Có thể thêm check regex email ở đây nếu muốn kỹ hơn
        return true
    }
    
    private func handleError(_ error: Error) {
        // Dịch lỗi Firebase sang tiếng người dùng dễ hiểu
        let nsError = error as NSError
        
        // Cậu có thể map các mã lỗi của Firebase Auth tại đây
        // Ví dụ: AuthErrorCode.wrongPassword...
        // Tạm thời hiển thị message gốc hoặc text chung
        print("Login Error: \(nsError.localizedDescription)")
        passwordvalidation.send("Login failed, check your account again.")
    }
}
