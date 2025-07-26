import * as admin from "firebase-admin";
import { onCall, CallableRequest } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { sendFollowNotification } from "../notifications/pushNotifications";

interface FollowData {
  targetUserId: string;
}

interface FollowResponse {
  success: boolean;
  message?: string;
}

interface UserPublicData {
  displayName?: string;
  username?: string;
  photoURL?: string;
}

export const followUser = onCall(
  { region: "us-east1" },
  async (req: CallableRequest<FollowData>): Promise<FollowResponse> => {
    const { data, auth } = req;
    
    if (!auth) {
      throw new Error("Kullanıcı kimlik doğrulaması gerekli");
    }

    const me = auth.uid;
    const { targetUserId } = data;

    if (!targetUserId) {
      throw new Error("targetUserId gerekli");
    }

    if (me === targetUserId) {
      throw new Error("Kendini takip edemezsin");
    }

    const db = admin.firestore();

    // Referanslar
    const meRef = db.collection("users").doc(me);
    const targetRef = db.collection("users").doc(targetUserId);
    const followerRef = targetRef.collection("followers").doc(me);
    const followingRef = meRef.collection("following").doc(targetUserId);

    try {
      await db.runTransaction(async (trx) => {
        const followerSnap = await trx.get(followerRef);
        if (followerSnap.exists) {
          throw new Error("Zaten takip ediyorsun");
        }

        // Kullanıcı bilgilerini al
        const meSnap = await trx.get(meRef);
        const targetSnap = await trx.get(targetRef);

        if (!meSnap.exists || !targetSnap.exists) {
          throw new Error("Kullanıcı bulunamadı");
        }

        const fromData = meSnap.data() as UserPublicData;

        // Takip ilişkileri ve sayaçlar
        trx.set(followerRef, { createdAt: FieldValue.serverTimestamp() });
        trx.set(followingRef, { createdAt: FieldValue.serverTimestamp() });
        trx.update(targetRef, { followersCount: FieldValue.increment(1) });
        trx.update(meRef, { followsCount: FieldValue.increment(1) });

        // In-app bildirim oluştur
        const notifRef = targetRef.collection("notifications").doc();
        const notifData = {
          type: "follow",
          fromUserId: me,
          fromDisplayName: fromData.displayName ?? "",
          fromUsername: fromData.username ?? "",
          fromPhotoURL: fromData.photoURL ?? "",
          createdAt: FieldValue.serverTimestamp(),
          isRead: false,
        };

        trx.set(notifRef, notifData);
      });

      // Push notification gönder (transaction dışında)
      try {
        const meDoc = await meRef.get();
        const fromData = meDoc.data() as UserPublicData;
        
        await sendFollowNotification(
          targetUserId,
          me,
          fromData.displayName ?? "Bir kullanıcı",
          fromData.username ?? "",
          fromData.photoURL
        );
      } catch (pushError) {
        console.error("Push notification gönderme hatası:", pushError);
        // Push notification hatası takip işlemini etkilemez
      }

      return { success: true };

    } catch (error) {
      console.error("Follow hatası:", error);
      throw new Error(error instanceof Error ? error.message : "Takip edilemedi");
    }
  }
);

export const unfollowUser = onCall(
  { region: "us-east1" },
  async (req: CallableRequest<FollowData>): Promise<FollowResponse> => {
    const { data, auth } = req;
    
    if (!auth) {
      throw new Error("Kullanıcı kimlik doğrulaması gerekli");
    }

    const me = auth.uid;
    const { targetUserId } = data;

    if (!targetUserId) {
      throw new Error("targetUserId gerekli");
    }

    if (me === targetUserId) {
      throw new Error("Kendini takipten çıkaramazsın");
    }

    const db = admin.firestore();

    // Referanslar
    const meRef = db.collection("users").doc(me);
    const targetRef = db.collection("users").doc(targetUserId);
    const followerRef = targetRef.collection("followers").doc(me);
    const followingRef = meRef.collection("following").doc(targetUserId);

    try {
      await db.runTransaction(async (trx) => {
        const followerSnap = await trx.get(followerRef);
        if (!followerSnap.exists) {
          throw new Error("Zaten takip etmiyorsun");
        }

        // Takip ilişkilerini sil ve sayaçları azalt
        trx.delete(followerRef);
        trx.delete(followingRef);
        trx.update(targetRef, { followersCount: FieldValue.increment(-1) });
        trx.update(meRef, { followsCount: FieldValue.increment(-1) });
      });

      return { success: true };

    } catch (error) {
      console.error("Unfollow hatası:", error);
      throw new Error(error instanceof Error ? error.message : "Takipten çıkılamadı");
    }
  }
); 