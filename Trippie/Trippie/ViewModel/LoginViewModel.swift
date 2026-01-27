//
//  LoginViewModel.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/23/26.
//

import Foundation
import Combine

class LoginViewModel {
    
    // MARK: - INPUT (State)
    @Published var email: String = ""
    @Published var password: String = ""
    
    // MARK: - OUTPUT (Inline Errors)
    @Published var emailError: String? = nil
    @Published var passwordError: String? = nil
    
    // Global State
    let loading = CurrentValueSubject<Bool, Never>(false)
    let loginSuccess = PassthroughSubject<Void, Never>()
    let logoutSuccess = PassthroughSubject<Void, Never>()
    let generalErrorMessage = PassthroughSubject<String, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - INIT
    init() {
        setupAutoClearErrors()
    }
    
    // MARK: - PIPE (Auto-Clear)
    private func setupAutoClearErrors() {
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
    }
    
    // MARK: - ACTIONS
    
    // 1. LOGIN
    func login() {
        emailError = nil
        passwordError = nil
        
        guard validateInput() else { return }
        
        loading.send(true)
        
        Task {
            do {
                try await AuthService.shared.login(email: self.email, pass: self.password)
                
                await MainActor.run {
                    self.loading.send(false)
                    self.loginSuccess.send()
                }
            } catch {
                await MainActor.run {
                    self.loading.send(false)
                    self.handleError(error)
                }
            }
        }
    }
    
    // 2. LOGOUT
    func logout() {
        Task {
            do {
                try AuthService.shared.logout()
                await MainActor.run {
                    self.logoutSuccess.send()
                }
            } catch {
                await MainActor.run {
                    self.generalErrorMessage.send(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - HELPER
    private func validateInput() -> Bool {
        var isValid = true
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            emailError = "Please enter your email."
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = "Please enter your password."
            isValid = false
        }
        
        return isValid
    }
    
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        let message = nsError.localizedDescription
        
        // Map lỗi
        if message.contains("invalid-credential") || message.contains("wrong-password") {
            passwordError = "Invalid email or password."
        } else {
            generalErrorMessage.send(message)
        }
    }
}
