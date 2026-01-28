import { PersonalStatus, UserRole } from "./constraints";

export const defaultParticipation = {
    id: '',
    userId: '',
    tripId: '',
    personalStatus: PersonalStatus.upcoming,
    role: UserRole.owner,
};

export const tripWithParticipation = (trip, participation) => {
    return {
        id: trip.id  || participation.tripId,
        trip: trip,
        participation: participation
    };
};

// Hàm Parser
// Nhiệm vụ: Biến cục data thô của Firebase thành Object sạch sẽ để dùng trong App
export const parseParticipation = (doc) => {
    const data = doc.data();

    // Nếu doc không tồn tại
    if (!data) return null;

    return {
        ...defaultParticipation, // Lấy giá trị mặc định lót nền trước
        ...data,        // Đè dữ liệu từ Firebase lên

        id: doc.id, 
    };
}

