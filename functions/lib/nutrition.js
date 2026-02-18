"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.recognizeMealImage = exports.searchBarcode = exports.getFoodDetails = exports.searchFood = void 0;
const admin = __importStar(require("firebase-admin"));
const axios_1 = __importDefault(require("axios"));
const logger = __importStar(require("firebase-functions/logger"));
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const FATSECRET_CLIENT_ID = (0, params_1.defineSecret)('FATSECRET_CLIENT_ID');
const FATSECRET_CLIENT_SECRET = (0, params_1.defineSecret)('FATSECRET_CLIENT_SECRET');
const REGION = 'us-central1';
const FATSECRET_TOKEN_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_SEARCH_V4_URL = 'https://platform.fatsecret.com/rest/foods/search/v4';
const FATSECRET_FOOD_V5_URL = 'https://platform.fatsecret.com/rest/food/v5';
const FATSECRET_BARCODE_V2_URL = 'https://platform.fatsecret.com/rest/food/barcode/find-by-id/v2';
const FATSECRET_IMAGE_RECOGNITION_V2_URL = 'https://platform.fatsecret.com/rest/image-recognition/v2';
const FATSECRET_SCOPE_PREMIER = 'premier';
const FATSECRET_SCOPE_BARCODE = 'barcode';
const FATSECRET_SCOPE_IMAGE_RECOGNITION = 'image-recognition';
const FOOD_CACHE_COLLECTION = 'foods_cache';
const FOOD_CACHE_TTL_MS = 1000 * 60 * 60 * 24 * 30; // 30 days
const TOKEN_REFRESH_BUFFER_MS = 60 * 1000; // refresh 1 minute early
class FatSecretApiError extends Error {
    constructor(apiCode, message) {
        super(message);
        this.name = 'FatSecretApiError';
        this.apiCode = apiCode;
    }
}
const cachedTokens = new Map();
const callableOptions = {
    region: REGION,
    invoker: 'public',
    secrets: [FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET],
};
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
function normalizeArray(value) {
    if (value == null) {
        return [];
    }
    return Array.isArray(value) ? value : [value];
}
function toBoolean(value, fallback = false) {
    if (typeof value === 'boolean')
        return value;
    if (typeof value === 'number')
        return value === 1;
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === 'true' || normalized === '1')
            return true;
        if (normalized === 'false' || normalized === '0')
            return false;
    }
    return fallback;
}
function sanitizeRegion(value) {
    if (typeof value !== 'string')
        return 'US';
    const trimmed = value.trim().toUpperCase();
    return trimmed.length >= 2 ? trimmed : 'US';
}
function sanitizeLanguage(value) {
    if (typeof value !== 'string')
        return null;
    const trimmed = value.trim().toLowerCase();
    return trimmed.length >= 2 ? trimmed : null;
}
function escapeRegExp(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
function parseMacro(description, label) {
    const pattern = new RegExp(`${escapeRegExp(label)}:\\s*([\\d.]+)`, 'i');
    const match = pattern.exec(description);
    return match ? toNumber(match[1]) : 0;
}
function parseServingSummary(description) {
    const match = /^Per\s+(.+?)\s*-/i.exec(description);
    if (!match || !match[1]) {
        return 'serving';
    }
    return match[1].trim();
}
function getAxiosErrorDetails(error) {
    var _a, _b;
    if (axios_1.default.isAxiosError(error)) {
        return {
            message: error.message,
            status: (_a = error.response) === null || _a === void 0 ? void 0 : _a.status,
            data: (_b = error.response) === null || _b === void 0 ? void 0 : _b.data,
        };
    }
    if (error instanceof Error) {
        return { message: error.message };
    }
    return { error };
}
function logAuthContext(functionName, request) {
    var _a, _b;
    logger.info(`${functionName} auth`, {
        authenticated: !!request.auth,
        uid: (_b = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid) !== null && _b !== void 0 ? _b : null,
    });
}
function parseFatSecretErrorNode(errorNode) {
    if (!errorNode || typeof errorNode !== 'object') {
        return null;
    }
    const node = errorNode;
    const codeRaw = node.code;
    const parsedCode = toNumber(codeRaw);
    const code = parsedCode > 0 ? Math.trunc(parsedCode) : null;
    let message = 'FatSecret API request failed.';
    const messageValue = node.message;
    if (typeof messageValue === 'string' && messageValue.trim().length > 0) {
        message = messageValue.trim();
    }
    else if (messageValue && typeof messageValue === 'object') {
        const nested = messageValue;
        if (typeof nested.value === 'string' && nested.value.trim().length > 0) {
            message = nested.value.trim();
        }
    }
    return new FatSecretApiError(code, message);
}
function parseFatSecretErrorFromPayload(payload) {
    if (!payload || typeof payload !== 'object') {
        return null;
    }
    const data = payload;
    return parseFatSecretErrorNode(data.error);
}
function parseFatSecretErrorFromAxios(error) {
    var _a;
    if (!axios_1.default.isAxiosError(error))
        return null;
    return parseFatSecretErrorFromPayload((_a = error.response) === null || _a === void 0 ? void 0 : _a.data);
}
function extractServingsNode(food) {
    const servingsNode = food.servings;
    if (servingsNode && typeof servingsNode === 'object' && !Array.isArray(servingsNode)) {
        const nested = servingsNode.serving;
        return normalizeArray(nested);
    }
    return normalizeArray(servingsNode);
}
function pickDefaultServing(food) {
    const servings = extractServingsNode(food);
    if (servings.length === 0)
        return null;
    const defaultServing = servings.find((serving) => toBoolean(serving.is_default));
    return defaultServing !== null && defaultServing !== void 0 ? defaultServing : servings[0];
}
function mapSearchFood(rawFood) {
    var _a;
    const description = typeof rawFood.food_description === 'string' ? rawFood.food_description : '';
    const defaultServing = pickDefaultServing(rawFood);
    const servingSummary = typeof rawFood.serving_summary === 'string'
        ? rawFood.serving_summary.trim()
        : '';
    const servingDescription = typeof (defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.serving_description) === 'string'
        ? defaultServing.serving_description
        : '';
    const carbsFromServing = toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.carbohydrate) > 0
        ? toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.carbohydrate)
        : toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.carbs);
    return {
        id: String((_a = rawFood.food_id) !== null && _a !== void 0 ? _a : ''),
        name: typeof rawFood.food_name === 'string' ? rawFood.food_name : 'Unknown',
        brand: typeof rawFood.brand_name === 'string' ? rawFood.brand_name : '',
        type: typeof rawFood.food_type === 'string' ? rawFood.food_type : 'Generic',
        description,
        serving_summary: servingSummary.length > 0
            ? servingSummary
            : (servingDescription.length > 0 ? servingDescription : parseServingSummary(description)),
        calories: toNumber(rawFood.calories) > 0
            ? toNumber(rawFood.calories)
            : (toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.calories) > 0
                ? toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.calories)
                : parseMacro(description, 'Calories')),
        protein: toNumber(rawFood.protein) > 0
            ? toNumber(rawFood.protein)
            : (toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.protein) > 0
                ? toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.protein)
                : parseMacro(description, 'Protein')),
        carbs: toNumber(rawFood.carbs) > 0
            ? toNumber(rawFood.carbs)
            : (carbsFromServing > 0
                ? carbsFromServing
                : parseMacro(description, 'Carbs')),
        fat: toNumber(rawFood.fat) > 0
            ? toNumber(rawFood.fat)
            : (toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.fat) > 0
                ? toNumber(defaultServing === null || defaultServing === void 0 ? void 0 : defaultServing.fat)
                : parseMacro(description, 'Fat')),
    };
}
function mapServing(rawServing) {
    var _a;
    const carbs = toNumber(rawServing.carbohydrate) > 0
        ? toNumber(rawServing.carbohydrate)
        : toNumber(rawServing.carbs);
    return {
        serving_id: String((_a = rawServing.serving_id) !== null && _a !== void 0 ? _a : ''),
        serving_description: typeof rawServing.serving_description === 'string'
            ? rawServing.serving_description
            : 'Serving',
        metric_serving_amount: toNumber(rawServing.metric_serving_amount),
        metric_serving_unit: typeof rawServing.metric_serving_unit === 'string'
            ? rawServing.metric_serving_unit
            : 'g',
        number_of_units: toNumber(rawServing.number_of_units),
        calories: toNumber(rawServing.calories),
        protein: toNumber(rawServing.protein),
        carbohydrate: carbs,
        carbs,
        fat: toNumber(rawServing.fat),
        fiber: toNumber(rawServing.fiber),
        sugar: toNumber(rawServing.sugar),
        saturated_fat: toNumber(rawServing.saturated_fat),
        polyunsaturated_fat: toNumber(rawServing.polyunsaturated_fat),
        monounsaturated_fat: toNumber(rawServing.monounsaturated_fat),
        cholesterol: toNumber(rawServing.cholesterol),
        sodium: toNumber(rawServing.sodium),
        potassium: toNumber(rawServing.potassium),
        vitamin_a: toNumber(rawServing.vitamin_a),
        vitamin_c: toNumber(rawServing.vitamin_c),
        calcium: toNumber(rawServing.calcium),
        iron: toNumber(rawServing.iron),
        trans_fat: toNumber(rawServing.trans_fat),
        added_sugars: toNumber(rawServing.added_sugars),
        vitamin_d: toNumber(rawServing.vitamin_d),
        is_default: toBoolean(rawServing.is_default),
    };
}
function isFreshCache(cachedAt) {
    if (!(cachedAt instanceof admin.firestore.Timestamp)) {
        return false;
    }
    return Date.now() - cachedAt.toMillis() < FOOD_CACHE_TTL_MS;
}
function isValidCachedFood(details) {
    if (!details || typeof details !== 'object') {
        return false;
    }
    const candidate = details;
    return typeof candidate.id === 'string' &&
        typeof candidate.name === 'string' &&
        Array.isArray(candidate.servings) &&
        candidate.servings.length > 0;
}
function toHttpsError(functionName, error) {
    if (error instanceof https_1.HttpsError) {
        return error;
    }
    if (error instanceof FatSecretApiError) {
        const code = error.apiCode === 211 ? 'not-found' : 'internal';
        return new https_1.HttpsError(code, error.message);
    }
    if (error instanceof Error) {
        return new https_1.HttpsError('internal', `${functionName} failed: ${error.message}`);
    }
    return new https_1.HttpsError('internal', `${functionName} failed.`);
}
async function getAccessToken(scope) {
    var _a, _b;
    const now = Date.now();
    const cachedToken = cachedTokens.get(scope);
    if (cachedToken && now < (cachedToken.expiresAtMs - TOKEN_REFRESH_BUFFER_MS)) {
        return cachedToken.token;
    }
    const clientId = FATSECRET_CLIENT_ID.value();
    const clientSecret = FATSECRET_CLIENT_SECRET.value();
    if (!clientId || !clientSecret) {
        logger.error('FatSecret secrets are missing', {
            hasClientId: !!clientId,
            hasClientSecret: !!clientSecret,
        });
        throw new https_1.HttpsError('failed-precondition', 'FatSecret secrets are not configured.');
    }
    const body = new URLSearchParams();
    body.set('grant_type', 'client_credentials');
    body.set('scope', scope);
    body.set('client_id', clientId);
    body.set('client_secret', clientSecret);
    try {
        const response = await axios_1.default.post(FATSECRET_TOKEN_URL, body.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            timeout: 15000,
        });
        const accessToken = (_a = response.data) === null || _a === void 0 ? void 0 : _a.access_token;
        const expiresInSeconds = toNumber((_b = response.data) === null || _b === void 0 ? void 0 : _b.expires_in) || 3600;
        if (!accessToken) {
            logger.error('FatSecret token response missing token', { response: response.data });
            throw new https_1.HttpsError('internal', 'FatSecret token response missing access token.');
        }
        const token = {
            token: accessToken,
            expiresAtMs: Date.now() + (expiresInSeconds * 1000),
            scope,
        };
        cachedTokens.set(scope, token);
        logger.info('FatSecret token refreshed', { expiresInSeconds, scope });
        return accessToken;
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error('FatSecret token request failed', getAxiosErrorDetails(error));
        throw new https_1.HttpsError('internal', 'Failed to authenticate with FatSecret.');
    }
}
async function callFatSecretGet(endpoint, params, scope) {
    const accessToken = await getAccessToken(scope);
    try {
        const response = await axios_1.default.get(endpoint, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
            params: Object.assign(Object.assign({}, params), { format: 'json' }),
            timeout: 15000,
        });
        const responseData = response.data;
        const apiError = parseFatSecretErrorNode(responseData.error);
        if (apiError) {
            throw apiError;
        }
        logger.info('FatSecret GET response', {
            endpoint,
        });
        return responseData;
    }
    catch (error) {
        const apiError = parseFatSecretErrorFromAxios(error);
        if (apiError) {
            throw apiError;
        }
        if (error instanceof FatSecretApiError || error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error('FatSecret GET failed', Object.assign({ endpoint }, getAxiosErrorDetails(error)));
        throw new https_1.HttpsError('internal', 'FatSecret request failed.');
    }
}
async function callFatSecretJsonPost(endpoint, payload, scope) {
    const accessToken = await getAccessToken(scope);
    try {
        const response = await axios_1.default.post(endpoint, payload, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            timeout: 25000,
        });
        const responseData = response.data;
        const apiError = parseFatSecretErrorNode(responseData.error);
        if (apiError) {
            throw apiError;
        }
        logger.info('FatSecret JSON POST response', {
            endpoint,
        });
        return responseData;
    }
    catch (error) {
        const apiError = parseFatSecretErrorFromAxios(error);
        if (apiError) {
            throw apiError;
        }
        if (error instanceof FatSecretApiError || error instanceof https_1.HttpsError) {
            throw error;
        }
        logger.error('FatSecret JSON POST failed', Object.assign({ endpoint }, getAxiosErrorDetails(error)));
        throw new https_1.HttpsError('internal', 'FatSecret request failed.');
    }
}
function extractSearchFoodsResponse(responseData) {
    const foodsSearchNode = responseData.foods_search;
    const resultsNode = foodsSearchNode === null || foodsSearchNode === void 0 ? void 0 : foodsSearchNode.results;
    let foods = normalizeArray(resultsNode === null || resultsNode === void 0 ? void 0 : resultsNode.food);
    if (foods.length === 0) {
        const fallbackFoodsNode = responseData.foods;
        foods = normalizeArray(fallbackFoodsNode === null || fallbackFoodsNode === void 0 ? void 0 : fallbackFoodsNode.food);
    }
    const maxResults = toNumber(foodsSearchNode === null || foodsSearchNode === void 0 ? void 0 : foodsSearchNode.max_results) || toNumber(responseData.max_results);
    const totalResults = toNumber(foodsSearchNode === null || foodsSearchNode === void 0 ? void 0 : foodsSearchNode.total_results) || toNumber(responseData.total_results);
    const pageNumber = toNumber(foodsSearchNode === null || foodsSearchNode === void 0 ? void 0 : foodsSearchNode.page_number) || toNumber(responseData.page_number);
    return {
        foods,
        maxResults,
        totalResults,
        pageNumber,
    };
}
function normalizeBarcode(value) {
    const digitsOnly = value.replace(/\D/g, '');
    if (!digitsOnly) {
        throw new https_1.HttpsError('invalid-argument', 'Barcode is required.');
    }
    if (digitsOnly.length > 13) {
        throw new https_1.HttpsError('invalid-argument', 'Barcode must be 13 digits or fewer.');
    }
    return digitsOnly.padStart(13, '0');
}
function sanitizeEatenFoods(input) {
    if (!Array.isArray(input)) {
        return [];
    }
    const results = [];
    for (const entry of input) {
        if (!entry || typeof entry !== 'object')
            continue;
        const node = entry;
        const foodId = Math.trunc(toNumber(node.food_id));
        const foodName = typeof node.food_name === 'string' ? node.food_name.trim() : '';
        if (!foodId || !foodName)
            continue;
        const mapped = {
            food_id: foodId,
            food_name: foodName,
        };
        if (typeof node.food_brand === 'string' && node.food_brand.trim().length > 0) {
            mapped.food_brand = node.food_brand.trim();
        }
        if (typeof node.serving_description === 'string' && node.serving_description.trim().length > 0) {
            mapped.serving_description = node.serving_description.trim();
        }
        const servingSize = toNumber(node.serving_size);
        if (servingSize > 0) {
            mapped.serving_size = servingSize;
        }
        results.push(mapped);
    }
    return results;
}
function mapImageRecognitionFood(raw) {
    var _a, _b, _c;
    const eaten = raw.eaten;
    const nutrition = eaten === null || eaten === void 0 ? void 0 : eaten.total_nutritional_content;
    const suggestedServing = raw.suggested_serving;
    const foodNode = raw.food;
    const name = typeof raw.food_entry_name === 'string'
        ? raw.food_entry_name
        : (typeof (eaten === null || eaten === void 0 ? void 0 : eaten.food_name_singular) === 'string'
            ? eaten.food_name_singular
            : (typeof (foodNode === null || foodNode === void 0 ? void 0 : foodNode.food_name) === 'string' ? foodNode.food_name : 'Detected food'));
    const servingDescription = typeof (suggestedServing === null || suggestedServing === void 0 ? void 0 : suggestedServing.custom_serving_description) === 'string'
        ? suggestedServing.custom_serving_description
        : (typeof (suggestedServing === null || suggestedServing === void 0 ? void 0 : suggestedServing.serving_description) === 'string'
            ? suggestedServing.serving_description
            : 'serving');
    return {
        id: String((_b = (_a = raw.food_id) !== null && _a !== void 0 ? _a : foodNode === null || foodNode === void 0 ? void 0 : foodNode.food_id) !== null && _b !== void 0 ? _b : ''),
        name,
        brand: typeof (foodNode === null || foodNode === void 0 ? void 0 : foodNode.brand_name) === 'string' ? foodNode.brand_name : '',
        type: typeof (foodNode === null || foodNode === void 0 ? void 0 : foodNode.food_type) === 'string' ? foodNode.food_type : 'Generic',
        serving_id: String((_c = suggestedServing === null || suggestedServing === void 0 ? void 0 : suggestedServing.serving_id) !== null && _c !== void 0 ? _c : ''),
        serving_description: servingDescription,
        units: toNumber(eaten === null || eaten === void 0 ? void 0 : eaten.units) > 0 ? toNumber(eaten === null || eaten === void 0 ? void 0 : eaten.units) : 1,
        calories: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.calories),
        protein: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.protein),
        carbs: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.carbohydrate),
        fat: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.fat),
        saturated_fat: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.saturated_fat),
        polyunsaturated_fat: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.polyunsaturated_fat),
        monounsaturated_fat: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.monounsaturated_fat),
        cholesterol: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.cholesterol),
        sodium: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.sodium),
        potassium: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.potassium),
        fiber: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.fiber),
        sugar: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.sugar),
        vitamin_a: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.vitamin_a),
        vitamin_c: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.vitamin_c),
        calcium: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.calcium),
        iron: toNumber(nutrition === null || nutrition === void 0 ? void 0 : nutrition.iron),
        metric_description: typeof (eaten === null || eaten === void 0 ? void 0 : eaten.metric_description) === 'string' ? eaten.metric_description : null,
        total_metric_amount: toNumber(eaten === null || eaten === void 0 ? void 0 : eaten.total_metric_amount),
        per_unit_metric_amount: toNumber(eaten === null || eaten === void 0 ? void 0 : eaten.per_unit_metric_amount),
    };
}
function summarizeRecognizedMeal(foods) {
    if (foods.length === 0)
        return null;
    const sum = (key) => foods.reduce((total, item) => total + toNumber(item[key]), 0);
    const names = foods
        .map((item) => (typeof item.name === 'string' ? item.name.trim() : ''))
        .filter((name) => name.length > 0);
    let mealName = 'Scanned meal';
    if (names.length === 1) {
        mealName = names[0];
    }
    else if (names.length > 1) {
        const previewNames = names.slice(0, 3);
        mealName = previewNames.join(', ');
        if (names.length > 3) {
            mealName = `${mealName} +${names.length - 3} more`;
        }
    }
    return {
        name: mealName,
        item_count: foods.length,
        calories: sum('calories'),
        protein: sum('protein'),
        carbs: sum('carbs'),
        fat: sum('fat'),
        saturated_fat: sum('saturated_fat'),
        polyunsaturated_fat: sum('polyunsaturated_fat'),
        monounsaturated_fat: sum('monounsaturated_fat'),
        cholesterol: sum('cholesterol'),
        sodium: sum('sodium'),
        potassium: sum('potassium'),
        fiber: sum('fiber'),
        sugar: sum('sugar'),
        vitamin_a: sum('vitamin_a'),
        vitamin_c: sum('vitamin_c'),
        calcium: sum('calcium'),
        iron: sum('iron'),
    };
}
exports.searchFood = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a, _b, _c, _d, _e, _f;
    logAuthContext('searchFood', request);
    const query = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.query) === null || _b === void 0 ? void 0 : _b.trim();
    if (!query) {
        throw new https_1.HttpsError('invalid-argument', 'Query is required.');
    }
    const maxResults = Math.min(Math.max(toNumber((_c = request.data) === null || _c === void 0 ? void 0 : _c.maxResults), 1), 50) || 20;
    const pageNumber = Math.max(toNumber((_d = request.data) === null || _d === void 0 ? void 0 : _d.pageNumber), 0) || 0;
    const region = sanitizeRegion((_e = request.data) === null || _e === void 0 ? void 0 : _e.region);
    const language = sanitizeLanguage((_f = request.data) === null || _f === void 0 ? void 0 : _f.language);
    try {
        logger.info('searchFood request', { query, maxResults, pageNumber, region, language });
        const responseData = await callFatSecretGet(FATSECRET_SEARCH_V4_URL, Object.assign({ search_expression: query, max_results: String(maxResults), page_number: String(pageNumber), region }, (language ? { language } : {})), FATSECRET_SCOPE_PREMIER);
        const parsed = extractSearchFoodsResponse(responseData);
        const foods = parsed.foods.map(mapSearchFood).filter((food) => {
            const id = food.id;
            return typeof id === 'string' && id.length > 0;
        });
        logger.info('searchFood success', { count: foods.length });
        return {
            foods,
            maxResults: parsed.maxResults || maxResults,
            totalResults: parsed.totalResults,
            pageNumber: parsed.pageNumber || pageNumber,
        };
    }
    catch (error) {
        if (error instanceof FatSecretApiError && error.apiCode === 211) {
            return {
                foods: [],
                maxResults,
                totalResults: 0,
                pageNumber,
            };
        }
        throw toHttpsError('searchFood', error);
    }
});
exports.getFoodDetails = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a, _b, _c, _d, _e;
    logAuthContext('getFoodDetails', request);
    const foodId = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.foodId) === null || _b === void 0 ? void 0 : _b.trim();
    if (!foodId) {
        throw new https_1.HttpsError('invalid-argument', 'Food ID is required.');
    }
    const region = sanitizeRegion((_c = request.data) === null || _c === void 0 ? void 0 : _c.region);
    const language = sanitizeLanguage((_d = request.data) === null || _d === void 0 ? void 0 : _d.language);
    try {
        logger.info('getFoodDetails request', { foodId, region, language });
        const cacheRef = db.collection(FOOD_CACHE_COLLECTION).doc(foodId);
        const cacheDoc = await cacheRef.get();
        if (cacheDoc.exists) {
            const cachedData = cacheDoc.data();
            if (cachedData &&
                isFreshCache(cachedData.cachedAt) &&
                isValidCachedFood(cachedData.details)) {
                logger.info('getFoodDetails cache hit', { foodId });
                return { food: cachedData.details };
            }
        }
        const responseData = await callFatSecretGet(FATSECRET_FOOD_V5_URL, Object.assign({ food_id: foodId, flag_default_serving: 'true', region }, (language ? { language } : {})), FATSECRET_SCOPE_PREMIER);
        const rawFood = responseData.food;
        if (!rawFood) {
            throw new https_1.HttpsError('not-found', `Food ${foodId} not found.`);
        }
        const rawServings = extractServingsNode(rawFood);
        const servings = rawServings.map(mapServing);
        if (servings.length === 0) {
            throw new https_1.HttpsError('not-found', `Food ${foodId} has no serving data.`);
        }
        const details = {
            id: String((_e = rawFood.food_id) !== null && _e !== void 0 ? _e : foodId),
            name: typeof rawFood.food_name === 'string' ? rawFood.food_name : 'Unknown',
            brand: typeof rawFood.brand_name === 'string' ? rawFood.brand_name : '',
            type: typeof rawFood.food_type === 'string' ? rawFood.food_type : 'Generic',
            servings,
        };
        await cacheRef.set({
            details,
            cachedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        logger.info('getFoodDetails success', { foodId, servingsCount: servings.length });
        return { food: details };
    }
    catch (error) {
        throw toHttpsError('getFoodDetails', error);
    }
});
exports.searchBarcode = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a, _b, _c, _d;
    logAuthContext('searchBarcode', request);
    const barcode = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.barcode) === null || _b === void 0 ? void 0 : _b.trim();
    if (!barcode) {
        throw new https_1.HttpsError('invalid-argument', 'Barcode is required.');
    }
    const region = sanitizeRegion((_c = request.data) === null || _c === void 0 ? void 0 : _c.region);
    const language = sanitizeLanguage((_d = request.data) === null || _d === void 0 ? void 0 : _d.language);
    const normalizedBarcode = normalizeBarcode(barcode);
    try {
        logger.info('searchBarcode request', { barcode: normalizedBarcode, region, language });
        const responseData = await callFatSecretGet(FATSECRET_BARCODE_V2_URL, Object.assign({ barcode: normalizedBarcode, flag_default_serving: 'true', region }, (language ? { language } : {})), FATSECRET_SCOPE_BARCODE);
        const rawFood = responseData.food;
        if (!rawFood) {
            return { foods: [], foodId: null };
        }
        const mapped = mapSearchFood(rawFood);
        logger.info('searchBarcode success', {
            barcode: normalizedBarcode,
            foodId: mapped.id,
        });
        return {
            foods: [mapped],
            foodId: mapped.id,
        };
    }
    catch (error) {
        if (error instanceof FatSecretApiError && error.apiCode === 211) {
            return { foods: [], foodId: null };
        }
        throw toHttpsError('searchBarcode', error);
    }
});
exports.recognizeMealImage = (0, https_1.onCall)(callableOptions, async (request) => {
    var _a, _b, _c, _d, _e, _f;
    logAuthContext('recognizeMealImage', request);
    const imageB64 = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.imageB64) === null || _b === void 0 ? void 0 : _b.trim();
    if (!imageB64) {
        throw new https_1.HttpsError('invalid-argument', 'imageB64 is required.');
    }
    if (imageB64.length > 999982) {
        throw new https_1.HttpsError('invalid-argument', 'imageB64 exceeds the 999,982 character limit.');
    }
    const includeFoodData = toBoolean((_c = request.data) === null || _c === void 0 ? void 0 : _c.includeFoodData, true);
    const region = sanitizeRegion((_d = request.data) === null || _d === void 0 ? void 0 : _d.region);
    const language = sanitizeLanguage((_e = request.data) === null || _e === void 0 ? void 0 : _e.language);
    const eatenFoods = sanitizeEatenFoods((_f = request.data) === null || _f === void 0 ? void 0 : _f.eatenFoods);
    try {
        const payload = Object.assign(Object.assign({ image_b64: imageB64, include_food_data: includeFoodData, region }, (language ? { language } : {})), (eatenFoods.length > 0 ? { eaten_foods: eatenFoods } : {}));
        logger.info('recognizeMealImage request', {
            region,
            language,
            includeFoodData,
            eatenFoodsCount: eatenFoods.length,
        });
        const responseData = await callFatSecretJsonPost(FATSECRET_IMAGE_RECOGNITION_V2_URL, payload, FATSECRET_SCOPE_IMAGE_RECOGNITION);
        const foodsRaw = normalizeArray(responseData.food_response);
        const foods = foodsRaw.map(mapImageRecognitionFood).filter((food) => {
            const id = food.id;
            const name = food.name;
            return ((typeof id === 'string' && id.length > 0) ||
                (typeof name === 'string' && name.length > 0));
        });
        const meal = summarizeRecognizedMeal(foods);
        logger.info('recognizeMealImage success', {
            items: foods.length,
        });
        return {
            foods,
            meal,
        };
    }
    catch (error) {
        if (error instanceof FatSecretApiError && error.apiCode === 211) {
            return {
                foods: [],
                meal: null,
                errorCode: 211,
            };
        }
        throw toHttpsError('recognizeMealImage', error);
    }
});
//# sourceMappingURL=nutrition.js.map