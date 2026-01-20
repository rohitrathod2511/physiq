"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.awardContestPrizes = exports.recomputeLeaderboard = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
// Helper to calculate date difference in days
function getDaysDiff(date1, date2) {
    const oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
    // Reset time part to ensure we count calendar days
    const d1 = new Date(date1.getFullYear(), date1.getMonth(), date1.getDate());
    const d2 = new Date(date2.getFullYear(), date2.getMonth(), date2.getDate());
    return Math.round(Math.abs((d1.getTime() - d2.getTime()) / oneDay));
}
exports.recomputeLeaderboard = functions.https.onCall(async (data, context) => {
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
    // Fetch last 90 days of summaries for streak/consistency calculation
    const summariesSnap = await userRef.collection('daily_summaries')
        .orderBy('date', 'desc')
        .limit(90)
        .get();
    let streakDays = 0;
    let totalActiveDays = 0;
    let totalCaloriesBurned = 0;
    const today = new Date();
    let lastDate = today;
    let isStreakBroken = false;
    const summaries = summariesSnap.docs.map(d => d.data());
    // Iterate through daily summaries to calculate streak
    for (const summary of summaries) {
        // Parse YYYY-MM-DD
        const dateStr = summary.date;
        const dateParts = dateStr.split('-');
        // Note: Month is 0-indexed in JS Date
        const summaryDate = new Date(Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]));
        const diff = getDaysDiff(lastDate, summaryDate);
        // Activity check: Logged calories or exercise or at least protein/carbs/fat > 0
        const isActive = (summary.calories > 0) ||
            (summary.exerciseCalories > 0) ||
            (summary.protein > 0);
        if (isActive) {
            totalActiveDays++;
            totalCaloriesBurned += (summary.exerciseCalories || 0);
            if (!isStreakBroken) {
                if (diff <= 1) {
                    // Consecutive day (0 = same day, 1 = yesterday relative to last checked)
                    // If it's the first check (streak 0), we count it.
                    // If it's a subsequent check, diff must be 1 to increment (consecutive)
                    // But wait, if I logged today (diff 0), streak=1.
                    // Next doc is yesterday (diff 1 from today), streak=2. 
                    streakDays++;
                    lastDate = summaryDate;
                }
                else {
                    // Gap > 1 day means streak is broken
                    isStreakBroken = true;
                }
            }
        }
        else {
            // If we encounter an inactive day doc (rare if we only create docs on activity, but possible if created empty)
            if (!isStreakBroken && diff > 0) {
                // If it's today and inactive, we don't break yet (maybe user logs later)
                // But if it's yesterday and inactive, streak breaks.
                if (getDaysDiff(today, summaryDate) > 0) {
                    isStreakBroken = true;
                }
            }
        }
    }
    // Consistency (last 30 days)
    // We cap at 1.0 (100%)
    const consistencyPct = Math.min(totalActiveDays / 30.0, 1.0) * 100;
    // Activity Points (e.g. 1 point per 100 kcal burned)
    const activityPoints = Math.floor(totalCaloriesBurned / 100);
    const engagementBonus = (userData === null || userData === void 0 ? void 0 : userData.engagementBonus) || 0;
    // Score Formula
    const score = (Math.min(streakDays, 60) * 2.0) + (consistencyPct * 1.5) + activityPoints + engagementBonus;
    // Update user doc with new stats
    await userRef.update({
        leaderboardScore: score,
        streakDays: streakDays,
        consistencyPct: consistencyPct,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    // Update global leaderboard cache
    await db.collection('leaderboards').doc('global').collection('users').doc(uid).set({
        uid: uid,
        displayName: (userData === null || userData === void 0 ? void 0 : userData.displayName) || 'Anonymous',
        country: (userData === null || userData === void 0 ? void 0 : userData.country) || 'IN',
        score: score,
        streakDays: streakDays,
        consistencyPct: consistencyPct,
        lastActive: admin.firestore.FieldValue.serverTimestamp()
    });
    return { score, streakDays, consistencyPct };
});
// Scheduled function to award prizes (stub)
exports.awardContestPrizes = functions.pubsub.schedule('0 0 1 * *').onRun(async (context) => {
    console.log('Awarding contest prizes...');
    // TODO: Implement prize distribution
    return null;
});
//# sourceMappingURL=leaderboard.js.map