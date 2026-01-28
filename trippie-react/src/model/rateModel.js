// Rating for
// 1. Giá trị mặc định cho Rate Model
// Để tránh lỗi crash khi render nếu field bị null
export const defaultRate = {
    id: '',
    userId: '',
    otherUserId: '',
    num: 1,
};

// 2. Hàm Parser 
// Nhiệm vụ: Biến cục data thô của Firebase thành Object sạch sẽ để dùng trong App
export const parseRate = (doc) => {
    const data = doc.data();

    // Nếu doc không tồn tại
    if (!data) return null;

    return {
        ...defaultRate, // Lấy giá trị mặc định lót nền trước
        ...data,        // Đè dữ liệu từ Firebase lên

        id: doc.id, 
    };
};