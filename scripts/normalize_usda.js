const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ============================================================================
// CONFIGURATION
// ============================================================================

const INPUT_DIR = __dirname;
const FOUNDATION_FILE = path.join(INPUT_DIR, 'FoodData_Central_foundation_food_json_2025-12-18.json');
const BRANDED_FILE = path.join(INPUT_DIR, 'FoodData_Central_branded_food_json_2025-12-18.json');
const OUTPUT_FILE = path.join(INPUT_DIR, 'foods_reduced_normalized.json');

const TARGET_SIZE_MB = 10;
const MAX_ITEMS = 5000;

// Categories Mapping (USDA Category -> Our Global Category)
const CATEGORY_MAP = {
    // Staple Foods
    "Cereal Grains and Pasta": "Staple Foods",
    "Baked Products": "Staple Foods",
    "Breakfast Cereals": "Staple Foods",
    "Grains": "Staple Foods",
    
    // Fast Food
    "Fast Foods": "Fast Food & Street Food",
    "Meals, Entrees, and Side Dishes": "Fast Food & Street Food",
    "Pizza": "Fast Food & Street Food",
    "Restaurant Foods": "Fast Food & Street Food",
    
    // Traditional
    "American Indian/Alaska Native Foods": "Traditional / Regional Foods",
    
    // Protein
    "Poultry Products": "Protein Sources",
    "Pork Products": "Protein Sources",
    "Beef Products": "Protein Sources",
    "Finfish and Shellfish Products": "Protein Sources",
    "Legumes and Legume Products": "Protein Sources",
    "Sausages and Luncheon Meats": "Protein Sources",
    "Eggs": "Protein Sources",
    "Nut and Seed Products": "Protein Sources",
    
    // Veg/Vegan
    // (Handled by keywords or fallback)
    
    // Fruits
    "Fruits and Fruit Juices": "Fruits",
    
    // Vegetables
    "Vegetables and Vegetable Products": "Vegetables",
    
    // Snacks
    "Snacks": "Snacks & Sweets",
    "Sweets": "Snacks & Sweets",
    "Confectioneries": "Snacks & Sweets",
    
    // Beverages
    "Beverages": "Beverages",
    
    // Dairy & Fats
    "Dairy and Egg Products": "Dairy & Fats",
    "Fats and Oils": "Dairy & Fats",
};

