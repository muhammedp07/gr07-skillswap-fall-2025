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

/**
 * Scheduled function that runs every hour to check for swap sessions
 * starting in approximately 24 hours and sends reminder notifications.
 */
exports.sendSwapReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async () => {
      const now = new Date();
      const in23Hours = new Date(now.getTime() + 23 * 60 * 60 * 1000);
      const in25Hours = new Date(now.getTime() + 25 * 60 * 60 * 1000);

      console.log("Checking swaps between", in23Hours, "and", in25Hours);

      try {
        // Query swap sessions scheduled between 23-25 hours from now
        const db = admin.firestore();
        const ts = admin.firestore.Timestamp;
        const sessionsSnapshot = await db
            .collection("swap_sessions")
            .where("status", "==", "scheduled")
            .where("scheduledTime", ">=", ts.fromDate(in23Hours))
            .where("scheduledTime", "<=", ts.fromDate(in25Hours))
            .get();

        if (sessionsSnapshot.empty) {
          console.log("No upcoming swap sessions in the 24-hour window");
          return null;
        }

        console.log(`Found ${sessionsSnapshot.size} sessions to remind`);

        const batch = db.batch();

        for (const sessionDoc of sessionsSnapshot.docs) {
          const session = sessionDoc.data();
          const sessionId = sessionDoc.id;

          // Check if we already sent a reminder for this session
          if (session.reminderSent) {
            console.log("Reminder already sent for session:", sessionId);
            continue;
          }

          const participantIds = session.participantIds || [];
          const scheduledTime = session.scheduledTime.toDate();
          const formattedTime = scheduledTime.toLocaleString("en-US", {
            weekday: "short",
            month: "short",
            day: "numeric",
            hour: "numeric",
            minute: "2-digit",
          });

          // Send notification to each participant
          for (const participantId of participantIds) {
            // Get the other participant's name for the notification
            const otherParticipantId = participantIds.find(
                (id) => id !== participantId,
            );

            let otherUserName = "your partner";
            if (otherParticipantId) {
              const otherUserDoc = await db
                  .collection("users")
                  .doc(otherParticipantId)
                  .get();
              if (otherUserDoc.exists) {
                const userData = otherUserDoc.data();
                otherUserName = userData.name ||
                    userData.displayName ||
                    "your partner";
              }
            }

            // Create notification document
            const notificationRef = db
                .collection("users")
                .doc(participantId)
                .collection("notifications")
                .doc();

            const notifBody = `Your swap with ${otherUserName} ` +
                `is in 24 hours! (${formattedTime})`;

            const notification = {
              fromUserId: otherParticipantId || "",
              fromUserName: otherUserName,
              title: "Swap Reminder 📅",
              body: notifBody,
              type: "swapReminder",
              isRead: false,
              timestamp: ts.now(),
              relatedId: session.chatId || "",
            };

            batch.set(notificationRef, notification);
            console.log("Queued reminder for user:", participantId);
          }

          // Mark session as reminder sent
          batch.update(sessionDoc.ref, {reminderSent: true});
        }

        await batch.commit();
        console.log("Swap reminders sent successfully");
        return null;
      } catch (error) {
        console.error("Error sending swap reminders:", error);
        return null;
      }
    });

/**
 * HTTP function to manually trigger swap reminders (for testing)
 * URL: https://<region>-<project>.cloudfunctions.net/sendSwapRemindersManual
 * Query params: ?test=true to send to ALL scheduled sessions
 */
exports.sendSwapRemindersManual = functions.https
    .onRequest(async (req, res) => {
      // For testing: allow custom hour offset via query param
      const hoursAhead = parseInt(req.query.hours) || 24;
      const testMode = req.query.test === "true";

      const now = new Date();
      const hourMs = 60 * 60 * 1000;
      const windowStart = new Date(now.getTime() + (hoursAhead - 1) * hourMs);
      const windowEnd = new Date(now.getTime() + (hoursAhead + 1) * hourMs);

      console.log(`Checking swaps: ${windowStart} to ${windowEnd}`);

      try {
        const db = admin.firestore();
        const ts = admin.firestore.Timestamp;
        let sessionsSnapshot;

        if (testMode) {
          // In test mode, get ALL scheduled sessions (ignore time window)
          sessionsSnapshot = await db
              .collection("swap_sessions")
              .where("status", "==", "scheduled")
              .get();
        } else {
          sessionsSnapshot = await db
              .collection("swap_sessions")
              .where("status", "==", "scheduled")
              .where("scheduledTime", ">=", ts.fromDate(windowStart))
              .where("scheduledTime", "<=", ts.fromDate(windowEnd))
              .get();
        }

        if (sessionsSnapshot.empty) {
          res.json({success: true, message: "No upcoming sessions found"});
          return;
        }

        const batch = db.batch();
        let notificationCount = 0;

        for (const sessionDoc of sessionsSnapshot.docs) {
          const session = sessionDoc.data();
          const participantIds = session.participantIds || [];
          const scheduledTime = session.scheduledTime.toDate();
          const formattedTime = scheduledTime.toLocaleString("en-US", {
            weekday: "short",
            month: "short",
            day: "numeric",
            hour: "numeric",
            minute: "2-digit",
          });

          for (const participantId of participantIds) {
            const otherParticipantId = participantIds.find(
                (id) => id !== participantId,
            );

            let otherUserName = "your partner";
            if (otherParticipantId) {
              const otherUserDoc = await db
                  .collection("users")
                  .doc(otherParticipantId)
                  .get();
              if (otherUserDoc.exists) {
                const userData = otherUserDoc.data();
                otherUserName = userData.name ||
                    userData.displayName ||
                    "your partner";
              }
            }

            const notificationRef = db
                .collection("users")
                .doc(participantId)
                .collection("notifications")
                .doc();

            const notifBody = `Your swap with ${otherUserName} ` +
                `is coming up! (${formattedTime})`;

            const notification = {
              fromUserId: otherParticipantId || "",
              fromUserName: otherUserName,
              title: "Swap Reminder 📅",
              body: notifBody,
              type: "swapReminder",
              isRead: false,
              timestamp: ts.now(),
              relatedId: session.chatId || "",
            };

            batch.set(notificationRef, notification);
            notificationCount++;
          }

          // Mark as reminder sent (skip in test mode to allow re-testing)
          if (!testMode) {
            batch.update(sessionDoc.ref, {reminderSent: true});
          }
        }

        await batch.commit();
        res.json({
          success: true,
          message: `Sent ${notificationCount} reminders`,
          sessionsFound: sessionsSnapshot.size,
        });
      } catch (error) {
        console.error("Error:", error);
        res.status(500).json({success: false, error: error.message});
      }
    });
