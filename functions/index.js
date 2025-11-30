const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Triggered when a new notification document is created
 * Path: users/{userId}/notifications/{notificationId}
 */
exports.sendPushNotification = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
      const notification = snapshot.data();
      const userId = context.params.userId;

      // Get the user's FCM token
      const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        console.log("User not found:", userId);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log("No FCM token for user:", userId);
        return null;
      }

      // Build the push notification payload
      const payload = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          type: notification.type || "",
          relatedId: notification.relatedId || "",
          fromUserId: notification.fromUserId || "",
          fromUserName: notification.fromUserName || "User",
          notificationId: context.params.notificationId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "skillswap_notifications",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      try {
        await admin.messaging().send(payload);
        console.log("Push notification sent to:", userId);
        return null;
      } catch (error) {
        console.error("Error sending push notification:", error);
        // If token is invalid, remove it
        if (error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered") {
          await admin.firestore()
              .collection("users")
              .doc(userId)
              .update({fcmToken: admin.firestore.FieldValue.delete()});
        }
        return null;
      }
    });
