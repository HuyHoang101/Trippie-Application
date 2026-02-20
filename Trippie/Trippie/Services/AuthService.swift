//
//  AuthService.swift
//  Trippie
//
//  Created by hoang.nguyenh on 1/21/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FacebookLogin
import FirebaseCore
internal import FBSDKLoginKit
import FirebaseMessaging

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    // Key để lưu vào UserDefaults
    private let userDefaultsKey = "cached_user_id"
    private let userDefaultsName = "cached_user_name"
    private let userDefaultsAvatar = "cached_user_avatar"
    
    // --- 1. REGISTER ---
    func register(email: String, pass: String, name: String, phone: String? = nil) async throws -> User {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: pass)
        let uid = authResult.user.uid
        
        let newUser = User(
            id: uid,
            avatarUrl: "",
            name: name,
            email: email,
            phone: phone ?? "",
            address: "",
            aboutMe: "New member of Trippie",
            rating: 0.0,
            ratingCount: 0,
            friendIds: [],
            fcmToken: "",
            createdAt: Date(), // Gán tạm local
            updatedAt: Date()
        )
        
        try db.collection("users").document(uid).setData(from: newUser)
        
        // Lưu UID vào cache sau khi đăng ký thành công
        saveUserToCache(uid: uid)
        saveUserNameToCache(name: name)
        
        return newUser
    }
    
    // --- 2. LOGIN ---
    func login(email: String, pass: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: pass)
        let user = try await UserService.shared.fetchUserById(id: result.user.uid)
        // Đăng nhập xong thì lưu ID vào cache ngay
        saveUserToCache(uid: result.user.uid)
        saveUserNameToCache(name: user.name)
        saveUserAvatarToCache(avatarUrl: user.avatarUrl)
    }
    
    // --- 3. LOGOUT ---
    func logout() async throws {
        // Xoá sạch dấu vết trong cache khi logout
        guard let userUid = AuthService.shared.currentUserId else { return }
        let db = Firestore.firestore()
        try await db.collection("users").document(userUid).updateData([
            "fcmToken": ""
        ])
        // 2. Xoá token rác bên trong SDK Firebase để reset hoàn toàn
        try? await Messaging.messaging().deleteToken()
        UserDefaults.standard.removeObject(forKey: "fcm_token_\(userUid)")
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsName)
        UserDefaults.standard.removeObject(forKey: userDefaultsAvatar)
        try Auth.auth().signOut()
    }
    
    // --- 4. CHECK USER (OPTIMIZED) ---
    // Hàm này sẽ trả về UID của user hiện tại
    var currentUserId: String? {
        // Ưu tiên 1: Check trong UserDefaults trước (Siêu nhanh)
        if let cachedId = UserDefaults.standard.string(forKey: userDefaultsKey) {
            return cachedId
        }
        
        // Ưu tiên 2: Nếu cache trống (app bị xoá/reinstall), check Firebase Auth
        if let firebaseUser = Auth.auth().currentUser {
            // Tiện tay lưu lại vào cache cho lần sau
            saveUserToCache(uid: firebaseUser.uid)
            return firebaseUser.uid
        }
        
        return nil
    }
    
    // MARK: - Google Sign In
        func signInWithGoogle(presenting: UIViewController) async throws -> User {
            // 1. Kiểm tra ClientID từ Firebase Config
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình GoogleService-Info.plist"])
            }
            
            // 2. Cấu hình Google Sign In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // 3. Mở popup đăng nhập và chờ kết quả
            // Lưu ý: Nếu user bấm hủy ở đây, nó sẽ ném lỗi, cậu catch ở UI nhé
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            
            // 4. Lấy ID Token và Access Token từ Google
            let user = result.user
                    
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không lấy được ID Token từ Google"])
            }
            
            // 5. Tạo Credential để gửi cho Firebase
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // 6. Đăng nhập vào Firebase Auth
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // 7. Gọi hàm check logic (Lần đầu/Lần sau)
            let trippieUser = try await handleCheckFirstLogin(firebaseUser: authResult.user)
            
            // 8. Quan trọng: Lưu Cache để app biết đã login
            saveUserToCache(uid: trippieUser.id ?? "")
            saveUserNameToCache(name: trippieUser.name)
            saveUserAvatarToCache(avatarUrl: trippieUser.avatarUrl)
            
            return trippieUser
        }

        // MARK: - Facebook Sign In
        func signInWithFacebook(presenting: UIViewController) async throws -> User {
            let loginManager = LoginManager()
            
            // 1. Mở popup Facebook (Xin quyền public_profile và email)
            // Vì LoginManager của FB chưa hỗ trợ async/await chuẩn, ta phải bọc nó lại bằng withCheckedThrowingContinuation
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LoginManagerLoginResult, Error>) in
                loginManager.logIn(permissions: ["public_profile", "email"], from: presenting) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let result = result, !result.isCancelled else {
                        // User tự bấm nút Cancel
                        continuation.resume(throwing: NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User huỷ đăng nhập Facebook"]))
                        return
                    }
                    continuation.resume(returning: result)
                }
            }
            
            // 2. Lấy Access Token hiện tại
            guard let token = AccessToken.current?.tokenString else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Lỗi Facebook Access Token"])
            }
            
            // 3. Tạo Credential
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            // 4. Đăng nhập vào Firebase Auth
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                // Nếu thành công (chưa có Google, hoặc đã link rồi) -> Vào luôn
                let trippieUser = try await handleCheckFirstLogin(firebaseUser: authResult.user)
                
                // 6. Lưu Cache
                saveUserToCache(uid: trippieUser.id ?? "")
                saveUserNameToCache(name: trippieUser.name)
                saveUserAvatarToCache(avatarUrl: trippieUser.avatarUrl)
                
                return trippieUser
                
            } catch let error as NSError {
                // 4. BẮT LỖI: TÀI KHOẢN ĐÃ TỒN TẠI
                if error.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
                    
                    print("⚠️ Email này đã tồn tại ở phương thức khác. Đang thử liên kết với Google...")
                    
                    // --- THAY ĐỔI Ở ĐÂY ---
                    // Không dùng fetchSignInMethods nữa.
                    // Ta mặc định thử đăng nhập Google để xác minh chủ sở hữu (Vì cậu chỉ có Google và FB là chính).
                    // Nếu App cậu có cả Password, cậu nên hiện Alert cho user chọn: "Bạn muốn xác minh bằng Google hay Mật khẩu?"
                    
                    do {
                        // 1. Yêu cầu đăng nhập Google để chứng minh là chủ tài khoản
                        // (Hàm này sẽ trả về User Google đang active)
                        let _ = try await signInWithGoogle(presenting: presenting)
                        
                        // 2. Nếu đăng nhập Google thành công -> Lấy User đó ra
                        if let currentUser = Auth.auth().currentUser {
                            
                            // 3. Nối cái Facebook Credential (biến 'credential' ở trên) vào tài khoản Google này
                            let linkResult = try await currentUser.link(with: credential)
                            
                            print("✅ Đã liên kết Facebook vào Google thành công!")
                            return try await handleCheckFirstLogin(firebaseUser: linkResult.user)
                        }
                    } catch {
                        // Nếu login Google cũng thất bại (User tắt popup hoặc không phải acc Google)
                        throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Vui lòng đăng nhập bằng phương thức gốc (Google/Email) trước để liên kết."])
                    }
                }
                
                throw error
            }
        }
    
    
    // --- Helper: check first login of sso ---
    private func handleCheckFirstLogin(firebaseUser: FirebaseAuth.User) async throws -> User {
        let uid = firebaseUser.uid
        let userDoc = try await db.collection("users").document(uid).getDocument()
        
        if userDoc.exists {
            // Lần sau: Chỉ lấy dữ liệu cũ về
            return try userDoc.data(as: User.self)
        } else {
            // Lần đầu: Tự trích xuất "quà tặng"
            
            // --- LOGIC PHÂN LOẠI GOOGLE / FACEBOOK ---
            var finalAvatarUrl = firebaseUser.photoURL?.absoluteString ?? ""
            var joinMethod = "Google" // Mặc định
            
            // Kiểm tra xem user đăng nhập bằng provider nào
            if let provider = firebaseUser.providerData.first {
                switch provider.providerID {
                case "facebook.com":
                    joinMethod = "Facebook"
                    // Xử lý riêng cho Facebook: Lấy ảnh HD (type=large) thay vì ảnh mờ mặc định
                    finalAvatarUrl = "https://graph.facebook.com/\(provider.uid)/picture?type=large&return_ssl_resources=1"
                    
                case "google.com":
                    joinMethod = "Google"
                    // Google thì ảnh mặc định đã nét rồi, nhưng nếu thích cậu có thể thay đổi size
                    // finalAvatarUrl = finalAvatarUrl.replacingOccurrences(of: "s96-c", with: "s400-c")
                    
                default:
                    break
                }
            }
            
            // --- TẠO USER MỚI ---
            let newUser = User(
                id: uid,
                avatarUrl: finalAvatarUrl,             // Đã xử lý ở trên
                name: firebaseUser.displayName ?? "New User",
                email: firebaseUser.email ?? "",
                phone: firebaseUser.phoneNumber ?? "",
                address: "",
                aboutMe: "Joined via \(joinMethod)",   // Ví dụ: "Joined via Facebook"
                rating: 0.0,
                ratingCount: 0,
                friendIds: [],
                fcmToken: "",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try db.collection("users").document(uid).setData(from: newUser)
            return newUser
        }
    }
    
    var currentUserName: String? {
        if let cacheName = UserDefaults.standard.string(forKey: userDefaultsName) {
            return cacheName
        }
        return nil
    }
    
    var currentUserAvatar: String? {
        if let cacheAvatar = UserDefaults.standard.string(forKey: userDefaultsAvatar) {
            return cacheAvatar
        }
        return nil
    }

    // --- PRIVATE HELPERS ---
    private func saveUserToCache(uid: String) {
        UserDefaults.standard.set(uid, forKey: userDefaultsKey)
    }
    private func saveUserNameToCache(name: String) {
        UserDefaults.standard.set(name, forKey: userDefaultsName)
    }
    private func saveUserAvatarToCache(avatarUrl: String) {
        UserDefaults.standard.set(avatarUrl, forKey: userDefaultsAvatar)
    }
}
