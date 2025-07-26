import * as admin from "firebase-admin";

// Firebase Admin SDK'yı başlat
admin.initializeApp();

// Social functions'ları export et
export * from "./social/follow";
export * from "./auth/username";
export * from "./notifications/pushNotifications"; 