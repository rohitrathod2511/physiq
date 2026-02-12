const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const axios = require('axios'); // Assuming axios is installed or user will install
const fs = require('fs');

// CONFIGURATION
const API_KEY = 'YyKtJPFCj6D3a9Ur8VIigpJqfgxvVEEHOjoON2u6'; // REPLACE THIS WITH YOUR USDA API KEY
const BASE_URL = 'https://api.nal.usda.gov/fdc/v1';

const path = require('path');

// SERVICE ACCOUNT SETUP
// Ensure key exists relative to this script
const serviceAccountPath = path.join(__dirname, '..', 'physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json');
try {
    if (!fs.existsSync(serviceAccountPath)) {
         throw new Error(`Service account file not found at ${serviceAccountPath}`);
    }
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase initialized.");
} catch (e) {
    console.warn("Service account issue, trying default credentials...", e.message);
    admin.initializeApp();
}

const db = getFirestore();

const SEARCH_TERMS = [
  'chicken breast', 'egg', 'milk', 'rice', 'apple', 'banana', 'potato', 
  'bread', 'cheese', 'yogurt', 'oats', 'avocado', 'almonds', 'peanut butter',
  'spinach', 'broccoli', 'carrot', 'cucumber', 'beef', 'pork', 'salmon',
  'tuna', 'pasta', 'tomato', 'onion', 'beans', 'lentils', 'orange',
  'grapes', 'strawberry', 'blueberry', 'watermelon', 'pineapple'
];

async function ingestUSDA() {
  console.log('Starting USDA Ingestion...');
  
  if (API_KEY === 'YOUR_API_KEY_HERE') {
      console.error('ERROR: Please replace YOUR_API_KEY_HERE with a real USDA API Key.');
      return;
  }

  let totalIngested = 0;

  for (const term of SEARCH_TERMS) {
    console.log(`Searching for: ${term}...`);
    try {
      const results = await searchFood(term);
      if (!results || results.length === 0) continue;

      const processedFoods = results.map(processFoodItem).filter(f => f !== null);
      
      await uploadBatch(processedFoods);
      totalIngested += processedFoods.length;
      
      // Rate limiting precaution
      await new Promise(r => setTimeout(r, 1000));
      
    } catch (e) {
      console.error(`Failed to process term "${term}":`, e.message);
    }
  }
  
  console.log(`Ingestion Complete! Total foods: ${totalIngested}`);
}

async function searchFood(query) {
  const url = `${BASE_URL}/foods/search?api_key=${API_KEY}`;
  const response = await axios.post(url, {
    query: query,
    pageSize: 20, // Keep it focused
    dataType: ["Foundation", "SR Legacy"], // Avoid branded foods if possible
    requireAllWords: true
  });
  return response.data.foods;
}

function processFoodItem(item) {
  // Extract Nutrients
  const getNutrient = (id) => {
    const n = item.foodNutrients.find(x => x.nutrientId === id || x.nutrientNumber === id.toString());
    return n ? n.value : 0;
  };

  // USDA Nutrient IDs:
  // 1008 = Calories (Energy)
  // 1003 = Protein
  // 1005 = Carbs
  // 1004 = Fat
  
  const kcal = getNutrient(1008);
  const protein = getNutrient(1003);
  const carbs = getNutrient(1005);
  const fat = getNutrient(1004);

  // If no calories, skip
  if (kcal === 0 && protein === 0 && carbs === 0 && fat === 0) return null;

  // Name cleanup: remove ", raw", ", cooked", etc for alias if needed, but keep full name
  const name = item.description; 
  
  return {
    name: name,
    calories_per_100g: kcal,
    protein_per_100g: protein,
    carbs_per_100g: carbs,
    fat_per_100g: fat,
    servings: {}, // Serving sizes are hard to get standardized from search results, defaulting to 100g base
    category: item.foodCategory || 'General',
    isIndian: false,
    usda_id: item.fdcId
  };
}


async function uploadBatch(foods) {
  if (foods.length === 0) return;
  
  const batch = db.batch();
  
  foods.forEach(food => {
    const docRef = db.collection('foods').doc(food.usda_id.toString());
    batch.set(docRef, food, { merge: true });
    
    // Create simple alias
    const aliasRef = db.collection('food_aliases').doc(food.name.toLowerCase().replace(/[^a-z0-9 ]/g, '').trim());
    batch.set(aliasRef, {
        alias: food.name.toLowerCase(),
        foodId: docRef.id,
        foodName: food.name
    }, { merge: true });
  });

  await batch.commit();
  console.log(`Uploaded ${foods.length} items to Firestore.`);
}

ingestUSDA().catch(console.error);
