"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.enrichMealItem = exports.recognizeMealImage = exports.getFoodDetailsUSDA = exports.searchFoodUSDA = void 0;
const axios_1 = require("axios");
const logger = require("firebase-functions/logger");
const params_1 = require("firebase-functions/params");
const generative_ai_1 = require("@google/generative-ai");
const https_1 = require("firebase-functions/v2/https");
const cors = require("cors");
const corsHandler = cors({ origin: true });
const GEMINI_API_KEY = (0, params_1.defineSecret)('GEMINI_API_KEY');
const USDA_API_KEY = (0, params_1.defineSecret)('USDA_API_KEY');
const REGION = 'us-central1';
const USDA_SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';
const USDA_DETAILS_URL = 'https://api.nal.usda.gov/fdc/v1/food';
const OPEN_FOOD_FACTS_SEARCH_URL = 'https://in.openfoodfacts.org/cgi/search.pl';
const NUTRITION_CACHE_TTL_MS = 1000 * 60 * 15;
const MEAL_CACHE_TTL_MS = 1000 * 60 * 10;
const GEMINI_RATE_LIMIT_WINDOW_MS = 3000;
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview';
const callableOptions = {
    region: REGION,
    invoker: 'public',
    secrets: [GEMINI_API_KEY, USDA_API_KEY],
};
const nutritionCache = new Map();
const mealCache = new Map();
const inFlightMealRequests = new Map();
let lastRequestTime = 0;
const QUERY_NORMALIZATION_MAP = {
    roti: 'whole wheat bread',
    chapati: 'whole wheat bread',
    paneer: 'cottage cheese',
    dal: 'lentils',
    sabzi: 'vegetable curry',
};
const GENERIC_FOOD_NAMES = new Set([
    'food',
    'meal',
    'item',
    'dish',
    'food item',
]);
const SNAPMEAL_QUERY_MAP = {
    banana: 'banana raw',
    apple: 'apple raw',
    rice: 'white rice cooked',
    chicken: 'chicken cooked',
    potato: 'potato boiled',
};
const USDA_REJECT_KEYWORDS = [
    'dehydrated',
    'dried',
    'powder',
    'chips',
    'fried',
    'oil',
    'butter',
    'sauce',
    'gravy',
    'dessert',
    'cake',
    'pie',
    'sweet',
    'juice',
    'concentrate',
    'syrup',
    'flavored',
];
const PRODUCE_TERMS = new Set([
    'apple', 'banana', 'orange', 'grape', 'mango', 'papaya', 'pineapple',
    'melon', 'watermelon', 'pear', 'peach', 'plum', 'berry', 'berries',
    'strawberry', 'blueberry', 'vegetable', 'carrot', 'potato', 'tomato',
    'onion', 'cucumber', 'spinach', 'broccoli', 'cabbage', 'cauliflower',
    'capsicum', 'pepper', 'okra', 'eggplant',
]);
const GRAIN_TERMS = new Set([
    'rice', 'pasta', 'noodle', 'oats', 'oatmeal', 'quinoa', 'barley',
    'couscous', 'bread',
]);
const MEAT_TERMS = new Set([
    'chicken', 'beef', 'mutton', 'lamb', 'pork', 'turkey', 'fish',
    'salmon', 'tuna', 'shrimp', 'prawn', 'egg',
]);
const GEMINI_MEAL_PROMPT = `Identify food items in this image.

Return JSON:
{
  "mealName": "string",
  "items": [
    {
      "name": "",
      "quantity": 1,
      "servingSize": "string",
      "estimatedGrams": 100
    }
  ]
}

Rules:
- No explanation
- No generic words`;
const GEMINI_RETRY_PROMPT = `${GEMINI_MEAL_PROMPT}

Previous response was invalid. Return only valid JSON with specific food names.`;
function toNumber(value) {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === 'string') {
        const parsed = Number.parseFloat(value);
        return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
}
function toNullableNumber(value) {
    if (value === null || value === undefined || value === '') {
        return null;
    }
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === 'string') {
        const parsed = Number.parseFloat(value);
        return Number.isFinite(parsed) ? parsed : null;
    }
    return null;
}
function safeString(value, fallback = '') {
    return typeof value === 'string' && value.trim().length > 0 ? value.trim() : fallback;
}
function isGenericFoodName(value) {
    return GENERIC_FOOD_NAMES.has(value.trim().toLowerCase());
}
function normalizeNutritionQuery(query) {
    let normalized = query.toLowerCase().trim();
    normalized = normalized.replace(/[^a-z0-9\s]/g, ' ');
    normalized = normalized.replace(/\s+/g, ' ').trim();
    for (const [source, replacement] of Object.entries(QUERY_NORMALIZATION_MAP)) {
        normalized = normalized.replace(new RegExp(`\\b${source}\\b`, 'g'), replacement);
    }
    return normalized.replace(/\s+/g, ' ').trim();
}
function containsAnyTerm(text, terms) {
    const sourceTerms = Array.isArray(terms) ? terms : Array.from(terms);
    return sourceTerms.some((term) => text.includes(term));
}
function getFoodContext(query) {
    const normalized = normalizeNutritionQuery(query);
    if (containsAnyTerm(normalized, PRODUCE_TERMS)) {
        return 'produce';
    }
    if (containsAnyTerm(normalized, GRAIN_TERMS)) {
        return 'grain';
    }
    if (containsAnyTerm(normalized, MEAT_TERMS)) {
        return 'meat';
    }
    return 'generic';
}
function enhanceSnapMealUSDAQuery(query) {
    const normalized = normalizeNutritionQuery(query);
    if (SNAPMEAL_QUERY_MAP[normalized]) {
        return SNAPMEAL_QUERY_MAP[normalized];
    }
    const context = getFoodContext(normalized);
    if (context === 'produce' && !containsAnyTerm(normalized, ['raw', 'fresh'])) {
        return `${normalized} raw`;
    }
    if (context === 'grain' && !containsAnyTerm(normalized, ['cooked', 'boiled'])) {
        return `${normalized} cooked`;
    }
    if (context === 'meat' && !containsAnyTerm(normalized, ['cooked', 'grilled', 'boiled'])) {
        return `${normalized} cooked`;
    }
    return normalized;
}
function hasRejectedKeyword(description) {
    return USDA_REJECT_KEYWORDS.some((keyword) => description.includes(keyword));
}
function scoreUSDACandidate(query, food) {
    const description = safeString(food === null || food === void 0 ? void 0 : food.description).toLowerCase();
    const originalQuery = normalizeNutritionQuery(query);
    const context = getFoodContext(originalQuery);
    let score = 0;
    if (description.includes(originalQuery)) {
        score += 5;
    }
    for (const token of originalQuery.split(' ')) {
        if (token.length >= 3 && description.includes(token)) {
            score += 2;
        }
    }
    if (context === 'produce') {
        if (description.includes('raw'))
            score += 4;
        if (description.includes('fresh'))
            score += 3;
    }
    if (context === 'grain') {
        if (description.includes('cooked'))
            score += 3;
        if (description.includes('boiled'))
            score += 2;
    }
    if (context === 'meat') {
        if (description.includes('cooked'))
            score += 3;
        if (description.includes('boiled'))
            score += 2;
        if (description.includes('grilled'))
            score += 2;
    }
    if (hasRejectedKeyword(description)) {
        score -= 10;
    }
    return score;
}
function isInvalidNutritionQuery(query) {
    if (!query) {
        return true;
    }
    return isGenericFoodName(query);
}
function getCachedNutrition(query) {
    const cached = nutritionCache.get(query);
    if (!cached) {
        return null;
    }
    if (Date.now() > cached.expiresAt) {
        nutritionCache.delete(query);
        return null;
    }
    return cached.value;
}
function setCachedNutrition(query, value) {
    nutritionCache.set(query, {
        expiresAt: Date.now() + NUTRITION_CACHE_TTL_MS,
        value,
    });
}
function getCachedMeal(hash) {
    const cached = mealCache.get(hash);
    if (!cached) {
        return null;
    }
    if (Date.now() > cached.expiresAt) {
        mealCache.delete(hash);
        return null;
    }
    return cached.value;
}
function setCachedMeal(hash, value) {
    mealCache.set(hash, {
        expiresAt: Date.now() + MEAL_CACHE_TTL_MS,
        value,
    });
}
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
function isGeminiRateLimitError(error) {
    var _a;
    if (typeof error === 'object' && error !== null) {
        const status = (_a = error.status) !== null && _a !== void 0 ? _a : error.code;
        if (status === 429 || status === '429') {
            return true;
        }
    }
    const message = error instanceof Error ? error.message : String(error !== null && error !== void 0 ? error : '');
    return message.includes('429') || message.toLowerCase().includes('too many requests');
}
async function callGeminiWithRetry(model, input, retries = 3) {
    for (let attempt = 0; attempt <= retries; attempt += 1) {
        try {
            return await model.generateContent(input);
        }
        catch (error) {
            const isRetryable = isGeminiRateLimitError(error);
            if (!isRetryable || attempt === retries) {
                throw error;
            }
            const delay = 1000 * (2 ** attempt);
            logger.warn('Gemini 429 error, retrying...', {
                attempt: attempt + 1,
                delay,
            });
            await sleep(delay);
        }
    }
    throw new Error('Gemini retry flow exited unexpectedly.');
}
function buildUnavailableNutrition(query, reason) {
    return {
        name: query,
        nutritionPer100g: {},
        servingOptions: [],
        source: 'unavailable',
        error: reason,
    };
}
function normalizeUSDAResponse(food) {
    var _a, _b, _c, _d, _e, _f;
    const nutrients = food.foodNutrients || food.nutrients || [];
    const findNutrient = (matcher) => {
        const normalizedMatcher = matcher.toString().toLowerCase();
        return nutrients.find((nutrient) => {
            var _a, _b, _c, _d;
            return nutrient.nutrientId === matcher ||
                nutrient.nutrientNumber === matcher ||
                (typeof matcher === 'number' &&
                    (((_a = nutrient.nutrient) === null || _a === void 0 ? void 0 : _a.id) === matcher ||
                        Number.parseInt(String((_c = (_b = nutrient.nutrient) === null || _b === void 0 ? void 0 : _b.number) !== null && _c !== void 0 ? _c : ''), 10) === matcher)) ||
                (typeof matcher === 'string' &&
                    ((safeString(nutrient.name).toLowerCase().includes(normalizedMatcher)) ||
                        (safeString((_d = nutrient.nutrient) === null || _d === void 0 ? void 0 : _d.name).toLowerCase().includes(normalizedMatcher))));
        });
    };
    const getNutrientValue = (ids, aliases = []) => {
        var _a, _b;
        for (const id of ids) {
            const nutrient = findNutrient(id);
            const amount = toNullableNumber((_a = nutrient === null || nutrient === void 0 ? void 0 : nutrient.amount) !== null && _a !== void 0 ? _a : nutrient === null || nutrient === void 0 ? void 0 : nutrient.value);
            if (amount !== null) {
                return amount;
            }
        }
        for (const alias of aliases) {
            const nutrient = findNutrient(alias);
            const amount = toNullableNumber((_b = nutrient === null || nutrient === void 0 ? void 0 : nutrient.amount) !== null && _b !== void 0 ? _b : nutrient === null || nutrient === void 0 ? void 0 : nutrient.value);
            if (amount !== null) {
                return amount;
            }
        }
        return null;
    };
    const servingOptions = [{ label: '100g', grams: 100 }];
    if (Array.isArray(food.foodPortions)) {
        for (const portion of food.foodPortions) {
            const grams = toNumber(portion === null || portion === void 0 ? void 0 : portion.gramWeight);
            if (grams <= 0)
                continue;
            const label = safeString((_b = (_a = portion === null || portion === void 0 ? void 0 : portion.modifier) !== null && _a !== void 0 ? _a : portion === null || portion === void 0 ? void 0 : portion.portionDescription) !== null && _b !== void 0 ? _b : `${(_c = portion === null || portion === void 0 ? void 0 : portion.amount) !== null && _c !== void 0 ? _c : ''} ${(_e = (_d = portion === null || portion === void 0 ? void 0 : portion.measureUnit) === null || _d === void 0 ? void 0 : _d.name) !== null && _e !== void 0 ? _e : 'serving'}`, 'Custom serving');
            servingOptions.push({ label, grams });
        }
    }
    const uniqueServingOptions = servingOptions.filter((option, index, options) => options.findIndex((candidate) => candidate.label.toLowerCase() === option.label.toLowerCase() &&
        Math.abs(candidate.grams - option.grams) < 0.01) === index);
    const nutritionPer100g = {};
    const setNutrient = (key, value) => {
        if (value !== null) {
            nutritionPer100g[key] = value;
        }
    };
    setNutrient('calories', getNutrientValue([1008, 208], ['energy', 'kcal']));
    setNutrient('protein', getNutrientValue([1003], ['protein']));
    setNutrient('carbs', getNutrientValue([1005], ['carbohydrate', 'carbohydrate, by difference']));
    setNutrient('fat', getNutrientValue([1004], ['total lipid', 'fat']));
    setNutrient('saturatedFat', getNutrientValue([1258], ['fatty acids, total saturated', 'saturated']));
    setNutrient('polyunsaturatedFat', getNutrientValue([1292], ['fatty acids, total polyunsaturated', 'polyunsaturated']));
    setNutrient('monounsaturatedFat', getNutrientValue([1293], ['fatty acids, total monounsaturated', 'monounsaturated']));
    setNutrient('cholesterol', getNutrientValue([1253], ['cholesterol']));
    setNutrient('sodium', getNutrientValue([1093], ['sodium']));
    setNutrient('fiber', getNutrientValue([1079], ['fiber', 'dietary fiber']));
    setNutrient('sugar', getNutrientValue([2000, 1063], ['sugars', 'sugar']));
    setNutrient('potassium', getNutrientValue([1092], ['potassium']));
    setNutrient('vitaminA', getNutrientValue([1106], ['vitamin a']));
    setNutrient('vitaminC', getNutrientValue([1162], ['vitamin c', 'ascorbic acid']));
    setNutrient('calcium', getNutrientValue([1087], ['calcium']));
    setNutrient('iron', getNutrientValue([1089], ['iron']));
    return {
        name: safeString((_f = food.description) !== null && _f !== void 0 ? _f : food.lowercaseDescription, 'Unknown Food'),
        nutritionPer100g,
        servingOptions: uniqueServingOptions,
        source: 'usda',
        fdcId: food.fdcId ? String(food.fdcId) : undefined,
    };
}
function normalizeOFFResponse(product, query) {
    var _a, _b;
    const nutriments = product.nutriments || {};
    const servingQuantity = toNumber(product.serving_quantity);
    const calories = toNullableNumber((_a = nutriments['energy-kcal_100g']) !== null && _a !== void 0 ? _a : nutriments.energy_kcal_100g);
    const protein = toNullableNumber(nutriments.proteins_100g);
    const carbs = toNullableNumber(nutriments.carbohydrates_100g);
    const fat = toNullableNumber(nutriments.fat_100g);
    const nutritionPer100g = {};
    if (calories !== null)
        nutritionPer100g.calories = calories;
    if (protein !== null)
        nutritionPer100g.protein = protein;
    if (carbs !== null)
        nutritionPer100g.carbs = carbs;
    if (fat !== null)
        nutritionPer100g.fat = fat;
    return {
        name: safeString((_b = product.product_name) !== null && _b !== void 0 ? _b : product.product_name_en, query),
        nutritionPer100g,
        servingOptions: [
            { label: '100g', grams: 100 },
            ...(servingQuantity > 0
                ? [{ label: safeString(product.serving_size, '1 serving'), grams: servingQuantity }]
                : []),
        ],
        source: 'off',
    };
}
async function fetchFoodFromUSDA(query) {
    var _a;
    const normalizedQuery = normalizeNutritionQuery(query);
    if (isInvalidNutritionQuery(normalizedQuery)) {
        logger.warn('Skipping invalid USDA query', { query, normalizedQuery });
        return null;
    }
    const cached = getCachedNutrition(`usda:${normalizedQuery}`);
    if (cached) {
        return cached;
    }
    const apiKey = USDA_API_KEY.value();
    if (!apiKey) {
        logger.error('USDA_API_KEY is missing');
        return null;
    }
    try {
        const enhancedQuery = enhanceSnapMealUSDAQuery(query);
        const normalizedEnhancedQuery = normalizeNutritionQuery(enhancedQuery);
        const foodContext = getFoodContext(query);
        logger.info('Searching USDA', { query, normalizedQuery, enhancedQuery: normalizedEnhancedQuery });
        const searchResponse = await axios_1.default.post(`${USDA_SEARCH_URL}?api_key=${apiKey}`, {
            query: normalizedEnhancedQuery,
            pageSize: 10,
            dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
        }, { timeout: 10000 });
        const foods = searchResponse.data.foods;
        if (!Array.isArray(foods) || foods.length === 0) {
            logger.warn('USDA returned no matches', { normalizedQuery, normalizedEnhancedQuery });
            return null;
        }
        const filteredFoods = foods.filter((food) => {
            const description = safeString(food === null || food === void 0 ? void 0 : food.description).toLowerCase();
            return !hasRejectedKeyword(description);
        });
        const candidateFoods = (filteredFoods.length > 0 ? filteredFoods : foods)
            .map((food) => ({
            food,
            score: scoreUSDACandidate(query, food),
        }))
            .sort((left, right) => right.score - left.score);
        let lowestCalorieMatch = null;
        for (const candidate of candidateFoods) {
            const fdcId = (_a = candidate.food) === null || _a === void 0 ? void 0 : _a.fdcId;
            if (!fdcId) {
                continue;
            }
            const detailsResponse = await axios_1.default.get(`${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`, { timeout: 10000 });
            const normalized = normalizeUSDAResponse(detailsResponse.data);
            const calories = normalized.nutritionPer100g.calories;
            if (typeof calories === 'number') {
                if (!lowestCalorieMatch || calories < lowestCalorieMatch.calories) {
                    lowestCalorieMatch = { food: candidate.food, normalized, calories };
                }
            }
            if (foodContext === 'produce' && typeof calories === 'number' && calories > 300) {
                continue;
            }
            logger.info('SMART USDA MATCH', {
                originalQuery: query,
                enhancedQuery: normalizedEnhancedQuery,
                selectedFood: candidate.food.description,
                calories,
            });
            setCachedNutrition(`usda:${normalizedQuery}`, normalized);
            return normalized;
        }
        if (lowestCalorieMatch) {
            logger.info('SMART USDA MATCH', {
                originalQuery: query,
                enhancedQuery: normalizedEnhancedQuery,
                selectedFood: lowestCalorieMatch.food.description,
                calories: lowestCalorieMatch.calories,
            });
            setCachedNutrition(`usda:${normalizedQuery}`, lowestCalorieMatch.normalized);
            return lowestCalorieMatch.normalized;
        }
        logger.warn('USDA smart matching found no safe match', {
            query,
            normalizedQuery,
            normalizedEnhancedQuery,
        });
        return null;
    }
    catch (error) {
        logger.error('fetchFoodFromUSDA error', { query, normalizedQuery, error });
        return null;
    }
}
async function fetchFoodFromOFF(query) {
    const normalizedQuery = normalizeNutritionQuery(query);
    if (isInvalidNutritionQuery(normalizedQuery)) {
        logger.warn('Skipping invalid OFF query', { query, normalizedQuery });
        return null;
    }
    const cached = getCachedNutrition(`off:${normalizedQuery}`);
    if (cached) {
        return cached;
    }
    try {
        const response = await axios_1.default.get(OPEN_FOOD_FACTS_SEARCH_URL, {
            params: {
                search_terms: normalizedQuery,
                search_simple: 1,
                action: 'process',
                json: 1,
                page_size: 5,
            },
            headers: { 'User-Agent': 'Physiq/1.0 (support@physiq.app)' },
            timeout: 10000,
        });
        const products = Array.isArray(response.data.products) ? response.data.products : [];
        const product = products.find((candidate) => {
            var _a;
            const nutriments = (candidate === null || candidate === void 0 ? void 0 : candidate.nutriments) || {};
            return toNullableNumber((_a = nutriments['energy-kcal_100g']) !== null && _a !== void 0 ? _a : nutriments.energy_kcal_100g) !== null;
        });
        if (!product) {
            logger.warn('OpenFoodFacts returned no nutritionally usable matches', { normalizedQuery });
            return null;
        }
        const normalized = normalizeOFFResponse(product, query);
        setCachedNutrition(`off:${normalizedQuery}`, normalized);
        return normalized;
    }
    catch (error) {
        logger.error('fetchFoodFromOFF error', { query, normalizedQuery, error });
        return null;
    }
}
function buildErrorMealResponse(error, mealTitle = 'Unable to detect meal') {
    return {
        meal_title: mealTitle,
        serving_container: 'plate',
        items: [],
        error,
    };
}
function validateAndNormalizeMealResponse(parsed) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    if (!parsed || typeof parsed !== 'object') {
        return null;
    }
    const data = parsed;
    const itemsRaw = Array.isArray(data.items)
        ? data.items
        : Array.isArray(data.ingredients)
            ? data.ingredients
            : [];
    if (itemsRaw.length === 0) {
        return null;
    }
    const items = [];
    for (const rawItem of itemsRaw) {
        if (!rawItem || typeof rawItem !== 'object') {
            continue;
        }
        const item = rawItem;
        const ingredient = safeString((_a = item.name) !== null && _a !== void 0 ? _a : item.ingredient, '');
        if (!ingredient || isGenericFoodName(ingredient)) {
            continue;
        }
        const quantity = toNullableNumber(item.quantity);
        const servingSize = safeString((_b = item.servingSize) !== null && _b !== void 0 ? _b : item.serving_size, 'serving');
        const estimatedAmount = safeString((_c = item.estimated_amount) !== null && _c !== void 0 ? _c : item.amount)
            || (quantity !== null
                ? `${quantity} ${servingSize}`
                : servingSize || '1 serving');
        items.push({
            ingredient,
            estimated_amount: estimatedAmount,
            serving_size: servingSize || 'serving',
            estimated_grams: toNullableNumber((_d = item.estimated_grams) !== null && _d !== void 0 ? _d : item.estimatedGrams),
            calories_estimate: toNullableNumber((_e = item.calories) !== null && _e !== void 0 ? _e : item.calories_estimate),
            protein_estimate: toNullableNumber((_f = item.protein) !== null && _f !== void 0 ? _f : item.protein_estimate),
            carbs_estimate: toNullableNumber((_g = item.carbs) !== null && _g !== void 0 ? _g : item.carbs_estimate),
            fat_estimate: toNullableNumber((_h = item.fat) !== null && _h !== void 0 ? _h : item.fat_estimate),
        });
    }
    if (items.length === 0) {
        return null;
    }
    const detectedTitle = safeString((_j = data.mealName) !== null && _j !== void 0 ? _j : data.meal_title, '');
    return {
        mealTitle: detectedTitle && !isGenericFoodName(detectedTitle)
            ? detectedTitle
            : items.map((item) => item.ingredient).slice(0, 3).join(', '),
        servingContainer: safeString((_k = data.serving_container) !== null && _k !== void 0 ? _k : data.servingContainer, 'plate').toLowerCase(),
        items,
    };
}
function toClientMealResponse(validated, error) {
    return Object.assign({ meal_title: validated.mealTitle, serving_container: validated.servingContainer, items: validated.items }, (error ? { error } : {}));
}
function extractJsonPayload(responseText) {
    let cleanedText = responseText.trim()
        .replace(/```json/gi, '')
        .replace(/```/g, '')
        .trim();
    const firstBrace = cleanedText.indexOf('{');
    const lastBrace = cleanedText.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1) {
        cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
    }
    return cleanedText;
}
exports.searchFoodUSDA = (0, https_1.onRequest)({ region: REGION, secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a, _b;
        const query = safeString((_b = (_a = req.body) === null || _a === void 0 ? void 0 : _a.query) !== null && _b !== void 0 ? _b : req.query.query, '');
        const normalizedQuery = normalizeNutritionQuery(query);
        if (isInvalidNutritionQuery(normalizedQuery)) {
            res.send([]);
            return;
        }
        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios_1.default.post(`${USDA_SEARCH_URL}?api_key=${apiKey}`, {
                query: normalizedQuery,
                pageSize: 20,
                dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
            }, { timeout: 10000 });
            res.send(response.data.foods || []);
        }
        catch (error) {
            logger.error('searchFoodUSDA error', { error, query, normalizedQuery });
            res.status(500).send({ error: 'Search failed.' });
        }
    });
});
exports.getFoodDetailsUSDA = (0, https_1.onRequest)({ region: REGION, secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a;
        const fdcId = ((_a = req.body) === null || _a === void 0 ? void 0 : _a.fdcId) || req.query.fdcId;
        if (!fdcId) {
            res.status(400).send({ error: 'FDC ID is required.' });
            return;
        }
        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios_1.default.get(`${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`, { timeout: 10000 });
            logger.info('USDA DETAILS RESPONSE', { data: response.data });
            res.send(normalizeUSDAResponse(response.data));
        }
        catch (error) {
            logger.error('getFoodDetailsUSDA error', { error, fdcId });
            res.status(500).send({ error: 'Details failed.' });
        }
    });
});
exports.recognizeMealImage = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a, _b;
    const imageB64 = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.imageB64) === null || _b === void 0 ? void 0 : _b.trim();
    if (!imageB64) {
        throw new https_1.HttpsError('invalid-argument', 'imageB64 is required.');
    }
    if (imageB64.length > 10000000) {
        throw new https_1.HttpsError('invalid-argument', 'imageB64 exceeds the 10 MB limit.');
    }
    const hash = imageB64.substring(0, 100);
    const requestId = hash.substring(0, 16);
    const cachedMeal = getCachedMeal(hash);
    if (cachedMeal) {
        logger.info('recognizeMealImage cache hit', { requestId });
        return cachedMeal;
    }
    const inFlightRequest = inFlightMealRequests.get(hash);
    if (inFlightRequest) {
        logger.info('recognizeMealImage joined in-flight request', { requestId });
        return inFlightRequest;
    }
    const now = Date.now();
    if (now - lastRequestTime < GEMINI_RATE_LIMIT_WINDOW_MS) {
        throw new https_1.HttpsError('resource-exhausted', 'Too many requests. Please wait.');
    }
    lastRequestTime = now;
    const geminiKey = GEMINI_API_KEY.value();
    if (!geminiKey) {
        logger.error('Gemini API key is not configured');
        return buildErrorMealResponse('Gemini API key is not configured.');
    }
    const requestPromise = (async () => {
        const genAI = new generative_ai_1.GoogleGenerativeAI(geminiKey);
        const model = genAI.getGenerativeModel({
            model: GEMINI_MODEL,
            generationConfig: {
                responseMimeType: 'application/json',
                temperature: 0.1,
            },
        });
        for (const [attemptIndex, prompt] of [GEMINI_MEAL_PROMPT, GEMINI_RETRY_PROMPT].entries()) {
            const attempt = attemptIndex + 1;
            const result = await callGeminiWithRetry(model, [
                prompt,
                {
                    inlineData: {
                        mimeType: 'image/jpeg',
                        data: imageB64,
                    },
                },
            ]);
            const responseText = result.response.text();
            logger.info('GEMINI RAW RESPONSE', { attempt, requestId, model: GEMINI_MODEL, responseText });
            const cleanedText = extractJsonPayload(responseText);
            logger.info('GEMINI CLEANED TEXT', { attempt, requestId, cleanedText });
            try {
                const parsed = JSON.parse(cleanedText);
                logger.info('GEMINI PARSED JSON', { attempt, requestId, parsed });
                const validated = validateAndNormalizeMealResponse(parsed);
                if (validated && validated.items.length > 0) {
                    const response = toClientMealResponse(validated);
                    setCachedMeal(hash, response);
                    return response;
                }
            }
            catch (parseError) {
                logger.error('Failed to parse Gemini JSON response', {
                    attempt,
                    requestId,
                    parseError,
                    cleanedText: cleanedText.substring(0, 1000),
                });
            }
        }
        return buildErrorMealResponse('Gemini did not return any specific food names.');
    })().catch((error) => {
        logger.error('GEMINI ERROR FULL', {
            requestId,
            model: GEMINI_MODEL,
            message: error instanceof Error ? error.message : error,
            stack: error instanceof Error ? error.stack : null,
        });
        if (isGeminiRateLimitError(error)) {
            return buildErrorMealResponse('Gemini rate limit reached. Please retry shortly.');
        }
        return buildErrorMealResponse('Gemini request failed.');
    }).finally(() => {
        inFlightMealRequests.delete(hash);
    });
    inFlightMealRequests.set(hash, requestPromise);
    return requestPromise;
});
exports.enrichMealItem = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a;
    const query = (_a = request.data) === null || _a === void 0 ? void 0 : _a.ingredient;
    if (!query || typeof query !== 'string') {
        logger.warn('Invalid query: empty or non-string', { query });
        return null;
    }
    const trimmedQuery = query.trim();
    const normalizedQuery = trimmedQuery.toLowerCase();
    const INVALID_TERMS = ['food', 'meal', 'item', 'dish', 'food item'];
    if (INVALID_TERMS.includes(normalizedQuery)) {
        logger.warn('Rejected generic food query', { query: trimmedQuery });
        return null;
    }
    const FOOD_MAP = {
        roti: 'whole wheat bread',
        chapati: 'whole wheat bread',
        paneer: 'cottage cheese',
        dal: 'lentils',
        sabzi: 'vegetable curry',
    };
    const finalQuery = FOOD_MAP[normalizedQuery] || trimmedQuery;
    logger.info('enrichMealItem request', {
        query: trimmedQuery,
        normalizedQuery,
        finalQuery,
    });
    let nutritionData = await fetchFoodFromUSDA(finalQuery);
    if (!nutritionData) {
        logger.info('USDA failed, trying OpenFoodFacts', {
            query: trimmedQuery,
            normalizedQuery,
            finalQuery,
        });
        nutritionData = await fetchFoodFromOFF(finalQuery);
    }
    if (nutritionData) {
        logger.info('enrichMealItem success', {
            query: trimmedQuery,
            normalizedQuery,
            finalQuery,
            source: nutritionData.source,
        });
        return nutritionData;
    }
    logger.warn('No enrichment found', {
        query: trimmedQuery,
        normalizedQuery,
        finalQuery,
    });
    const unavailable = buildUnavailableNutrition(trimmedQuery, 'Nutrition unavailable from USDA and OpenFoodFacts.');
    return unavailable;
});
//# sourceMappingURL=nutrition.js.map