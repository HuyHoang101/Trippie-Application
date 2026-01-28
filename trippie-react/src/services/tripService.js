import { defaultTrip, parseTrip } from "../model/tripModel";
import { parseParticipation, defaultParticipation, tripWithParticipation } from "../model/participation";
import firestore from '@react-native-firebase/firestore';
import authService from "./authService";
import { PersonalStatus, TripStatus, UserRole } from "../model/constraints";

const tripCollection = firestore().collection('trips');
const participationCollection = firestore().collection('participations');

class TripService {
    // --- 1. Get Trip (feeding board => status not compleled, isExpired true. Query: tripType, location, search) ---
    async getAvailableTrips(tripType, location, searchText) {
        try {
            let query = tripCollection
                .where('status', '!=', 'completed')

            if (tripType) {
                query = query.where('tripType', '==', tripType);
            }

            if (location) {
                query = query.where('location', '==', location);
            }

            const snapshot = await query.get();
            let trips = snapshot.docs.map(doc => parseTrip(doc));

            trips = trips.filter(trip => !trip.isExpired);

            // Filter by search text
            if (searchText) {
                const lowerSearchText = searchText.toLowerCase();
                trips = trips.filter(trip =>
                    trip.title.toLowerCase().includes(lowerSearchText) ||
                    trip.country.toLowerCase().includes(lowerSearchText) ||
                    trip.location.toLowerCase().includes(lowerSearchText) || []
                );
            }

            return trips;
        } catch (error) {
            console.error('Error fetching available trips:', error);
            return [];
        }
    }

    // --- 2. Get Trip (my trip all in participation) ---
    async getMyTrips(userId) {
        try {
            // 1. Chạy 3 luồng fetch song song
            const [partSnap, ownerSnap, memberSnap] = await Promise.all([
                participationCollection.where('userId', '==', userId).get(),
                tripCollection.where('ownerId', '==', userId).get(),
                tripCollection.where('members', 'array-contains', userId).get()
            ]);

            // 2. Parse dữ liệu
            const participations = partSnap.docs.map(doc => parseParticipation(doc));
            
            // Gộp 2 luồng Trip và dùng Map để khử trùng theo ID
            const allTripDocs = [...ownerSnap.docs, ...memberSnap.docs];
            const uniqueTripsMap = new Map();

            allTripDocs.forEach(doc => {
                if (!uniqueTripsMap.has(doc.id)) {
                    uniqueTripsMap.set(doc.id, parseTrip(doc));
                }
            });

            const uniqueTrips = Array.from(uniqueTripsMap.values());

            // 3. Kết hợp Trip với Participation tương ứng
            return uniqueTrips.map(trip => {
                const p = participations.find(part => part.tripId === trip.id) || defaultParticipation;
                return tripWithParticipation(trip, p);
            });

        } catch (error) {
            console.error('Error fetching my trips (3-way):', error);
            return [];
        }
    }

    // --- 3. Create Trip (ownerId = authService.getCurrentUserId())---
    async createTrip(newTrip) {
        try {
            const batch = firestore().batch(); // Khởi tạo batch
            
            // Tạo Reference trước để có ID
            const tripRef = tripCollection.doc(); 
            const participationRef = participationCollection.doc();

            const timestamp = firestore.FieldValue.serverTimestamp();

            let formattedStartDate = null;
            if (newTrip.startDate instanceof Date) {
                formattedStartDate = firestore.Timestamp.fromDate(newTrip.startDate);
            }

            const { isExpired, ...dataToUpload } = newTrip; // Loại bỏ isExpired không cần lưu

            // 1. Chuẩn bị dữ liệu Trip
            const tripData = {
                ...dataToUpload,
                id: tripRef.id, // Lưu luôn ID vào document cho tiện
                startDate: formattedStartDate,
                createdAt: timestamp,
                updatedAt: timestamp,
            };

            // 2. Chuẩn bị dữ liệu Participation
            const participationData = {
                userId: tripRef.ownerId,
                tripId: tripRef.id,
                personalStatus: 'upcoming',
                role: 'owner',
                createdAt: timestamp,
            };

            // 3. Đưa vào batch
            batch.set(tripRef, tripData);
            batch.set(participationRef, participationData);

            // 4. Thực thi duy nhất 1 lần gửi request
            await batch.commit();

            return parseTrip(tripRef); // Trả về data luôn, đỡ tốn 1 lần .get() nữa
        } catch (error) {
            console.error('Error creating trip with batch:', error);
            throw error;
        }
    }

