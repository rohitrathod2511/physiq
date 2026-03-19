"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateCanonicalPlan = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();
exports.generateCanonicalPlan = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const uid = request.auth.uid;
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError('not-found', 'User not found.');
    }
    const userData = userDoc.data();
    // Logic to calculate plan based on height, weight, goal, etc.
    // This mirrors the client-side logic but is authoritative.
    const weight = (userData === null || userData === void 0 ? void 0 : userData.weightKg) || 70;
    const height = (userData === null || userData === void 0 ? void 0 : userData.heightCm) || 170;
    const age = new Date().getFullYear() - ((userData === null || userData === void 0 ? void 0 : userData.birthYear) || 2000);
    const gender = (userData === null || userData === void 0 ? void 0 : userData.gender) || 'male';
    // activityLevel is removed as it's not currently used, to pass TS build
    // Mifflin-St Jeor Equation
    let bmr = (10 * weight) + (6.25 * height) - (5 * age);
    if (gender === 'male') {
        bmr += 5;
    }
    else {
        bmr -= 161;
    }
    let tdee = bmr * 1.55; // Default moderate
    // Adjust based on activity level if available
    // Goal adjustment
    const goalWeight = (userData === null || userData === void 0 ? void 0 : userData.goalWeightKg) || weight;
    let targetCalories = tdee;
    if (goalWeight < weight) {
        targetCalories -= 500; // Deficit
    }
    else if (goalWeight > weight) {
        targetCalories += 500; // Surplus
    }
    const plan = {
        calories: Math.round(targetCalories),
        protein: Math.round((targetCalories * 0.3) / 4),
        carbs: Math.round((targetCalories * 0.4) / 4),
        fats: Math.round((targetCalories * 0.3) / 9),
        waterMl: 3000,
        generatedAt: admin.firestore.Timestamp.now()
    };
    await userRef.update({
        currentPlan: plan,
        planHistory: admin.firestore.FieldValue.arrayUnion(plan)
    });
    return plan;
});
//# sourceMappingURL=plan.js.map