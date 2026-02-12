
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

// Ensure Firebase is initialized if not already
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

// FATSECRET CONFIG - Ideally set via creating a .env file or using firebase functions:config:set fatsecret.id="..." fatsecret.secret="..."
// Using defineSecret/defineString is better in v2 but let keeps it simple for now.
const FATSECRET_CLIENT_ID = process.env.FATSECRET_CLIENT_ID || functions.config().fatsecret?.id || 'YOUR_CLIENT_ID';
const FATSECRET_CLIENT_SECRET = process.env.FATSECRET_CLIENT_SECRET || functions.config().fatsecret?.secret || 'YOUR_CLIENT_SECRET';
const FATSECRET_Token_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';

// Helper: Get Access Token (Client Credentials)
// Should cache token in memory or Firestore to avoid hitting limit
let cachedToken: string | null = null;
let tokenExpiry: number = 0;

async function getAccessToken(): Promise<string> {
    if (cachedToken && Date.now() < tokenExpiry) {
        return cachedToken;
    }

    try {
        const auth = Buffer.from(`${FATSECRET_CLIENT_ID}:${FATSECRET_CLIENT_SECRET}`).toString('base64');
        const response = await axios.post(FATSECRET_Token_URL, 'grant_type=client_credentials&scope=basic', {
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        cachedToken = response.data.access_token;
        // token expires in response.data.expires_in seconds usually (86400). Subtract buffer.
        tokenExpiry = Date.now() + ((response.data.expires_in || 3600) * 1000) - 60000;
        return cachedToken!;
    } catch (error) {
        console.error("FatSecret Auth Error:", error);
        throw new functions.https.HttpsError('internal', 'Failed to authenticate with FatSecret API');
    }
}

// 1. SEARCH FOOD
export const searchFood = functions.https.onCall(async (data: any, context: any) => {
    // Auth check
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const query = data.query;
    if (!query) throw new functions.https.HttpsError('invalid-argument', 'Query is required.');

    try {
        const token = await getAccessToken();
        
        // Call FatSecret foods.search
        // format=json is required
        const response = await axios.get(FATSECRET_API_URL, {
            params: {
                method: 'foods.search',
                search_expression: query,
                format: 'json',
                max_results: 20
            },
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const foods = response.data.foods?.food || [];
        // If single result, it might be an object instead of array depending on API quirk, but usually array with search
        const results = Array.isArray(foods) ? foods : [foods];

        // Map to our structure
        return results.map((f: any) => ({
            id: f.food_id,
            name: f.food_name,
            description: f.food_description, // Usually contains quick calories info
            brand: f.brand_name,
            type: f.food_type
        }));

    } catch (error) {
        console.error("Search API Error:", error);
        throw new functions.https.HttpsError('internal', 'Failed to search food.');
    }
});

// 2. GET FOOD DETAILS (By ID) - returns serving sizes
export const getFoodDetails = functions.https.onCall(async (data: any, context: any) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const foodId = data.foodId;
    if (!foodId) throw new functions.https.HttpsError('invalid-argument', 'Food ID is required.');

    // CHECK CACHE FIRST in Firestore 'foods_cache'
    const cacheRef = db.collection('foods_cache').doc(String(foodId));
    const cacheDoc = await cacheRef.get();
    
    // Cache valid for 30 days?
    if (cacheDoc.exists) {
        const cachedData = cacheDoc.data();
        if (cachedData && cachedData.cachedAt && (Date.now() - cachedData.cachedAt.toMillis() < 1000 * 60 * 60 * 24 * 30)) {
            return cachedData.details;
        }
    }

    try {
        const token = await getAccessToken();
        
        const response = await axios.get(FATSECRET_API_URL, {
            params: {
                method: 'food.get.v2',
                food_id: foodId,
                format: 'json'
            },
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const food = response.data.food;
        
        // Parse Servings
        let servings = food.servings?.serving || [];
        if (!Array.isArray(servings)) servings = [servings]; // Handle single serving object

        const details = {
            id: food.food_id,
            name: food.food_name,
            brand: food.brand_name,
            servings: servings.map((s: any) => ({
                id: s.serving_id,
                description: s.serving_description, // e.g. "1 cup", "1 slice"
                metric_serving_amount: s.metric_serving_amount,
                metric_serving_unit: s.metric_serving_unit,
                calories: Number(s.calories),
                protein: Number(s.protein),
                carbs: Number(s.carbohydrate),
                fat: Number(s.fat),
                fiber: Number(s.fiber),
                sugar: Number(s.sugar)
            }))
        };

        // Save to cache
        await cacheRef.set({
            details: details,
            cachedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return details;

    } catch (error) {
        console.error("Get Food Details Error:", error);
        throw new functions.https.HttpsError('internal', 'Failed to get food details.');
    }
});

// 3. BARCODE SEARCH
export const searchBarcode = functions.https.onCall(async (data: any, context: any) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const barcode = data.barcode;
    if (!barcode) throw new functions.https.HttpsError('invalid-argument', 'Barcode is required.');

     try {
        const token = await getAccessToken();
        
        const response = await axios.get(FATSECRET_API_URL, {
            params: {
                method: 'food.find_id_for_barcode',
                barcode: barcode,
                format: 'json'
            },
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const foodId = response.data.food_id?.value;

        if (!foodId) {
             return null; // Not found
        }

        // Now get details
        // We can just call the internal function logic or return ID and let frontend call getDetails
        // Returning ID is simpler for separation
        return { foodId: foodId };

    } catch (error) {
        console.error("Barcode Error:", error);
        throw new functions.https.HttpsError('internal', 'Failed to search barcode.');
    }
});

// 4. ANALYZE FOOD IMAGE (AI)
export const analyzeFoodImage = functions.https.onCall(async (data: any, context: any) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const imageBase64 = data.image; // Base64 string
    const mimeType = data.mimeType || 'image/jpeg';
    
    if (!imageBase64) throw new functions.https.HttpsError('invalid-argument', 'Image is required.');

    try {
        const projectId = process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
        const location = 'us-central1'; // Default
        const model = 'gemini-1.5-flash';

        // Get Google Auth Token
        // admin.app().options.credential might be a Certificate object or applicationDefault
        // The surest way in Cloud Functions env is using google-auth-library which is a dependency of firebase-admin
        const { GoogleAuth } = require('google-auth-library');
        const auth = new GoogleAuth({
            scopes: 'https://www.googleapis.com/auth/cloud-platform'
        });
        const client = await auth.getClient();
        const accessToken = (await client.getAccessToken()).token;

        const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;

        const prompt = `
        Analyze this image of food. Identify the main dish.
        Return ONLY valid JSON with this structure:
        {
            "meal_name": "Food Name",
            "quantity": 1, 
            "unit": "serving unit (e.g. plate, bowl, slice, piece, cup)"
        }
        Example: {"meal_name": "Poha", "quantity": 1, "unit": "plate"}
        If multiple items, pick the main one. return quantity as number.
        Do not include markdown or backticks.
        `;

        const response = await axios.post(url, {
            contents: [{
                role: 'user',
                parts: [
                    { text: prompt },
                    { inline_data: { mime_type: mimeType, data: imageBase64 } }
                ]
            }],
            generation_config: {
                response_mime_type: "application/json"
            }
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });

        const content = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!content) throw new Error("No AI response");

        // Parse JSON
        let result;
        try {
            result = JSON.parse(content.trim().replace(/```json|```/g, ''));
        } catch (e) {
            console.error("JSON Parse Error:", content);
            // Fallback - just return raw text as meal_name if parse fails
            return { meal_name: content.substring(0, 50), quantity: 1, unit: 'serving' };
        }

        return result;

    } catch (error: any) {
        console.error("AI Analysis Error:", error.response?.data || error);
        throw new functions.https.HttpsError('internal', 'Failed to analyze image.');
    }
});

// 5. ANALYZE FOOD TEXT (AI)
export const analyzeFoodText = functions.https.onCall(async (data: any, context: any) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const text = data.text;
    if (!text) throw new functions.https.HttpsError('invalid-argument', 'Text is required.');

    try {
        const projectId = process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
        const location = 'us-central1';
        const model = 'gemini-1.5-flash';

        const { GoogleAuth } = require('google-auth-library');
        const auth = new GoogleAuth({ scopes: 'https://www.googleapis.com/auth/cloud-platform' });
        const client = await auth.getClient();
        const accessToken = (await client.getAccessToken()).token;

        const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;

        const prompt = `
        Analyze this food description: "${text}".
        Identify the food name, quantity, and unit.
        Return ONLY valid JSON with this structure:
        {
            "meal_name": "Food Name",
            "quantity": number,
            "unit": "unit"
        }
        Example: "2 plates poha" -> {"meal_name": "Poha", "quantity": 2, "unit": "plate"}
        `;

        const response = await axios.post(url, {
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            generation_config: { response_mime_type: "application/json" }
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });

        const content = response.data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!content) throw new Error("No AI response");

        try {
            return JSON.parse(content.trim().replace(/```json|```/g, ''));
        } catch (e) {
            return { meal_name: text.substring(0, 50), quantity: 1, unit: 'serving' };
        }

    } catch (error: any) {
        console.error("AI Text Analysis Error:", error.response?.data || error);
        throw new functions.https.HttpsError('internal', 'Failed to analyze text.');
    }
});