    // --- 4. Update Trip (return updated trip with participation) ---
    async updateTrip(updatedData) {
        try {
            updatedData.updatedAt = firestore.FieldValue.serverTimestamp();
            await tripCollection.doc(updatedData.id).update(updatedData);
            const updatedDoc = await tripCollection.doc(updatedData.id).get();
            const participation = await participationCollection
                .where('tripId', '==', updatedData.id)
                .where('userId', '==', authService.getCurrentUserId())
                .get();
            const participationData = participation.docs.length > 0 ? parseParticipation(participation.docs[0]) : defaultParticipation;
            return tripWithParticipation(parseTrip(updatedDoc), participationData);
        } catch (error) {
            console.error('Error updating trip:', error);
            throw error;
        }
    }

    // --- 5. Delete Trip and Participation ---
    async deleteTrip(tripId) {
        try {
            const batch = firestore().batch();
            const tripRef = tripCollection.doc(tripId);
            const participationQuery = participationCollection
                .where('tripId', '==', tripId);

            // Xóa Trip
            batch.delete(tripRef);

            // Xóa Participation liên quan
            const participationSnap = await participationQuery.get();
            participationSnap.docs.forEach(doc => {
                batch.delete(doc.ref);
            });

            await batch.commit();
        } catch (error) {
            console.error('Error deleting trip:', error);
            throw error;
        }
    }

    // --- 6. Accept Join trip ---
    async acceptJoinTrip(tripId, userId) {
        try {
            const batch = firestore().batch();
            const participationRef = participationCollection.doc();
            
            const participationData = {
                userId: userId,
                tripId: tripId,
                personalStatus: PersonalStatus.upcoming,
                role: UserRole.member,
            };

            batch.set(participationRef, participationData);

            // Cập nhật số lượng currentMember trong Trip
            const currentTripDoc = await tripCollection.doc(tripId).get();
            if (!currentTripDoc.exists) {
                throw new Error('Trip not found');
            }
            const tripRef = currentTripDoc.id;
            if (currentTripDoc.status !== TripStatus.completed && currentTripDoc.currentMember === currentTripDoc.maxMember) {
                currentTripDoc.status = TripStatus.full;
            }

            batch.update(tripRef, {
                members: firestore.FieldValue.arrayUnion(userId),
                pendingRequests: firestore.FieldValue.arrayRemove(userId),
                currentMember: firestore.FieldValue.increment(1),
                status: currentTripDoc.status,
            });
            await batch.commit();

            let newTrip = parseTrip({ ...currentTripDoc, 
                members: [...currentTripDoc.members, userId],
                pendingRequests: currentTripDoc.pendingRequests.filter(id => id !== userId),
                currentMember: currentTripDoc.currentMember + 1,
                status: currentTripDoc.status,
            });

            return newTrip;
        } catch (error) {
            console.error('Error joining trip:', error);
            throw error;
        }
    }


    // --- 7. Kick member from trip ---
    async kickMemberFromTrip(tripId, userId) {
        try {
            const batch = firestore().batch();
            const tripRef = tripCollection.doc(tripId);
            
            // 1. Lấy data trip để tính toán
            const tripSnap = await tripRef.get();
            if (!tripSnap.exists) throw new Error('Trip not found');
            const tripData = tripSnap.data();

            // 2. Tính toán status mới
            let newStatus = tripData.status;
            if (newStatus === TripStatus.full) {
                newStatus = TripStatus.recruiting; // Kick bớt người thì mở tuyển lại
            }
            
            // 3. Update Trip
            batch.update(tripRef, {
                status: newStatus,
                currentMember: firestore.FieldValue.increment(-1), // Trừ đi 1
                members: firestore.FieldValue.arrayRemove(userId) // Xoá khỏi mảng members
            });

            // 4. Tìm và Xoá Participation
            const partSnapshot = await participationCollection
                .where('tripId', '==', tripId)
                .where('userId', '==', userId)
                .get();
                
            partSnapshot.forEach(doc => {
                batch.delete(doc.ref); // Đưa vào batch
            });

            await batch.commit();
            let newTrip = parseTrip({ ...tripData, 
                status: newStatus, 
                currentMember: tripData.currentMember - 1, 
                members: tripData.members.filter(id => id !== userId) 
            });

            // Return updated data (giả lập)
            return newTrip;

        } catch (error) {
            console.error('Error kicking member:', error);
            throw error;
        }
    }

    // --- 8. Deny join trip (for pending requests) ---
    async denyJoinTrip(tripId, userId) {
        try {
            const tripDoc = await tripCollection.doc(tripId).get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            // Cập nhật pendingRequests
            tripDoc.pendingRequests = tripDoc.pendingRequests.filter(id => id !== userId);

            await tripCollection.doc(tripId).update({
                pendingRequests: tripDoc.pendingRequests,
            });

            let newTrip = parseTrip({ ...tripDoc, 
                pendingRequests: tripDoc.pendingRequests 
            });
            return newTrip;
        } catch (error) {
            console.error('Error denying join trip:', error);
            throw error;
        }
    }

