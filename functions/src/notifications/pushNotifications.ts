import * as admin from "firebase-admin";

/* ------------ Types ------------ */

interface NotificationPayload {
  title: string;
  body: string;
  type: string;
  fromUserId?: string;
  postId?: string;
  imageUrl?: string;
}

interface NotificationData {
  type: string;
  fromUserId?: string;
  postId?: string;
  [key: string]: string | undefined;
}

/** Firestore'daki `users/{uid}` dokümanı için beklenen alanlar. */
interface UserDoc {
  fcmToken?: string;
}

/* ------------ Helpers ------------ */

/**
 * Hedef kullanıcıya FCM bildirimi gönderir.
 *
 * @template T
 * @param {string}              targetUserId  UID of recipient user.
 * @param {NotificationPayload} payload       Title, body, etc.
 * @param {NotificationData=}   data          Extra key/value data.
 * @return {Promise<boolean>}  true → sent, false → no token / no user.
 */
export async function sendPushNotification(
  targetUserId: string,
  payload: NotificationPayload,
  data?: NotificationData
): Promise<boolean> {
  try {
    console.log("Push notification payload:", {
      targetUserId,
      imageUrl: payload.imageUrl,
      title: payload.title
    });

    const userDocSnap = (await admin
      .firestore()
      .collection("users")
      .doc(targetUserId)
      .get()) as FirebaseFirestore.DocumentSnapshot<UserDoc>;

    if (!userDocSnap.exists) {
      console.log("User not found:", targetUserId);
      return false;
    }

    const {fcmToken} = userDocSnap.data() ?? {};
    if (!fcmToken) {
      console.log("FCM token not found for user:", targetUserId);
      return false;
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
        imageUrl: payload.imageUrl, // iOS'ta sağ tarafta küçük thumbnail olarak görünür
      },
      data: {
        type: payload.type,
        fromUserId: payload.fromUserId ?? "",
        postId: payload.postId ?? "",
        imageUrl: payload.imageUrl ?? "", // Extension için data'ya da ekle
        ...data,
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
            "mutable-content": 1,
            "content-available": 1,
          },
        },
        fcmOptions: {
          imageUrl: payload.imageUrl, // iOS thumbnail için
        },
        headers: {
          "apns-priority": "10",
        },
      },
      android: {
        notification: {
          icon: "ic_notification",
          color: "#7C3AED",
          imageUrl: payload.imageUrl, // Android'de büyük resim olarak görünür
        },
      },
    };

    console.log("Sending message with imageUrl:", payload.imageUrl);
    await admin.messaging().send(message);
    console.log("Push notification sent successfully");
    return true;
  } catch (error) {
    console.error("Push notification error:", error);
    return false;
  }
}

/**
 * "Takip" bildirimi gönderen yardımcı sarmal.
 *
 * @param {string}  targetUserId     UID of recipient.
 * @param {string}  fromUserId       UID of follower.
 * @param {string}  fromDisplayName  Follower's display name.
 * @param {string}  fromUsername     Follower's username.
 * @param {string=} fromPhotoURL     Follower's photo URL.
 * @return {Promise<boolean>}       Send result.
 */
export async function sendFollowNotification(
  targetUserId: string,
  fromUserId: string,
  fromDisplayName: string,
  fromUsername: string,
  fromPhotoURL?: string
): Promise<boolean> {
  console.log("sendFollowNotification called:", {
    targetUserId,
    fromUserId,
    fromDisplayName,
    fromPhotoURL
  });

  // URL validation ekle
  let validImageUrl = fromPhotoURL;
  if (fromPhotoURL && !fromPhotoURL.startsWith('http')) {
    console.log("Invalid image URL format:", fromPhotoURL);
    validImageUrl = undefined;
  }
  console.log("Using image URL:", validImageUrl);

  return sendPushNotification(
    targetUserId,
    {
      title: "Yeni Takipçi",
      body: `${fromDisplayName} seni takip etmeye başladı`,
      type: "follow",
      fromUserId,
      imageUrl: validImageUrl,
    },
    {
      type: "follow",
      fromUserId,
      fromDisplayName,
      fromUsername,
      fromPhotoURL: validImageUrl ?? "",
    }
  );
}

export async function sendLikeNotification(
  targetUserId: string,
  fromUserId: string,
  fromDisplayName: string,
  postId: string,
  fromPhotoURL?: string
): Promise<boolean> {
  const payload: NotificationPayload = {
    title: "Yeni Beğeni",
    body: `${fromDisplayName} gönderini beğendi`,
    type: "like",
    fromUserId,
    postId,
    imageUrl: fromPhotoURL,
  };

  const data: NotificationData = {
    type: "like",
    fromUserId,
    postId,
    fromDisplayName,
  };

  return await sendPushNotification(targetUserId, payload, data);
}

export async function sendCommentNotification(
  targetUserId: string,
  fromUserId: string,
  fromDisplayName: string,
  postId: string,
  commentText: string,
  fromPhotoURL?: string
): Promise<boolean> {
  const payload: NotificationPayload = {
    title: "Yeni Yorum",
    body: `${fromDisplayName}: ${commentText}`,
    type: "comment",
    fromUserId,
    postId,
    imageUrl: fromPhotoURL,
  };

  const data: NotificationData = {
    type: "comment",
    fromUserId,
    postId,
    fromDisplayName,
    commentText,
  };

  return await sendPushNotification(targetUserId, payload, data);
} 