// Global Categories List
const GLOBAL_CATEGORIES = [
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

// ============================================================================
// STATE
// ============================================================================

// Map<NormalizedName, FoodItem>
// NormalizedName: lowercase, simplified
const foodMap = new Map();

// Stats
let stats = {
    foundation: 0,
    branded: 0,
    merged: 0,
    skipped: 0
};

// ============================================================================
// MAIN PIPELINE
// ============================================================================

async function run() {
    console.log("🚀 Starting Food Data Normalization Pipeline...");
    
    // 1. Process Foundation Foods (High Quality, Base Truth)
    await processFoundation();
    
    // 2. Process Branded Foods (High Volume, Needs Streaming)
    await processBranded();
    
    // 3. Finalize & Save
    saveOutput();
}

// ============================================================================
// PROCESSORS
// ============================================================================

async function processFoundation() {
    console.log(`\n📦 Reading Foundation Foods: ${path.basename(FOUNDATION_FILE)}`);
    
    try {
        const raw = fs.readFileSync(FOUNDATION_FILE, 'utf8');
        const data = JSON.parse(raw);
        const items = data.FoundationFoods || [];
        
        console.log(`   Found ${items.length} foundation items.`);
        
        for (const item of items) {
           const normalized = normalize(item, 'foundation');
           if (normalized) {
               addToMap(normalized);
               stats.foundation++;
           }
        }
    } catch (e) {
        console.error("Error reading foundation file:", e);
    }
}

async function processBranded() {
    console.log(`\n🌊 Streaming Branded Foods: ${path.basename(BRANDED_FILE)}`);
    console.log("   (This may take a moment...)");

    return new Promise((resolve, reject) => {
        const stream = fs.createReadStream(BRANDED_FILE, { encoding: 'utf8', highWaterMark: 64 * 1024 });
        
        // Simple Buffer Logic for JSON Array Streaming
        // We look for objects between braces `{...}` assuming standard array structure
        let buffer = '';
        let depth = 0;
        let inString = false;
        let isEscaped = false;
        
        stream.on('data', (chunk) => {
            for (let i = 0; i < chunk.length; i++) {
                const char = chunk[i];
                buffer += char;
                
                // Handle strings to ignore braces inside strings
                if (char === '"' && !isEscaped) {
                    inString = !inString;
                }
                if (char === '\\' && !isEscaped) {
                    isEscaped = true;
                } else {
                    isEscaped = false;
                }
                
                if (!inString) {
                    if (char === '{') {
                        depth++;
                    } else if (char === '}') {
                        depth--;
                        if (depth === 0) {
                            // End of an object at root level (inside the array)
                            // Find the start of this object
                            // Ideally, we accumulated just this object.
                            // But since we are appending to buffer, we need to carefully parse.
                            // Optimization: Only parse if buffer looks like a valid object or comma separated
                            
                            // Actually, simpler logic:
                            // If depth goes to 0, we *might* have a full object.
                            // In a huge array: [ {obj}, {obj} ]
                            // depth 0 -> 1 (start) -> ... -> 0 (end).
                            // So whenever depth hits 0 after being >0, we have a potentially complete object string in buffer.
                            
                            // Tricky part: The buffer might contain ", { ... }" from previous.
                            // We need to trim comma/whitespace from start.
                        }
                    }
                }
            }
            
            // Heuristic cleaning of buffer:
            // This manual parser is risky for 3GB.
            // Let's use a simpler heuristic for USDA JSON specifically.
            // USDA Branded JSON is usually: { "BrandedFoods": [ ... ] }
            // Meaning we accept depth 1 -> 2 -> 1.
            // Items are at depth 2.
            
            // Let's defer to a 'split by regex' approach on the buffer which is safer for this specific task
            // provided the file is reasonably formatted.
            // USDA files are often compact.
            
            // ALTERNATIVE: Use 'stream-json' pattern if we could, but we can't.
            // Let's try to process buffer by splitting on "},". 
            // This assumes valid JSON array structure.
            
            processBuffer(false);
        });
        
        stream.on('end', () => {
            processBuffer(true);
            resolve();
        });
        
        stream.on('error', reject);
        
        function processBuffer(isEnd) {
             // Split buffer by "}," to isolate objects
             // This is a naive split but works for 99% of data export formats
             // We must be careful about strings containing "},"
             
             // To be safe, we only split if the buffer gets too large, to avoid OOM
             if (buffer.length < 100000 && !isEnd) return;
             
             // Split logic
             let searchIdx = 0;
             while (true) {
                 const splitIdx = buffer.indexOf('},', searchIdx);
                 if (splitIdx === -1) break;
                 
                 // Check if inside string? Use primitive check (count quotes)
                 // This is slow for 3GB. 
                 // Optimization: Trust the USDA format (standard keys).
                 
                 const potentialChunk = buffer.substring(0, splitIdx + 1);
                 
                 // Try parsing
                 try {
                     // Cleanup leading comma/brackets if first item or subsequent
                     let cleanChunk = potentialChunk.trim();
                     if (cleanChunk.startsWith(',')) cleanChunk = cleanChunk.substring(1).trim();
                     if (cleanChunk.startsWith('[')) cleanChunk = cleanChunk.substring(1).trim(); // start of array
                     if (cleanChunk.startsWith('{"BrandedFoods": [')) cleanChunk = cleanChunk.substring('{"BrandedFoods": ['.length).trim(); // start of file
                     
                     // It might be essential to create a valid JSON object string
                     if (!cleanChunk.startsWith('{')) cleanChunk = '{' + cleanChunk.substring(cleanChunk.indexOf('{') + 1);

                     const item = JSON.parse(cleanChunk);
                     
                     // Helper: Normalize & Add
                     const normalized = normalize(item, 'branded');
                     if (normalized) {
                         if (!foodMap.has(normalized.key)) {
                             // Only add if we have space and it's somewhat unique or popular
                             // For branded, we are stricter.
                             // Check if it matches a Foundation food (normalized name comparison)
                             
                             // Limit total items during streaming to prevent huge map
                             if (foodMap.size < MAX_ITEMS * 1.5) { // Allow some buffer for sorting later
                                 addToMap(normalized);
                                 stats.branded++;
                             }
                         } else {
                             // Merge aliases
                             mergeAliases(normalized);
                             stats.merged++;
                         }
                     }
                     
                     // Sliced successfully
                     buffer = buffer.substring(splitIdx + 2); // skip "},"
                     searchIdx = 0;
                     
                 } catch (e) {
                     // Not a valid JSON yet, maybe inside a string or incomplete
                     // Continue search
                     searchIdx = splitIdx + 2;
                 }
             }
        }
    });
}

// ============================================================================
// NORMALIZATION LOGIC
// ============================================================================

function normalize(item, type) {
    const desc = item.description || "";
    if (!desc) return null;
    
    // Nutrition Extraction (Values are usually per 100g or serving)
    // USDA JSON structure: 
    // item.foodNutrients[] -> { nutrient: { name: "Protein" }, amount: 10.0 }
    
    // Parse Nutrients
    let calories = 0, protein = 0, carbs = 0, fat = 0;
    
    const nutrients = item.foodNutrients || [];
    for (const n of nutrients) {
        const name = n.nutrient?.name || "";
        const amount = n.amount || 0;
        
        // IDs: Energy=1008/2047, Protein=1003, Fat=1004, Carbs=1005
        const id = n.nutrient?.id || n.nutrientId; // different versions have different schema

        if (name.includes("Energy") && (n.nutrient?.unitName === "kcal" || id === 1008 || id === 2047)) {
            calories = amount;
        } else if (name.includes("Protein") || id === 1003) {
            protein = amount;
        } else if (name.includes("Carbohydrate") || id === 1005) {
            carbs = amount;
        } else if (name.includes("Total lipid") || name.includes("Fat") || id === 1004) {
            fat = amount;
        }
    }
    
    // Serving Size
    let servingUnit = "100g";
    let gramWeight = 100;

    // Branded foods often have 'servingSize' and 'servingSizeUnit' (e.g. 28 g)
    if (item.servingSize && item.servingSizeUnit) {
        servingUnit = `${item.servingSize} ${item.servingSizeUnit}`;
        // Adjust nutrition if it was per 100g but we want per serving?
        // USDA Branded data 'foodNutrients' are usually per 100g/100ml basis unless specified otherwise.
        // BUT for the app, we want "Per Serving" or "Per 100g"?
        // App logic usually handles "1 serving" -> multipliers.
        // Let's standardise to: Store 100g values if we can, or store "per serving" values if explicit.
        // ACTUALLY: Foundation foods are per 100g. Branded are usually per 100g in the 'amount' field (standard USDA rule).
        // Scaling to serving size:
        // calories = (calories_per_100g / 100) * servingSize_in_g
        
        // Let's store nutrition per Serving for the App Display (as requested "2 slices pizza")
        // NOTE: If item.servingSizeUnit is NOT 'g' or 'ml', conversion is hard.
        
        // Only convert if we have gram equivalent
        // Branded foods usually provide servingSize (value) and servingSizeUnit (unit).
        // They are strictly mapped to 100g/ml in the 'amount' field.
        
        gramWeight = item.servingSize; 
        // Simple heuristic conversion
        const multiplier = gramWeight / 100.0;
        calories = Math.round(calories * multiplier);
        protein = parseFloat((protein * multiplier).toFixed(1));
        carbs = parseFloat((carbs * multiplier).toFixed(1));
        fat = parseFloat((fat * multiplier).toFixed(1));
    } else if (item.inputFoods) {
         // Foundation - usually 100g
    }

    // Name Cleaning
    let cleanName = cleaner(desc);
    
    // Map Category
    let category = mapCategory(item.foodCategory?.description || item.fdcCategory || "");
    
    if (!category) {
        // Try to guess from name
        category = guessCategory(cleanName);
    }
    
    if (!category || category === "Skip") return null;
    
    // Subcategory (First word or specialized logic)
    const subcategory = getSubcategory(cleanName, category);
    
    // Normalized Key (for deduplication)
    // e.g. "cheese pizza"
    const key = cleanName.toLowerCase();
    
    return {
        key: key,
        name: cleanName,
        aliases: [desc], // Add original as alias
        category: category,
        subcategory: subcategory,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingUnit: servingUnit
    };
}

function cleaner(str) {
    if (!str) return "";
    // Remove "GTIN:", UPC codes, commas
    let s = str.replace(/GTIN:\s*\d+/g, "")
               .replace(/UPC:\s*\d+/g, "")
               .replace(/Includes.*$/g, "") // "Apple, raw, Includes skin" -> "Apple, raw"
               .split(',')[0] // Take primary name "Pizza, cheese" -> "Pizza"?? No, generic mapping is better.
               .trim();

    // Remove Brand names if possible (Heuristic: All Caps often implies generic in USDA foundation, but mixed in branded)
    // Convert to Title Case
    s = s.toLowerCase().replace(/(?:^|\s)\S/g, function(a) { return a.toUpperCase(); });
    
    // Remove content in parenthesis
    s = s.replace(/\(.*\)/g, "").trim();
    
    return s;
}

function mapCategory(usdaCat) {
    return CATEGORY_MAP[usdaCat] || null;
}

function guessCategory(name) {
    const n = name.toLowerCase();
    if (n.includes("pizza") || n.includes("burger") || n.includes("fries") || n.includes("sandwich")) return "Fast Food & Street Food";
    if (n.includes("chicken") || n.includes("beef") || n.includes("egg") || n.includes("fish")) return "Protein Sources";
    if (n.includes("apple") || n.includes("banana") || n.includes("berry") || n.includes("fruit")) return "Fruits";
    if (n.includes("spinach") || n.includes("carrot") || n.includes("broccoli") || n.includes("salad")) return "Vegetables";
    if (n.includes("milk") || n.includes("cheese") || n.includes("yogurt") || n.includes("butter")) return "Dairy & Fats";
    if (n.includes("bread") || n.includes("rice") || n.includes("pasta") || n.includes("oat")) return "Staple Foods";
    if (n.includes("cookie") || n.includes("chip") || n.includes("candy") || n.includes("chocolate")) return "Snacks & Sweets";
    if (n.includes("juice") || n.includes("soda") || n.includes("coffee") || n.includes("tea")) return "Beverages";
    return null;
}

function getSubcategory(name, category) {
    // Simple logic: First word, or hardcoded for common items
    const n = name.toLowerCase();
    if (n.includes("pizza")) return "Pizza";
    if (n.includes("burger")) return "Burger";
    if (n.includes("bread")) return "Bread";
    if (n.includes("pasta")) return "Pasta";
    if (n.includes("potato")) return "Potato";
    return "General";
}

function addToMap(item) {
    if (foodMap.has(item.key)) {
        mergeAliases(item);
    } else {
        foodMap.set(item.key, {
            name: item.name,
            aliases: item.aliases,
            category: item.category,
            subcategory: item.subcategory,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            servingUnit: item.servingUnit
        });
    }
}

function mergeAliases(item) {
    const existing = foodMap.get(item.key);
    for (const a of item.aliases) {
        if (!existing.aliases.includes(a)) {
            // Check similarity to avoid explosion of aliases
            if (existing.aliases.length < 5) {
                existing.aliases.push(a);
            }
        }
    }
}

// ============================================================================
// OUTPUT
// ============================================================================

function saveOutput() {
    console.log(`\n💾 Normalization Complete.`);
    console.log(`   Foundation Items: ${stats.foundation}`);
    console.log(`   Branded Items: ${stats.branded}`);
    console.log(`   Merged Duplicates: ${stats.merged}`);
    console.log(`   Total Unique Foods: ${foodMap.size}`);
    
    // Sort by name
    const sorted = Array.from(foodMap.values()).sort((a, b) => a.name.localeCompare(b.name));
    
    // Limit to MAX_ITEMS (Priority: Foundation items usually merged first, but we have mixed map)
    // We assume the map contains the most relevant ones because we processed Foundation first.
    const final = sorted.slice(0, MAX_ITEMS);
    
    try {
        const jsonStr = JSON.stringify(final, null, 2); // Pretty print (eats size, but user wants readable array)
        
        // Check size
        const sizeMB = Buffer.byteLength(jsonStr) / (1024 * 1024);
        console.log(`   Output Size: ${sizeMB.toFixed(2)} MB`);
        
        if (sizeMB > TARGET_SIZE_MB) {
            console.warn("⚠️  Output exceeds target size. Try Reducing aliases or limiting count further.");
        }
        
        fs.writeFileSync(OUTPUT_FILE, jsonStr);
        console.log(`✅ Saved to ${OUTPUT_FILE}`);
        
    } catch (e) {
        console.error("Error saving output:", e);
    }
}

if (require.main === module) {
    run().catch(console.error);
}
