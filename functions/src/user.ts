import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const deleteUserData = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
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
