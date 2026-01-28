//
//  RegisterViewModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import Foundation
import Combine

class RegisterViewModel {
    
    // MARK: - INPUT (State)
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    
    // MARK: - OUTPUT (Inline Errors)
    // Dùng String? -> Nếu nil là không lỗi, nếu có text là hiện lỗi đỏ
    @Published var nameError: String? = nil
    @Published var emailError: String? = nil
    @Published var phone: String? = nil
    @Published var passwordError: String? = nil
    @Published var confirmError: String? = nil
    
    
    // Global State
    let loading = CurrentValueSubject<Bool, Never>(false)
    let registerSuccess = PassthroughSubject<Void, Never>()
    // Vẫn giữ message chung để báo lỗi hệ thống (ví dụ: Mất mạng, Lỗi server)
    let generalErrorMessage = PassthroughSubject<String, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - INIT (Setup Auto-Clear Pipeline)
    init() {
        setupAutoClearErrors()
    }
    
    
    // MARK: - PIPE
    private func setupAutoClearErrors() {
        // CƠ CHẾ: Lắng nghe Input thay đổi -> Reset Error về nil ngay lập tức
        
        $name
            .dropFirst() // Bỏ qua lần emit đầu tiên khi khởi tạo
            .removeDuplicates()
            .sink { [weak self] _ in self?.nameError = nil }
            .store(in: &cancellables)
            
        $email
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.emailError = nil }
            .store(in: &cancellables)
            
        $password
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.passwordError = nil }
            .store(in: &cancellables)
            
        $confirmPassword
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.confirmError = nil }
            .store(in: &cancellables)
    }
    
    // MARK: - ACTIONS
    func register() {
        // Reset sạch lỗi cũ trước khi check mới (đề phòng)
        clearAllErrors()
        
        // 1. Validate toàn bộ form
        guard validateInput() else {
            return
        }
        
        // 2. Bắt đầu gọi API
        loading.send(true)
        
        Task {
            do {
                let _ = try await AuthService.shared.register(
                    email: self.email,
                    pass: self.password,
                    name: self.name,
                    phone: self.phone
                )
                
                await MainActor.run {
                    self.loading.send(false)
                    self.registerSuccess.send()
                }
            } catch {
                await MainActor.run {
                    self.loading.send(false)
                    self.handleFirebaseError(error)
                }
            }
        }
    }
    
    // MARK: - VALIDATION LOGIC
    private func validateInput() -> Bool {
        var isValid = true
        
        // 1. Check Name
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Please enter your full name."
            isValid = false
        }
        
        // 2. Check Email (Rỗng & Format)
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            emailError = "Please enter your email address."
            isValid = false
        } else if !isValidEmail(email) {
            emailError = "The email address is not in the correct format (e.g., abc@mail.com)."
            isValid = false
        }
        
        // 3. Check Password (Độ dài, ký tự)
        if password.isEmpty {
            passwordError = "Please enter the password."
            isValid = false
        } else if !isValidPasswordFormat(password) {
            passwordError = "Passwords must be at least 6 characters, include both letters and numbers."
            isValid = false
        }
        
        // 4. Check Confirm Password
        if confirmPassword.isEmpty {
            confirmError = "Please re-enter your password."
            isValid = false
        } else if password != confirmPassword {
            confirmError = "Password doesn't match."
            isValid = false
        }
        
        return isValid
    }
    
    private func clearAllErrors() {
        nameError = nil
        emailError = nil
        passwordError = nil
        confirmError = nil
    }
    
    // MARK: - REGEX HELPERS
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPasswordFormat(_ pass: String) -> Bool {
        if pass.count < 6 { return false }
        let letterRegex = ".*[A-Za-z]+.*" // Có chữ
        let numberRegex = ".*[0-9]+.*"    // Có số
        
        let letterTest = NSPredicate(format: "SELF MATCHES %@", letterRegex)
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        return letterTest.evaluate(with: pass) && numberTest.evaluate(with: pass)
    }
    
    private func handleFirebaseError(_ error: Error) {
        let nsError = error as NSError
        print("Register Error: \(nsError.localizedDescription)")
        
        // Map lỗi Firebase vào đúng dòng Input tương ứng
        if nsError.localizedDescription.contains("email address is already in use") {
            emailError = "Email is already in use."
        } else if nsError.localizedDescription.contains("password") {
            passwordError = "The password is invalid."
        } else {
            // Lỗi không xác định thì hiện popup chung
            generalErrorMessage.send("\(nsError.localizedDescription)")
        }
    }
}
