
// 1. Giá trị mặc định cho User Model
// Để tránh lỗi crash khi render nếu field bị null
export const defaultUser = {
  id: '',
  avatarUrl: '',
  name: '',
  email: '',
  phone: '',
  address: '',
  aboutMe: '',
  rating: 0.0,
  ratingCount: 0,
  friendIds: [],
  fcmToken: '',
  createdAt: null,
  updatedAt: null,
};

// 2. Hàm Parser 
// Nhiệm vụ: Biến cục data thô của Firebase thành Object sạch sẽ để dùng trong App
export const parseUser = (doc) => {
  const data = doc.data();
  
  // Nếu doc không tồn tại
  if (!data) return null;

  return {
    ...defaultUser, // Lấy giá trị mặc định lót nền trước
    ...data,        // Đè dữ liệu từ Firebase lên

    id: doc.id, 

    // Xử lý @ServerTimestamp (Quan trọng!)
    // Firebase trả về Timestamp object, cần đổi sang JS Date để hiển thị
    createdAt: data.createdAt ? data.createdAt.toDate() : new Date(),
    updatedAt: data.updatedAt ? data.updatedAt.toDate() : new Date(),
  };
};