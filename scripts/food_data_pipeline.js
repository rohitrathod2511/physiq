const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================
// Path to your service account key file (download from Firebase Console)
const SERVICE_ACCOUNT_KEY_PATH = './service-account-key.json'; 

// Input Data Files (USDA Format expected, or simplified JSON for this demo)
const FOUNDATION_FOODS_PATH = './foundation_foods.json';
const BRANDED_FOODS_PATH = './branded_foods.json';

// Target Collection
const COLLECTION_NAME = 'foods';

// Global Categories (Nutrition-First)
const CATEGORIES = [
  "Staple Foods",
  "Fast Food & Street Food",
  "Traditional / Regional Foods",
  "Protein Sources",
  "Vegetarian & Vegan",
  "Fruits",
  "Vegetables",
  "Snacks & Sweets",
  "Beverages",
  "Dairy & Fats"
];

// Helper to keywords generation (lowercase, tokenized)
const generateKeywords = (name, aliases = []) => {
    const text = [name, ...aliases].join(' ').toLowerCase();
    // Split by spaces, remove special chars
    const tokens = text.replace(/[^\w\s]/g, '').split(/\s+/);
    // Remove duplicates and empty strings
    return [...new Set(tokens.filter(t => t.length > 2))]; // Filter small words
};

// ============================================================================
// PIPELINE LOGIC
// ============================================================================

