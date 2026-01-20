"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserData = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
exports.deleteUserData = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const uid = context.auth.uid;
    // Check for dryRun flag if needed, or just proceed.
    // Real deletion logic:
    // 1. Delete user document
    await db.collection('users').doc(uid).delete();
    // 2. Delete auth record
    await admin.auth().deleteUser(uid);
    // 3. Cleanup other collections (invites, leaderboards, etc.) - simplified for now
    return { success: true };
});
//# sourceMappingURL=user.js.map