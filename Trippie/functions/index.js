const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// --- HELPER FUNCTION TO SEND PUSH AND SAVE TO DATABASE ---
async function sendPush(userIds, title, body, dataPayload) {
    if (!userIds || userIds.length === 0) return;
    
    const ids = Array.isArray(userIds) ? userIds : [userIds];
    const tokens = [];
    
    const db = admin.firestore();
    const batch = db.batch(); 
    let hasBatchOperations = false; // Biến kiểm tra xem có cần ghi vào DB không

    const userPromises = ids.map(uid => db.collection("users").doc(uid).get());
    const userDocs = await Promise.all(userPromises);
    
    userDocs.forEach((doc, index) => {
        if (doc.exists) {
            const uid = ids[index];
            
            // 1. CHỈ LƯU VÀO DATABASE NẾU KHÔNG PHẢI LÀ TIN NHẮN CHAT
            if (dataPayload.type !== "chat_message") {
                const notifRef = db.collection("users").doc(uid).collection("notifications").doc();
                
                batch.set(notifRef, {
                    id: notifRef.id,
                    title: title,
                    body: body,
                    type: dataPayload.type || "unknown",
                    tripId: dataPayload.tripId || "",
                    isRead: false, 
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
                hasBatchOperations = true; // Đánh dấu là có data để ghi
            }

            // 2. VẪN NHẶT TOKEN ĐỂ BẮN PUSH RA MÀN HÌNH KHOÁ (Áp dụng cho mọi loại)
            if (doc.data().fcmToken) {
                tokens.push(doc.data().fcmToken);
            }
        }
    });

    // 3. THỰC THI LỆNH LƯU VÀO DATABASE (Chỉ chạy khi có dữ liệu cần lưu)
    if (hasBatchOperations) {
        await batch.commit();
    }

    // 4. THỰC THI LỆNH BẮN PUSH NOTIFICATION 
    if (tokens.length === 0) return;
    
    if (dataPayload.type === "chat_message") {
        const message = {
            notification: { title, body },
            data: dataPayload,
            tokens: tokens,
            apns: { payload: { aps: { 
                    sound: "default",
                    "thread-id": dataPayload.tripId ? `trip_chat_${dataPayload.tripId}` : "trippie_general"
                }} 
            }
        };

        return admin.messaging().sendEachForMulticast(message);
    } else {
        const message = {
            notification: { title, body },
            data: dataPayload,
            tokens: tokens,
            apns: { payload: { aps: { sound: "default" } } }
        };

        return admin.messaging().sendEachForMulticast(message);
    }
}

// ============================================================================
// 1. NEW CHAT MESSAGE - GỘP NHÓM, GIỚI HẠN & ĐỔI TITLE
// ============================================================================
exports.onNewMessage = functions.firestore
  .document("trips/{tripId}/comments/{commentId}")
  .onCreate(async (snapshot, context) => {
      const data = snapshot.data();
      const tripId = context.params.tripId;
      const senderId = data.userId;
      
      const db = admin.firestore();
      const tripDoc = await db.collection("trips").doc(tripId).get();
      if (!tripDoc.exists) return null;
      
      const tripData = tripDoc.data();
      let allParticipants = [tripData.ownerId, ...(tripData.members || [])];
      let targetIds = allParticipants.filter(id => id !== senderId);

      // Chia làm 2 mảng gửi để khác nhau cái Title
      const firstMessageTargets = []; // Dành cho người nhận tin đầu tiên (count = 0)
      const subsequentTargets = [];   // Dành cho người nhận tin từ thứ 2 đến 10 (count > 0)
      
      const now = new Date();
      const ONE_HOUR = 60 * 60 * 1000; 

      for (const targetId of targetIds) {
          const throttleRef = db.collection("users").doc(targetId).collection("chat_throttle").doc(tripId);
          const throttleDoc = await throttleRef.get();

          let count = 0;
          let lastSentTime = new Date(0);

          if (throttleDoc.exists) {
              const throttleData = throttleDoc.data();
              count = throttleData.count || 0;
              lastSentTime = throttleData.lastSent ? throttleData.lastSent.toDate() : new Date(0);
          }

          if (now - lastSentTime > ONE_HOUR) {
              count = 0; // Reset
          }

          if (count < 10) {
              // Phân loại user vào đúng mảng
              if (count === 0) {
                  firstMessageTargets.push(targetId);
              } else {
                  subsequentTargets.push(targetId);
              }
              
              await throttleRef.set({
                  count: count + 1,
                  lastSent: admin.firestore.FieldValue.serverTimestamp()
              }, { merge: true });
          }
      }

      const promises = [];

      // Bắn push cho nhóm tin nhắn đầu tiên (Có kèm chữ Trip)
      if (firstMessageTargets.length > 0) {
            promises.push(sendPush(
                firstMessageTargets,
                `${(data.userName || "").trim() || "Someone"} (${tripData.location || "the"} Trip)`,
                    (data.message || "").trim() || "Sent a new message.",
                { type: "chat_message", tripId: String(tripId) }
            ));
      }

      // Bắn push cho nhóm tin nhắn tiếp theo (Chỉ có Tên)
      if (subsequentTargets.length > 0) {
            promises.push(sendPush(
                subsequentTargets,
                `${(data.userName || "").trim() || "Someone"}`,
                    (data.message || "").trim() || "Sent a new message.",
                { type: "chat_message", tripId: String(tripId) }
            ));
      }

      return Promise.all(promises);
});

// ============================================================================
// 2. LẮNG NGHE SỰ THAY ĐỔI CỦA TRIP (Accept, Kick, New Request, Deny)
// ============================================================================
exports.onTripUpdate = functions.firestore
    .document("trips/{tripId}")
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const tripId = context.params.tripId;
        const ownerId = afterData.ownerId;
        const tripLocation = afterData.location || "the destination";

        const beforeMembers = beforeData.members || [];
        const afterMembers = afterData.members || [];
        const beforePending = beforeData.pendingRequests || [];
        const afterPending = afterData.pendingRequests || [];

        const getAdded = (arrBefore, arrAfter) => arrAfter.filter(id => !arrBefore.includes(id));
        const getRemoved = (arrBefore, arrAfter) => arrBefore.filter(id => !arrAfter.includes(id));

        const addedMembers = getAdded(beforeMembers, afterMembers);
        const removedMembers = getRemoved(beforeMembers, afterMembers);
        const addedPending = getAdded(beforePending, afterPending);
        const removedPending = getRemoved(beforePending, afterPending);
        const recentAction = afterData.recentAction || "";

        const promises = [];

        // CASE 1: ĐƯỢC ACCEPT (Từ Pending sang Members)
        addedMembers.forEach(userId => {
            promises.push(sendPush(
                userId, "Request Accepted!", `You have officially joined the trip to ${tripLocation}.`, 
                { type: "status_change", tripId: String(tripId), status: "accepted" }
            ));
        });

        // CASE 2: BỊ KICK/TỰ ĐỘNG RỜI KHỎI NHÓM (Bị xoá khỏi mảng Members)
        removedMembers.forEach(userId => {
            if (recentAction !== "leave") { 
                promises.push(sendPush(
                    userId, "Trip Update", `You are no longer in the trip to ${tripLocation}.`, 
                    { type: "status_change", tripId: String(tripId), status: "kicked_or_left" }
                ));
            }
        });

        // CASE 3: NEW REQUEST (Có ID mới chui vào mảng Pending)
        addedPending.forEach(userId => {
            promises.push(sendPush(
                ownerId, "New Join Request", `Someone requested to join your trip to ${tripLocation}.`, 
                { type: "new_request", tripId: String(tripId), userId: String(userId) }
            ));
        });

        // CASE 4: BỊ DENY / TỰ HUỶ REQUEST (Bị xoá khỏi Pending, và KHÔNG CÓ TRONG addedMembers)
        removedPending.forEach(userId => {
            if (!addedMembers.includes(userId) && recentAction !== "cancel") {
                promises.push(sendPush(
                    userId, "Request Update", `Your request to join the trip to ${tripLocation} was declined.`, 
                    { type: "status_change", tripId: String(tripId), status: "denied" }
                ));
            }
        });

        return Promise.all(promises);
    });

    // ============================================================================
    // 3. TRIP REMINDER (24h before start)
    // Runs every hour to check for trips starting in 24-25 hours
    // ============================================================================
    exports.tripReminder24h = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
        const now = new Date();
        // Tạo mốc thời gian từ 24h đến 25h tới
        const startTimeWindow = new Date(now.getTime() + 24 * 60 * 60 * 1000); 
        const endTimeWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

        const tripsSnapshot = await admin.firestore().collection("trips")
            .where("startTime", ">=", startTimeWindow)
            .where("startTime", "<", endTimeWindow)
            .get();

        const promises = [];

        tripsSnapshot.forEach(doc => {
            const trip = doc.data();
            const tripId = doc.id;
            // Gửi cho cả Owner và tất cả Members
            const allParticipants = [trip.ownerId, ...(trip.members || [])];

            promises.push(sendPush(
                allParticipants,
                "Trip starting soon!",
                `Your trip to ${trip.location} is starting in 24 hours. Get your luggage ready!`,
                { type: "trip_reminder", tripId: String(tripId) }
            ));
        });

        return Promise.all(promises);
    });