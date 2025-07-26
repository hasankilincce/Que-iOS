import * as admin from "firebase-admin";
import { onCall, CallableRequest } from "firebase-functions/v2/https";

interface UsernameCheckData {
  username: string;
}

interface UsernameCheckResponse {
  available: boolean;
  message?: string;
}

interface ReserveUsernameData {
  username: string;
  email: string;
  displayName: string;
}

interface LoginWithUsernameData {
  username: string;
}

interface LoginWithUsernameResponse {
  uid?: string;
  email?: string;
  error?: string;
}

export const checkUsernameAvailable = onCall(
  { region: "us-east1" },
  async (req: CallableRequest<UsernameCheckData>): Promise<UsernameCheckResponse> => {
    const { username } = req.data;

    if (!username) {
      throw new Error("Username gerekli");
    }

    // Username format kontrolü
    const usernameRegex = /^[a-zA-Z0-9._]{3,30}$/;
    if (!usernameRegex.test(username)) {
      return {
        available: false,
        message: "Username sadece harf, rakam, nokta ve alt çizgi içerebilir (3-30 karakter)"
      };
    }

    const db = admin.firestore();
    
    try {
      const userQuery = await db.collection("users")
        .where("username", "==", username.toLowerCase())
        .limit(1)
        .get();

      return {
        available: userQuery.empty,
        message: userQuery.empty ? "Username kullanılabilir" : "Bu username zaten alınmış"
      };

    } catch (error) {
      console.error("Username kontrol hatası:", error);
      throw new Error("Username kontrol edilemedi");
    }
  }
);

export const reserveUsername = onCall(
  { region: "us-east1" },
  async (req: CallableRequest<ReserveUsernameData>): Promise<{ success: boolean }> => {
    const { data, auth } = req;
    
    if (!auth) {
      throw new Error("Kullanıcı kimlik doğrulaması gerekli");
    }

    const { username, email, displayName } = data;

    if (!username || !email || !displayName) {
      throw new Error("Tüm alanlar gerekli");
    }

    const db = admin.firestore();
    const userId = auth.uid;

    try {
      await db.runTransaction(async (transaction) => {
        // Username müsaitlik kontrolü
        const usernameQuery = await db.collection("users")
          .where("username", "==", username.toLowerCase())
          .limit(1)
          .get();

        if (!usernameQuery.empty) {
          throw new Error("Bu username zaten alınmış");
        }

        // Kullanıcı bilgilerini kaydet
        const userRef = db.collection("users").doc(userId);
        const userData = {
          username: username.toLowerCase(),
          displayName,
          email,
          photoURL: "",
          bio: "",
          followersCount: 0,
          followsCount: 0,
          searchKeywords: generateSearchKeywords(displayName, username),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        transaction.set(userRef, userData);
      });

      return { success: true };

    } catch (error) {
      console.error("Username rezervasyon hatası:", error);
      throw new Error(error instanceof Error ? error.message : "Username rezerve edilemedi");
    }
  }
);

export const loginWithUsername = onCall(
  { region: "us-east1" },
  async (req: CallableRequest<LoginWithUsernameData>): Promise<LoginWithUsernameResponse> => {
    const { username } = req.data;

    if (!username) {
      return { error: "Username gerekli" };
    }

    const db = admin.firestore();

    try {
      const userQuery = await db.collection("users")
        .where("username", "==", username.toLowerCase())
        .limit(1)
        .get();

      if (userQuery.empty) {
        return { error: "Kullanıcı bulunamadı" };
      }

      const userDoc = userQuery.docs[0];
      const userData = userDoc.data();

      return {
        uid: userDoc.id,
        email: userData.email
      };

    } catch (error) {
      console.error("Username ile giriş hatası:", error);
      return { error: "Giriş yapılamadı" };
    }
  }
);

// Helper function
function generateSearchKeywords(displayName: string, username: string): string[] {
  function prefixes(text: string): string[] {
    const lower = text.toLowerCase();
    return Array.from({ length: lower.length }, (_, i) => lower.slice(0, i + 1));
  }

  const nameParts = displayName.toLowerCase().split(" ");
  const keywords = new Set<string>();

  // Display name prefixes
  for (const part of nameParts) {
    prefixes(part).forEach(prefix => keywords.add(prefix));
  }

  // Username prefixes
  prefixes(username.toLowerCase()).forEach(prefix => keywords.add(prefix));

  // Full words
  keywords.add(displayName.toLowerCase());
  keywords.add(username.toLowerCase());

  return Array.from(keywords);
} 