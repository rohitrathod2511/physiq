const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

console.log('Script started. Current directory:', process.cwd());
console.log('Script location:', __dirname);
fs.writeFileSync(path.join(__dirname, 'startup_log.txt'), 'SCRIPT_STARTED\n');

// Initialize Firebase Admin
// Key is in functions/, this script is in functions/scripts/
// So key is at ../physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json relative to this file
const serviceAccountPath = path.join(__dirname, '..', 'physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json');
console.log('Looking for service account at:', serviceAccountPath);

try {
  if (!fs.existsSync(serviceAccountPath)) {
      throw new Error(`Service account file not found at ${serviceAccountPath}`);
  }
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase initialized.');
} catch (e) {
  console.error('CRITICAL ERROR: Failed to initialize Firebase.', e);
  process.exit(1);
}


const db = getFirestore();

async function ingestIndianFoods() {
  console.log('Reading Indian foods JSON...');
  const jsonPath = path.join(__dirname, 'indian_foods.json');
  console.log('JSON path:', jsonPath);

  if (!fs.existsSync(jsonPath)) {
      console.error('JSON file not found!');
      process.exit(1);
  }

  const rawData = fs.readFileSync(jsonPath, 'utf8');
  const foods = JSON.parse(rawData);

  console.log(`Found ${foods.length} base food entries to ingest.`);

  const batchSize = 400; 
  let batch = db.batch();
  let count = 0;
  let totalProcessed = 0;

  for (const food of foods) {
    const servings = food.servings || {};
    const servingKeys = Object.keys(servings);
    
    // If no servings defined, skip or create a default? 
    // For now, if no serving, we can't create a unit-based doc. 
    // Or we assume 100g is a unit? Let's skip to be safe/strict for now or define 'standard' 100g.
    if (servingKeys.length === 0) {
        console.warn(`Skipping ${food.name} - No servings defined.`);
        continue;
    }

    // Determine default serving for alias mapping (prioritize 'medium', 'bowl', 'piece')
    let defaultServingKey = servingKeys.find(k => ['medium', 'bowl', 'piece', 'glass'].includes(k)) || servingKeys[0];

    for (const servingUnit of servingKeys) {
      const weightG = servings[servingUnit]; // e.g., 30
      const multiplier = weightG / 100;
      
      // Generate ID: sanitized_name_unit (e.g., roti_medium)
      const sanitizedName = food.name.toLowerCase().replace(/[^a-z0-9]/g, '_');
      const docId = `${sanitizedName}_${servingUnit}`;
      const foodRef = db.collection('foods').doc(docId);

      const nutrition = {
        calories: Math.round(food.calories_per_100g * multiplier),
        protein: Number((food.protein_per_100g * multiplier).toFixed(1)),
        carbs: Number((food.carbs_per_100g * multiplier).toFixed(1)),
        fat: Number((food.fat_per_100g * multiplier).toFixed(1)),
      };

      const foodData = {
        id: docId,
        name: food.name, // e.g., "Roti (Chapati)"
        category: food.category || 'General',
        unit: `1 ${servingUnit}`, // e.g., "1 piece"
        base_weight_g: weightG,
        nutrition_per_unit: nutrition,
        aliases: food.aliases || [],
        isIndian: true,
        source: "internal"
      };

      batch.set(foodRef, foodData);
      
      count++;
      totalProcessed++;
    }

    // 2. Create Aliases (Only point to the DEFAULT serving size to avoid duplicate results for "Roti")
    const allAliases = [food.name, ...(food.aliases || [])];
    const defaultDocId = `${food.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${defaultServingKey}`;

    for (const alias of allAliases) {
      if (!alias) continue;
      const normalizedAlias = alias.toLowerCase().trim();
      if (!normalizedAlias) continue;

      const aliasRef = db.collection('food_aliases').doc(normalizedAlias);
      batch.set(aliasRef, {
        alias: normalizedAlias,
        foodId: defaultDocId
      });
      // count alias writes too for batching? Technically yes, but less critical. 
      // Let's add them to batch count to be safe.
      count++;
    }

    if (count >= batchSize) {
      console.log(`Committing batch of ${count} ops...`);
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    console.log('Committing final batch...');
    await batch.commit();
  }

  console.log('Ingestion Complete!');
}

function generateKeywords(name, aliases) {
  const words = new Set();
  name.toLowerCase().split(' ').forEach(w => words.add(w));
  if (aliases) {
    aliases.forEach(a => a.toLowerCase().split(' ').forEach(w => words.add(w)));
  }
  return Array.from(words);
}

ingestIndianFoods().catch(e => {
    console.error('Fatal script error:', e);
});