async function runPipeline() {
    console.log("🚀 Starting Food Data Pipeline...");

    // 1. Initialize Firebase Admin
    if (!fs.existsSync(SERVICE_ACCOUNT_KEY_PATH)) {
        console.warn(`⚠️  Service account key not found at ${SERVICE_ACCOUNT_KEY_PATH}.`);
        console.warn("    Please place your 'service-account-key.json' in the scripts folder to run this against real Firestore.");
        console.warn("    Continuing in DRY RUN mode (logic check only)...");
        // return; // In real usage we would return, but for this task I'll proceed to show logic.
    } else {
        const serviceAccount = require(SERVICE_ACCOUNT_KEY_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log("✅ Firebase Admin Initialized");
    }

    // 2. Load and Process Data
    // NOTE: In a real scenario with 3GB files, we would use a stream reader (e.g. 'JSONStream' or 'csv-parser').
    // For this deliverables demonstration, we simulate the processing logic on sample data.
    
    const rawFoods = loadSampleData(); // Simulating reading the files
    console.log(`📦 Loaded ${rawFoods.length} raw items for processing...`);

    const processedFoods = [];

    for (const item of rawFoods) {
        // Normalization Logic
        const normalized = normalizeFood(item);
        if (normalized) {
            processedFoods.push(normalized);
        }
    }

    console.log(`♻️  Normalized into ${processedFoods.length} unique food concepts.`);

    // 3. Upload to Firestore (Batching)
    if (admin.apps.length > 0) {
        const db = admin.firestore();
        const batchSize = 400; // Firestore limit is 500
        let batch = db.batch();
        let count = 0;
        let total = 0;

        for (const food of processedFoods) {
            // Create a deterministically random ID or use normalized name hash
            const docRef = db.collection(COLLECTION_NAME).doc(); 
            batch.set(docRef, food);
            count++;

            if (count >= batchSize) {
                await batch.commit();
                total += count;
                console.log(`☁️  Uploaded ${total} foods...`);
                batch = db.batch();
                count = 0;
            }
        }

        if (count > 0) {
            await batch.commit();
            total += count;
        }
        console.log(`✅ Upload Complete! Total documents: ${total}`);
    } else {
        console.log("⚠️  Skipping upload (Dry Run).");
        console.log("Sample Output:", processedFoods.slice(0, 3));
    }

    // 4. Cleanup
    // fs.unlinkSync(FOUNDATION_FOODS_PATH);
    // fs.unlinkSync(BRANDED_FOODS_PATH);
    console.log("🧹 Cleanup complete.");
}

// ============================================================================
// DATA TRANSFORMATION
// ============================================================================

function normalizeFood(rawItem) {
    // Logic to map raw USDA/External data to our Schema
    // This is where you'd put regex mapping for categories, etc.
    
    // Example heuristic for categorization
    const nameLower = rawItem.description.toLowerCase();
    let category = "Staple Foods"; // Default

    if (nameLower.includes("pizza") || nameLower.includes("burger")) category = "Fast Food & Street Food";
    else if (nameLower.includes("chicken") || nameLower.includes("egg")) category = "Protein Sources";
    else if (nameLower.includes("apple") || nameLower.includes("banana")) category = "Fruits";
    // ... add more rules
    
    // Construct the object
    const aliases = rawItem.aliases || [];
    
    return {
        name: capitalize(rawItem.description),
        aliases: aliases,
        searchKeywords: generateKeywords(rawItem.description, aliases), // Important for search
        category: category,
        subcategory: rawItem.subcategory || "General",
        calories: rawItem.calories,
        protein: rawItem.protein,
        carbs: rawItem.carbs,
        fat: rawItem.fat,
        servingUnit: rawItem.servingSize || "100g",
        lastUpdated: admin.firestore.Timestamp.now()
    };
}

function capitalize(str) {
    return str.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
}

// ============================================================================
// SAMPLE DATA GENERATOR (For Dev Seeding)
// ============================================================================
function loadSampleData() {
    // This replaces reading the big 3GB file for now.
    // Provides 2 items per category to verify the app works.
    return [
        { description: "White Rice, Cooked", category: "Staple Foods", calories: 130, protein: 2.7, carbs: 28, fat: 0.3, servingSize: "1 cup" },
        { description: "Whole Wheat Bread", category: "Staple Foods", calories: 247, protein: 12, carbs: 41, fat: 3.4, servingSize: "2 slices" },
        { description: "Cheese Pizza", category: "Fast Food & Street Food", calories: 266, protein: 11, carbs: 33, fat: 10, servingSize: "1 slice" },
        { description: "Chicken Burger", category: "Fast Food & Street Food", calories: 500, protein: 25, carbs: 45, fat: 22, servingSize: "1 burger" },
        { description: "Chicken Breast, Grilled", category: "Protein Sources", calories: 165, protein: 31, carbs: 0, fat: 3.6, servingSize: "100g" },
        { description: "Boiled Egg", category: "Protein Sources", calories: 155, protein: 13, carbs: 1.1, fat: 11, servingSize: "2 large" },
        { description: "Apple, Medium", category: "Fruits", calories: 95, protein: 0.5, carbs: 25, fat: 0.3, servingSize: "1 medium" },
        { description: "Banana", category: "Fruits", calories: 105, protein: 1.3, carbs: 27, fat: 0.3, servingSize: "1 medium" },
        { description: "Spinach, Raw", category: "Vegetables", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, servingSize: "100g" },
        { description: "Broccoli, Steamed", category: "Vegetables", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, servingSize: "1 cup" },
        { description: "Milk, Whole", category: "Dairy & Fats", calories: 149, protein: 8, carbs: 12, fat: 8, servingSize: "1 cup" },
        { description: "Cheddar Cheese", category: "Dairy & Fats", calories: 402, protein: 25, carbs: 1.3, fat: 33, servingSize: "100g" },
        { description: "Potato Chips", category: "Snacks & Sweets", calories: 536, protein: 7, carbs: 53, fat: 35, servingSize: "100g" },
        { description: "Chocolate Bar", category: "Snacks & Sweets", calories: 546, protein: 4.9, carbs: 61, fat: 31, servingSize: "100g" },
        { description: "Orange Juice", category: "Beverages", calories: 45, protein: 0.7, carbs: 10, fat: 0.2, servingSize: "100ml" },
        { description: "Black Coffee", category: "Beverages", calories: 2, protein: 0, carbs: 0, fat: 0, servingSize: "1 cup" },
    ];
}

if (require.main === module) {
    runPipeline().catch(console.error);
}