    // --- 9. Request to join trip (add to pendingRequests) ---
    async requestToJoinTrip(tripId, userId) {
        try {
            const tripDoc = await tripCollection.doc(tripId).get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            // Cập nhật pendingRequests
            if (!tripDoc.pendingRequests.includes(userId)) {
                tripDoc.pendingRequests.push(userId);
            }

            await tripCollection.doc(tripId).update({
                pendingRequests: tripDoc.pendingRequests,
                updatedAt: tripDoc.updatedAt
            });

            let newTrip = parseTrip({ ...tripDoc, 
                pendingRequests: tripDoc.pendingRequests 
            });

            return newTrip;
        } catch (error) {
            console.error('Error requesting to join trip:', error);
            throw error;
        }
    }

    // --- 10. leave trip (remove participation and decrease currentMember) ---
    async leaveTrip(tripId, userId) {
        try {
            const patch = firestore().batch();
            const tripRef = tripCollection.doc(tripId);
            const tripDoc = await tripRef.get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            // Cập nhật số lượng currentMember trong Trip
            let updatedCurrentMember = tripDoc.currentMember - 1;
            let updatedStatus = tripDoc.status;
            let members = tripDoc.members.filter(memberId => memberId !== userId);
            if (tripDoc.status !== TripStatus.completed) {
                updatedStatus = TripStatus.recruiting;
            }

            patch.update(tripRef, {
                currentMember: updatedCurrentMember,
                status: updatedStatus,
                members: members,
            });

            // Xóa Participation
            const participationQuery = await participationCollection
                .where('tripId', '==', tripId)
                .where('userId', '==', userId)
                .get();

            participationQuery.forEach(doc => {
                patch.delete(doc.ref);
            });

            await patch.commit();

            let newTrip = parseTrip({ ...tripDoc, 
                currentMember: updatedCurrentMember,
                status: updatedStatus,
                members: members
            });

            return newTrip;
        } catch (error) {
            console.error('Error leaving trip:', error);
            throw error;
        }
    }

    // --- 11. Cancel request to join trip ---
    async cancelJoinRequest(tripId, userId) {
        try {
            const tripDoc = await tripCollection.doc(tripId).get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            // Cập nhật pendingRequests
            tripDoc.pendingRequests = tripDoc.pendingRequests.filter(id => id !== userId);
            tripDoc.updatedAt = firestore.FieldValue.serverTimestamp();

            await tripCollection.doc(tripId).update({
                pendingRequests: tripDoc.pendingRequests,
                updatedAt: tripDoc.updatedAt
            });

            let newTrip = parseTrip({ ...tripDoc, 
                pendingRequests: tripDoc.pendingRequests 
            });

            return newTrip;
        } catch (error) {
            console.error('Error cancelling join request:', error);
            throw error;
        }
    }

    // --- 12. Change personal status ---
    async changePersonalStatus(tripId, userId, newStatus) {
        try {
            const participationQuery = await participationCollection
                .where('tripId', '==', tripId)
                .where('userId', '==', userId)
                .get();

            if (participationQuery.empty) {
                throw new Error('Participation not found');
            }

            const participationDoc = participationQuery.docs[0];
            await participationDoc.ref.update({
                personalStatus: newStatus
            });
            participationDoc.personalStatus = newStatus;
            return parseParticipation(participationDoc);
        } catch (error) {
            console.error('Error changing personal status:', error);
            throw error;
        }
    }

    // --- 13. Complete trip ---
    async completeTrip(tripId) {
        try {
            const tripRef = tripCollection.doc(tripId);
            const tripDoc = await tripRef.get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            await tripRef.update({
                status: TripStatus.completed,
                updatedAt: firestore.FieldValue.serverTimestamp()
            });
            let newTrip = parseTrip({ ...tripDoc, 
                status: TripStatus.completed 
            });
            return newTrip;
        } catch (error) {
            console.error('Error completing trip:', error);
            throw error;
        }
    }

    // --- 14. UnComplete trip ---
    async uncompleteTrip(tripId) {
        try {
            const tripRef = tripCollection.doc(tripId);
            const tripDoc = await tripRef.get();
            if (!tripDoc.exists) {
                throw new Error('Trip not found');
            }

            await tripRef.update({
                status: tripDoc.currentMember >= tripDoc.maxMember ? TripStatus.full : TripStatus.recruiting,
                updatedAt: firestore.FieldValue.serverTimestamp()
            });
            let newTrip = parseTrip({ ...tripDoc, 
                status: tripDoc.currentMember >= tripDoc.maxMember ? TripStatus.full : TripStatus.recruiting 
            });
            return newTrip;
        } catch (error) {
            console.error('Error uncompleting trip:', error);
            throw error;
        }
    }
}