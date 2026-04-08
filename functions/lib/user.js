"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteUserData = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();
const storage = admin.storage();
const RECENT_AUTH_WINDOW_SECONDS = 5 * 60;
const BATCH_DELETE_LIMIT = 400;
// Deletes docs returned by a query in safe-sized batches.
async function deleteQuerySnapshot(snapshot) {
    if (snapshot.empty) {
        return 0;
    }
    let deletedCount = 0;
    let batch = db.batch();
    let batchSize = 0;
    for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        batchSize += 1;
        deletedCount += 1;
        if (batchSize >= BATCH_DELETE_LIMIT) {
            await batch.commit();
            batch = db.batch();
            batchSize = 0;
        }
    }
    if (batchSize > 0) {
        await batch.commit();
    }
    return deletedCount;
}
// Deletes top-level records that store a user reference in a field instead of the doc path.
async function deleteWhereEquals(collectionName, fieldName, value) {
    const snapshot = await db.collection(collectionName).where(fieldName, '==', value).get();
    return deleteQuerySnapshot(snapshot);
}
// Removes the deleted user's UID from invite redemption arrays stored on other users' records.
async function scrubInviteUsageReferences(uid) {
    const snapshot = await db.collection('invites').where('usedBy', 'array-contains', uid).get();
    if (snapshot.empty) {
        return 0;
    }
    let updatedCount = 0;
    let batch = db.batch();
    let batchSize = 0;
    for (const doc of snapshot.docs) {
        batch.update(doc.ref, {
            usedBy: admin.firestore.FieldValue.arrayRemove(uid),
        });
        updatedCount += 1;
        batchSize += 1;
        if (batchSize >= BATCH_DELETE_LIMIT) {
            await batch.commit();
            batch = db.batch();
            batchSize = 0;
        }
    }
    if (batchSize > 0) {
        await batch.commit();
    }
    return updatedCount;
}
// Removes referral array entries that contain the deleted user's UID.
async function scrubReferralArrayReferences(uid) {
    const snapshot = await db.collection('users').get();
    if (snapshot.empty) {
        return 0;
    }
    let updatedCount = 0;
    let batch = db.batch();
    let batchSize = 0;
    for (const doc of snapshot.docs) {
        const referrals = doc.get('referrals');
        if (!Array.isArray(referrals)) {
            continue;
        }
        const sanitizedReferrals = referrals.filter((entry) => {
            return !(entry && typeof entry === 'object' && entry.uid === uid);
        });
        if (sanitizedReferrals.length === referrals.length) {
            continue;
        }
        batch.update(doc.ref, { referrals: sanitizedReferrals });
        updatedCount += 1;
        batchSize += 1;
        if (batchSize >= BATCH_DELETE_LIMIT) {
            await batch.commit();
            batch = db.batch();
            batchSize = 0;
        }
    }
    if (batchSize > 0) {
        await batch.commit();
    }
    return updatedCount;
}
// Deletes all files stored under a user-owned prefix in the default bucket.
async function deleteStoragePrefix(prefix) {
    await storage.bucket().deleteFiles({ prefix });
}
// Enforces a recent login on the server before allowing destructive account deletion.
function assertRecentAuthentication(request) {
    var _a, _b;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const signInProvider = (_a = request.auth.token.firebase) === null || _a === void 0 ? void 0 : _a.sign_in_provider;
    if (signInProvider === 'anonymous') {
        return;
    }
    const authTime = Number((_b = request.auth.token.auth_time) !== null && _b !== void 0 ? _b : 0);
    const nowInSeconds = Math.floor(Date.now() / 1000);
    if (!authTime || nowInSeconds - authTime > RECENT_AUTH_WINDOW_SECONDS) {
        throw new https_1.HttpsError('permission-denied', 'Please re-authenticate and try deleting your account again.');
    }
}
exports.deleteUserData = (0, https_1.onCall)(async (request) => {
    assertRecentAuthentication(request);
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const uid = auth.uid;
    // 1. Delete non-path-based user records that the extension cannot discover by UID path alone.
    await Promise.all([
        deleteWhereEquals('custom_foods', 'userId', uid),
        deleteWhereEquals('appFeatureRequests', 'userId', uid),
        deleteWhereEquals('promoCodes', 'ownerUid', uid),
        deleteWhereEquals('invites', 'referrerUid', uid),
        scrubInviteUsageReferences(uid),
        scrubReferralArrayReferences(uid),
    ]);
    // 2. Delete Cloud Storage prefixes created by the mobile app.
    await Promise.all([
        deleteStoragePrefix(`meal_images/${uid}/`),
        deleteStoragePrefix(`progress_photos/${uid}/`),
    ]);
    // 3. Delete the Firebase Auth user server-side.
    // This triggers the official Delete User Data extension, which should be configured
    // in recursive mode for Firestore paths like:
    //   users/{UID},saved_scans/{UID},logs/settingsChanges/{UID}
    await admin.auth().deleteUser(uid);
    return {
        success: true,
        message: 'Account deletion confirmed. All associated data is being permanently deleted.',
    };
});
//# sourceMappingURL=user.js.map