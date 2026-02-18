import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const recomputeLeaderboard = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const uid = context.auth.uid;
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'User not found.');
    }

    const userData = userDoc.data();
    
    // Mock calculation logic based on specs
    // score = (min(streakDays, 60) * 2.0) + (consistencyPct * 1.5) + (activityPoints) + engagementBonus
    
    // In a real app, we would fetch activity history. Here we use stored fields or defaults.
    // Assuming we store some stats on the user doc for now or fetch from subcollections.
    
    const streakDays = userData?.streakDays || 0; // You might need to calculate this from daily logs
    const consistencyPct = userData?.consistencyPct || 0;
    const activityPoints = userData?.activityPoints || 0;
    const engagementBonus = userData?.engagementBonus || 0;

    const score = (Math.min(streakDays, 60) * 2.0) + (consistencyPct * 1.5) + activityPoints + engagementBonus;

    // Update user doc
    await userRef.update({
        leaderboardScore: score,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update global leaderboard cache
    await db.collection('leaderboards').doc('global').collection('users').doc(uid).set({
        uid: uid,
        displayName: userData?.displayName || 'Anonymous',
        country: userData?.country || 'IN', // Default to IN
        score: score,
        streakDays: streakDays,
        consistencyPct: consistencyPct,
        lastActive: admin.firestore.FieldValue.serverTimestamp()
    });

    return { score };
});

import { onSchedule } from "firebase-functions/v2/scheduler";

export const awardContestPrizes = onSchedule("0 0 1 * *", async (event) => {
    console.log('Awarding contest prizes...');
    // Logic to query top users and award prizes
});
