import firestore from '@react-native-firebase/firestore';
import { parseUser } from '../model/userModel';
import { defaultRate, parseRate } from '../model/rateModel';

const userCollection = firestore().collection('users');
const rateLimitCollection = firestore().collection('ratings');

class UserService {
  // --- 1. LẤY USER THEO ID ---
  async getUserById(userId) {
    try {
      const doc = await userCollection.doc(userId).get();
      if (!doc.exists) return null;
      return parseUser(doc);
    } catch (error) {
      console.error('Error fetching user by ID:', error);
      return null;
    }
  }

    // --- 2. CẬP NHẬT USER ---
    async updateUser(userId, updatedData) {
        try {
            updatedData.updatedAt = firestore.FieldValue.serverTimestamp();
            await userCollection.doc(userId).update({updatedData});
        } catch (error) {
            console.error('Error updating user:', error);
            throw error;
        }
    }

    // --- 3. Get user by array of IDs ---
    async getUsersByIds(userIds) {
        try {
            const users = [];
            for (const id of userIds) {
                const user = await this.getUserById(id);
                if (user) {
                    users.push(user);
                }
            }
            return users;
        } catch (error) {
            console.error('Error fetching users by IDs:', error);
            return [];
        }
    }

    // --- 4. Add friend ---
    async addFriend(userId, friendId) {
        try {
            const userDoc = await userCollection.doc(userId).get();
            if (!userDoc.exists) throw new Error('User not found');

            const userData = userDoc.data();
            const currentFriends = userData.friendIds || [];

            if (!currentFriends.includes(friendId)) {
                currentFriends.push(friendId);
                await userCollection.doc(userId).update({ friendIds: currentFriends });
            }
        } catch (error) {
            console.error('Error adding friend:', error);
            throw error;
        }
    }

    // --- 5. Remove friend ---
    async removeFriend(userId, friendId) {
        try {
            const userDoc = await userCollection.doc(userId).get();
            if (!userDoc.exists) throw new Error('User not found');

            const userData = userDoc.data();
            const currentFriends = userData.friendIds || [];

            const updatedFriends = currentFriends.filter(id => id !== friendId);
            await userCollection.doc(userId).update({ friendIds: updatedFriends });
        } catch (error) {
            console.error('Error removing friend:', error);
            throw error;
        }
    }

    // --- 6. Rate user (add rating)---
    async rateUser(userId, otherUserId, newRating) {
        try {
            const userDoc = await userCollection.doc(userId).get();
            if (!userDoc.exists) throw new Error('User not found');
            const userData = userDoc.data();

            const currentRating = userData.rating || 1.0;
            const ratingCount = userData.ratingCount || 0;

            const totalRating = currentRating * ratingCount;
            const updatedRatingCount = ratingCount + 1;
            const updatedRating = (totalRating + newRating) / updatedRatingCount;

            await userCollection.doc(userId).update({
                rating: updatedRating,
                ratingCount: updatedRatingCount
            });

            await rateLimitCollection.add({
                userId: userId,
                otherUserId: otherUserId,
                num: newRating,
            });
        } catch (error) {
            console.error('Error rating user:', error);
            throw error;
        }
    }

    // --- 7. Check if user can rate another user (rate limiting) ---
    async canRateUser(userId, otherUserId) {
        try {
            const querySnapshot = await rateLimitCollection
                .where('userId', '==', userId)
                .where('otherUserId', '==', otherUserId)
                .get();

            return querySnapshot.empty;
        } catch (error) {
            console.error('Error checking rate limit:', error);
            return false;
        }
    }

    // --- 8. Edit rating ---
    async editRating(userId, otherUserId, newRating) {
        try {
            const querySnapshot = await rateLimitCollection
                .where('userId', '==', userId)
                .where('otherUserId', '==', otherUserId)
                .get();

            if (querySnapshot.empty) {
                throw new Error('No existing rating found to edit');
            }

            const rateDoc = querySnapshot.docs[0];
            const oldRatingData = parseRate(rateDoc);
            const oldRating = oldRatingData.num;

            const userDoc = await userCollection.doc(userId).get();
            if (!userDoc.exists) throw new Error('User not found');
            const userData = userDoc.data();

            const currentRating = userData.rating || 1.0;
            const ratingCount = userData.ratingCount || 1;

            const totalRating = currentRating * ratingCount;
            const updatedTotalRating = totalRating - oldRating + newRating;
            const updatedRating = updatedTotalRating / ratingCount;

            await userCollection.doc(userId).update({
                rating: updatedRating,
            });

            await rateLimitCollection.doc(rateDoc.id).update({
                num: newRating,
            });
        } catch (error) {
            console.error('Error editing rating:', error);
            throw error;
        } 
    }

    // --- 9. Delete rating ---
    async deleteRating(userId, otherUserId) {
        try {
            const querySnapshot = await rateLimitCollection
                .where('userId', '==', userId)
                .where('otherUserId', '==', otherUserId)
                .get();

            if (querySnapshot.empty) {
                throw new Error('No existing rating found to delete');
            }

            const rateDoc = querySnapshot.docs[0];
            const oldRatingData = parseRate(rateDoc);
            const oldRating = oldRatingData.num;

            const userDoc = await userCollection.doc(userId).get();
            if (!userDoc.exists) throw new Error('User not found');
            const userData = userDoc.data();

            const currentRating = userData.rating || 1.0;
            const ratingCount = userData.ratingCount || 1;

            const totalRating = currentRating * ratingCount;
            const updatedRatingCount = ratingCount - 1;
            const updatedRating = updatedRatingCount > 0 ? (totalRating - oldRating) / updatedRatingCount : 1.0;

            await userCollection.doc(userId).update({
                rating: updatedRating,
                ratingCount: updatedRatingCount
            });

            await rateLimitCollection.doc(rateDoc.id).delete();
        } catch (error) {
            console.error('Error deleting rating:', error);
            throw error;
        }
    }
}

export const userService = new UserService();