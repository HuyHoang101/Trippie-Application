import { TripStatus, TripType } from "./constraints";

//trip
export const defaultTrip = {
    id: '',
    ownerId: '',
    ownerName: '',
    coverImage: '',
    title: '',
    description: 'None',
    location: '',
    country: '',

    status: TripStatus.recruiting,
    TripType: TripType.buddy,

    members: [],
    pendingRequsests: [],
    maxMember: 1,
    currentMember: 1,

    startDate: null,
    dayIndex: 0,

    createdAt: null,
    updatedAt: null,

    get isExpired() {
        return this.startDate ? (this.startDate < new Date()) : false;
    }
}; 



// Hàm Parser
// Nhiệm vụ: Biến cục data thô của Firebase thành Object sạch sẽ để dùng trong App
// Hàm Parser thông minh: Nhận cả Snapshot lẫn Object thường
export const parseTrip = (docOrData) => {
    // 1. Kiểm tra xem đầu vào là Snapshot (có hàm data) hay là Object thường
    let data = null;
    let id = '';

    if (typeof docOrData.data === 'function') {
        // Trường hợp là Snapshot từ Firebase trả về
        data = docOrData.data();
        id = docOrData.id;
    } else {
        // Trường hợp là Object mình tự chế (manual object)
        data = docOrData;
        id = docOrData.id || '';
    }

    // Nếu data null
    if (!data) return null;

    return {
        ...defaultTrip, // Lót nền
        ...data,        // Đè data lên
        id: id,         // Đảm bảo ID luôn đúng

        // Xử lý Date/Timestamp
        startDate: data.startDate && typeof data.startDate.toDate === 'function' 
            ? data.startDate.toDate() 
            : (data.startDate instanceof Date ? data.startDate : new Date()), // Handle cả JS Date
        
        // Tương tự cho createdAt, updatedAt...
        createdAt: data.createdAt && typeof data.createdAt.toDate === 'function' ? data.createdAt.toDate() : new Date(),
        updatedAt: data.updatedAt && typeof data.updatedAt.toDate === 'function' ? data.updatedAt.toDate() : new Date(),
    };
}