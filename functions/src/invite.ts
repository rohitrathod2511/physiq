import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Generate a random alphanumeric code
function generateCode(length: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

export const createInviteCode = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const uid = request.auth.uid;
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User not found.');
    }

    const userData = userDoc.data();
    if (userData?.invites?.code) {
        return { code: userData.invites.code };
    }

    let code = generateCode(8);
    let codeRef = db.collection('invites').doc(code);
    let codeDoc = await codeRef.get();

    // Simple collision check (retry once)
    if (codeDoc.exists) {
        code = generateCode(8);
        codeRef = db.collection('invites').doc(code);
    }

    const batch = db.batch();

    // Create invite document
    batch.set(codeRef, {
        code: code,
        referrerUid: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        uses: 0,
        usedBy: [],
    });

    // Update user document
    batch.update(userRef, {
        'invites.code': code,
        'invites.createdAt': admin.firestore.FieldValue.serverTimestamp(),
        'invites.redeemedCount': 0,
        'invites.creditedAmount': 0
    });

    await batch.commit();

    return { code };
});

export const claimReferral = onCall(async (request) => {
    const { code, newUserUid } = request.data as { code: string; newUserUid: string };

    // Validate inputs
    if (!code || !newUserUid) {
        throw new HttpsError('invalid-argument', 'Missing code or newUserUid.');
    }

    const inviteRef = db.collection('invites').doc(code);
    const inviteDoc = await inviteRef.get();

    if (!inviteDoc.exists) {
        throw new HttpsError('not-found', 'Invite code not found.');
    }

    const inviteData = inviteDoc.data();
    const referrerUid = inviteData?.referrerUid;

    if (referrerUid === newUserUid) {
        throw new HttpsError('invalid-argument', 'Cannot refer yourself.');
    }

    if (inviteData?.usedBy?.includes(newUserUid)) {
         throw new HttpsError('already-exists', 'Referral already claimed by this user.');
    }

    const referrerRef = db.collection('users').doc(referrerUid);
    // const newUserRef = db.collection('users').doc(newUserUid);

    const REWARD_AMOUNT = 100;
    const BONUS_THRESHOLD = 5;
    const BONUS_AMOUNT = 500;

    await db.runTransaction(async (t) => {
        const rDoc = await t.get(referrerRef);
        if (!rDoc.exists) {
            throw new HttpsError('not-found', 'Referrer user not found.');
        }
        
        const rData = rDoc.data();
        const currentRedeemed = (rData?.invites?.redeemedCount || 0) + 1;
        let credit = REWARD_AMOUNT;
        
        // Check for bonus
        if (currentRedeemed === BONUS_THRESHOLD) {
            credit += BONUS_AMOUNT;
        }

        // Update Invite Doc
        t.update(inviteRef, {
            uses: admin.firestore.FieldValue.increment(1),
            usedBy: admin.firestore.FieldValue.arrayUnion(newUserUid)
        });

        // Update Referrer
        t.update(referrerRef, {
            'invites.redeemedCount': admin.firestore.FieldValue.increment(1),
            'invites.creditedAmount': admin.firestore.FieldValue.increment(credit),
            'referrals': admin.firestore.FieldValue.arrayUnion({
                uid: newUserUid,
                claimedAt: admin.firestore.Timestamp.now(),
                amount: credit,
                status: 'credited'
            })
        });

        // Update New User (e.g. give trial)
        // t.update(newUserRef, { ... });
    });

    return { success: true, amountCredited: REWARD_AMOUNT };
});
