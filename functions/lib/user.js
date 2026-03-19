"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserData = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();
exports.deleteUserData = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const uid = request.auth.uid;
    // Check for dryRun flag if needed, or just proceed.
    // Real deletion logic:
    // 1. Delete user document
    await db.collection('users').doc(uid).delete();
    // 2. Delete auth record
    await admin.auth().deleteUser(uid);
    // 3. Cleanup other collections (invites, etc.) - simplified for now
    return { success: true };
});
//# sourceMappingURL=user.js.map