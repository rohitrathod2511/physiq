const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require('axios');
const { config } = require("firebase-functions");

// Initialize Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}

setGlobalOptions({ maxInstances: 10, timeoutSeconds: 60 });

// FatSecret API credentials from config
// Use: firebase functions:config:set fatsecret.client_id="ID" fatsecret.client_secret="SECRET"
const FATSECRET_CLIENT_ID = config().fatsecret.client_id;
const FATSECRET_CLIENT_SECRET = config().fatsecret.client_secret;

// Helper to get access token
async function getAccessToken() {
  if (!FATSECRET_CLIENT_ID || !FATSECRET_CLIENT_SECRET) {
      throw new Error('FatSecret credentials not configured');
  }
  
  try {
    const response = await axios.post('https://oauth.fatsecret.com/connect/token', new URLSearchParams({
      grant_type: 'client_credentials',
      scope: 'basic',
    }), {
      auth: {
        username: FATSECRET_CLIENT_ID,
        password: FATSECRET_CLIENT_SECRET,
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    return response.data.access_token;
  } catch (error) {
    console.error('Error getting access token:', error.response ? error.response.data : error.message);
    throw new Error('Failed to authenticate with FatSecret');
  }
}

exports.fatsecretProxy = onRequest({ cors: true }, async (req, res) => {
  // Validate method
  if (req.method !== "GET") {
    return res.status(405).send("Method Not Allowed");
  }

  try {
    const token = await getAccessToken();
    const { method, query, food_id } = req.query; // Expect 'method' param or deduce from inputs

    let apiUrl = 'https://platform.fatsecret.com/rest/server.api';
    let params = { format: 'json' };

    // --- SEARCH FOOD ---
    if (method === 'search' && query) {
       params.method = 'foods.search';
       params.search_expression = query;
       
       const response = await axios.get(apiUrl, {
          headers: { Authorization: `Bearer ${token}` },
          params: params
       });

       const data = response.data;
       let foods = [];
       if (data.foods && data.foods.food) {
           const list = Array.isArray(data.foods.food) ? data.foods.food : [data.foods.food];
           foods = list.map(f => ({
               id: f.food_id,
               name: f.food_name,
               brand: f.brand_name || '',
               description: f.food_description
           }));
       }
       return res.json({ foods });

    } 
    // --- GET FOOD DETAILS ---
    else if (method === 'get_details' && food_id) {
       params.method = 'food.get.v2';
       params.food_id = food_id;

       const response = await axios.get(apiUrl, {
          headers: { Authorization: `Bearer ${token}` },
          params: params
       });

       const data = response.data;
       if (!data.food) {
           return res.status(404).send('Food not found');
       }
       
       const f = data.food;
       
       // Handle servings array
       let rawServings = [];
       if (f.servings && f.servings.serving) {
           rawServings = Array.isArray(f.servings.serving) ? f.servings.serving : [f.servings.serving];
       }

       const servings = rawServings.map(s => ({
           serving_id: s.serving_id,
           serving_description: s.serving_description,
           metric_serving_amount: s.metric_serving_amount,
           metric_serving_unit: s.metric_serving_unit,
           calories: parseFloat(s.calories) || 0,
           protein: parseFloat(s.protein) || 0,
           carbohydrate: parseFloat(s.carbohydrate) || 0,
           fat: parseFloat(s.fat) || 0,
           saturated_fat: parseFloat(s.saturated_fat) || 0,
           polyunsaturated_fat: parseFloat(s.polyunsaturated_fat) || 0,
           monounsaturated_fat: parseFloat(s.monounsaturated_fat) || 0,
           cholesterol: parseFloat(s.cholesterol) || 0,
           sodium: parseFloat(s.sodium) || 0,
           potassium: parseFloat(s.potassium) || 0,
           fiber: parseFloat(s.fiber) || 0,
           sugar: parseFloat(s.sugar) || 0,
           vitamin_a: parseFloat(s.vitamin_a) || 0,
           vitamin_c: parseFloat(s.vitamin_c) || 0,
           calcium: parseFloat(s.calcium) || 0,
           iron: parseFloat(s.iron) || 0,
       }));

       const cleanFood = {
           id: f.food_id,
           name: f.food_name,
           brand: f.brand_name || '',
           type: f.food_type,
           servings: servings
       };

       return res.json(cleanFood);
    } 
    else {
      return res.status(400).send('Invalid parameters. Use method=search&query=... or method=get_details&food_id=...');
    }

  } catch (error) {
    console.error('FatSecret Proxy Error:', error.response ? error.response.data : error.message);
    return res.status(500).send('Internal Server Error');
  }
});

// Existing helper exports if any (e.g. estimateNutrition from index.js remains separate)
