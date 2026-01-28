// services/AuthService.js
import auth from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { defaultUser } from '../model/userModel';

const USER_CACHE_KEY = 'cached_user_id';

class AuthService {
  // --- 1. REGISTER ---
  async register(email, pass, name) {
    try {
      // 1. Tạo Auth User
      const userCredential = await auth().createUserWithEmailAndPassword(email, pass);
      const uid = userCredential.user.uid;

      // 2. Chuẩn bị data User (Merge với defaultUser)
      const newUser = {
        ...defaultUser, // Lấy toàn bộ giá trị mặc định
        id: uid,
        name: name,
        email: email,
        aboutMe: 'New member of Trippie!',
        createdAt: firestore.FieldValue.serverTimestamp(), // Dùng giờ Server chuẩn hơn Date() local
        updatedAt: firestore.FieldValue.serverTimestamp(),
      };

      // 3. Lưu vào Firestore
      // Lưu ý: JS không cần Codable, ném thẳng Object vào là được
      await firestore().collection('users').doc(uid).set(newUser);

      // 4. Lưu Cache
      await this.saveUserToCache(uid);

      return newUser;
    } catch (error) {
      throw error; // Ném lỗi ra để màn hình UI xử lý (hiện Alert)
    }
  }

  // --- 2. LOGIN ---
  async login(email, pass) {
    try {
      const result = await auth().signInWithEmailAndPassword(email, pass);
      await this.saveUserToCache(result.user.uid);
      return result.user;
    } catch (error) {
      throw error;
    }
  }

  // --- 3. LOGOUT ---
  async logout() {
    try {
      await auth().signOut();
      await AsyncStorage.removeItem(USER_CACHE_KEY);
    } catch (error) {
      console.error(error);
    }
  }

  // --- 4. GET CURRENT USER ID (Khác Swift chút xíu) ---
  // Vì AsyncStorage là Async, nên hàm này phải trả về Promise
  async getCurrentUserId() {
    // Ưu tiên 1: Cache
    const cachedId = await AsyncStorage.getItem(USER_CACHE_KEY);
    if (cachedId) return cachedId;

    // Ưu tiên 2: Firebase SDK (SDK này lưu cache cực tốt sẵn rồi)
    const firebaseUser = auth().currentUser;
    if (firebaseUser) {
      await this.saveUserToCache(firebaseUser.uid);
      return firebaseUser.uid;
    }

    return null;
  }

  // --- HELPERS ---
  async saveUserToCache(uid) {
    try {
      await AsyncStorage.setItem(USER_CACHE_KEY, uid);
    } catch (e) {
      console.error("Lỗi lưu cache", e);
    }
  }
}

// Export một instance (Singleton) để dùng mọi nơi
export default new AuthService();