import * as admin from 'firebase-admin';
import axios from 'axios';
import * as logger from 'firebase-functions/logger';
import { defineSecret } from 'firebase-functions/params';
import { GoogleGenerativeAI } from "@google/generative-ai";
import { CallableRequest, HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import * as cors from 'cors';

const corsHandler = cors({ origin: true });

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

const FATSECRET_CLIENT_ID = defineSecret('FATSECRET_CLIENT_ID');
const FATSECRET_CLIENT_SECRET = defineSecret('FATSECRET_CLIENT_SECRET');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const USDA_API_KEY = defineSecret('USDA_API_KEY');

const REGION = 'us-central1';
const FATSECRET_TOKEN_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_SEARCH_V4_URL = 'https://platform.fatsecret.com/rest/foods/search/v4';
const FATSECRET_FOOD_V5_URL = 'https://platform.fatsecret.com/rest/food/v5';
const FATSECRET_BARCODE_V2_URL =
    'https://platform.fatsecret.com/rest/food/barcode/find-by-id/v2';

const USDA_SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';
const USDA_DETAILS_URL = 'https://api.nal.usda.gov/fdc/v1/food';


const FATSECRET_SCOPE_PREMIER = 'premier';
const FATSECRET_SCOPE_BARCODE = 'barcode';


const FOOD_CACHE_COLLECTION = 'foods_cache';
const FOOD_CACHE_TTL_MS = 1000 * 60 * 60 * 24 * 30; // 30 days
const TOKEN_REFRESH_BUFFER_MS = 60 * 1000; // refresh 1 minute early

// Retrieve Gemini API Key using modern secrets
const GEMINI_KEY = GEMINI_API_KEY.value();
const genAI = GEMINI_KEY ? new GoogleGenerativeAI(GEMINI_KEY) : null;

interface CachedToken {
    token: string;
    expiresAtMs: number;
    scope: string;
}

interface SearchFoodRequest {
    query?: string;
    maxResults?: number;
    pageNumber?: number;
    region?: string;
    language?: string;
}

interface GetFoodDetailsRequest {
    foodId?: string;
    region?: string;
    language?: string;
}

interface SearchBarcodeRequest {
    barcode?: string;
    region?: string;
    language?: string;
}

interface RecognizeMealImageRequest {
    imageB64?: string;
}

interface NormalizedFood {
    name: string;
    nutritionPer100g: {
        calories: number;
        protein: number;
        carbs: number;
        fat: number;
    };
    servingOptions: {
        label: string;
        grams: number;
    }[];
    source: string;
}

class FatSecretApiError extends Error {
    readonly apiCode: number | null;

    constructor(apiCode: number | null, message: string) {
        super(message);
        this.name = 'FatSecretApiError';
        this.apiCode = apiCode;
    }
}

const cachedTokens = new Map<string, CachedToken>();

const callableOptions = {
    region: REGION,
    invoker: 'public' as const,
    secrets: [FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET, GEMINI_API_KEY],
};

function toNumber(value: unknown): number {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === 'string') {
        const parsed = Number.parseFloat(value);
        return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
}

function normalizeArray<T>(value: T | T[] | undefined | null): T[] {
    if (value == null) {
        return [];
    }
    return Array.isArray(value) ? value : [value];
}

/**
 * Normalizes USDA FDC food data into our internal format
 */
function normalizeUSDAResponse(food: any): NormalizedFood {
    const nutrients = food.foodNutrients || food.nutrients || [];
    
    const findNutrient = (nameOrId: string | number) => {
        return nutrients.find((n: any) => 
            n.nutrientId === nameOrId || 
            n.nutrientNumber === nameOrId || 
            (n.nutrient && (n.nutrient.id === nameOrId || n.nutrient.number === nameOrId)) ||
            (n.name && n.name.toLowerCase().includes(nameOrId.toString().toLowerCase()))
        );
    };

    const getNutrientValue = (id: number) => {
        const n = findNutrient(id);
        const val = n ? toNumber(n.amount || n.value) : 0;
        return val;
    };

    // USDA Nutrient IDs
    // Energy (kcal): 1008
    // Protein: 1003
    // Lipid (Fat): 1004
    // Carbohydrate: 1005
    
    let calories = getNutrientValue(1008);
    if (calories === 0) calories = getNutrientValue(208); // fallback
    const protein = getNutrientValue(1003);
    const fat = getNutrientValue(1004);
    const carbs = getNutrientValue(1005);

    const servingOptions: { label: string; grams: number }[] = [];
    
    // Add default 100g option
    servingOptions.push({ label: '100g', grams: 100 });

    // Handle USDA foodPortions
    if (food.foodPortions && Array.isArray(food.foodPortions)) {
        food.foodPortions.forEach((portion: any) => {
            if (portion.gramWeight) {
                const label = portion.modifier || portion.portionDescription || `${portion.amount || ''} ${portion.measureUnit?.name || 'serving'}`;
                servingOptions.push({
                    label: label.trim() || 'Custom serving',
                    grams: toNumber(portion.gramWeight)
                });
            }
        });
    }

    return {
        name: food.description || food.lowercaseDescription || 'Unknown Food',
        nutritionPer100g: {
            calories,
            protein,
            carbs,
            fat
        },
        servingOptions,
        source: 'usda'
    };
}

/**
 * Normalizes Open Food Facts data into our internal format
 */
function normalizeOFFResponse(product: any): NormalizedFood {
    const nutriments = product.nutriments || {};
    
    return {
        name: product.product_name || product.product_name_en || 'Unknown Food',
        nutritionPer100g: {
            calories: toNumber(nutriments['energy-kcal_100g'] || nutriments.energy_kcal_100g || 0),
            protein: toNumber(nutriments.proteins_100g || 0),
            carbs: toNumber(nutriments.carbohydrates_100g || 0),
            fat: toNumber(nutriments.fat_100g || 0)
        },
        servingOptions: [
            { label: '100g', grams: 100 },
            ...(product.serving_quantity ? [{ label: product.serving_size || '1 serving', grams: toNumber(product.serving_quantity) }] : [])
        ],
        source: 'off'
    };
}

/**
 * Fetch and normalize food from USDA
 */
async function fetchFoodFromUSDA(query: string): Promise<NormalizedFood | null> {
    const apiKey = USDA_API_KEY.value();
    if (!apiKey) return null;

    try {
        const searchRes = await axios.post(`${USDA_SEARCH_URL}?api_key=${apiKey}`, {
            query,
            pageSize: 1,
            dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)']
        }, { timeout: 10000 });

        const foods = searchRes.data.foods;
        if (!foods || foods.length === 0) return null;

        const fdcId = foods[0].fdcId;
        const detailsRes = await axios.get(`${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`, { timeout: 10000 });
        return normalizeUSDAResponse(detailsRes.data);
    } catch (error) {
        logger.error('fetchFoodFromUSDA error', { query, error });
        return null;
    }
}

/**
 * Fetch and normalize food from Open Food Facts
 */
async function fetchFoodFromOFF(query: string): Promise<NormalizedFood | null> {
    try {
        const url = `https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(query)}&search_simple=1&action=process&json=1&page_size=1`;
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Physiq/1.0 (support@physiq.app)' },
            timeout: 10000
        });

        const products = response.data.products;
        if (!products || products.length === 0) return null;

        return normalizeOFFResponse(products[0]);
    } catch (error) {
        logger.error('fetchFoodFromOFF error', { query, error });
        return null;
    }
}

export const searchFoodUSDA = onRequest({ secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        const query = req.body.query || req.query.query;
        if (!query) {
            res.status(400).send({ error: 'Query is required.' });
            return;
        }

        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios.post(`${USDA_SEARCH_URL}?api_key=${apiKey}`, {
                query,
                pageSize: 20,
                dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)']
            }, { timeout: 10000 });
            res.send(response.data.foods || []);
        } catch (error) {
            logger.error('searchFoodUSDA error', error);
            res.status(500).send({ error: 'Search failed.' });
        }
    });
});

export const getFoodDetailsUSDA = onRequest({ secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        const fdcId = req.body.fdcId || req.query.fdcId;
        if (!fdcId) {
            res.status(400).send({ error: 'FDC ID is required.' });
            return;
        }

        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios.get(`${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`, { timeout: 10000 });
            res.send(normalizeUSDAResponse(response.data));
        } catch (error) {
            logger.error('getFoodDetailsUSDA error', error);
            res.status(500).send({ error: 'Details failed.' });
        }
    });
});

function toBoolean(value: unknown, fallback = false): boolean {
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value === 1;
    if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === 'true' || normalized === '1') return true;
        if (normalized === 'false' || normalized === '0') return false;
    }
    return fallback;
}

function sanitizeRegion(value: unknown): string {
    if (typeof value !== 'string') return 'US';
    const trimmed = value.trim().toUpperCase();
    return trimmed.length >= 2 ? trimmed : 'US';
}

function sanitizeLanguage(value: unknown): string | null {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim().toLowerCase();
    return trimmed.length >= 2 ? trimmed : null;
}

function escapeRegExp(value: string): string {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function parseMacro(description: string, label: string): number {
    const pattern = new RegExp(`${escapeRegExp(label)}:\\s*([\\d.]+)`, 'i');
    const match = pattern.exec(description);
    return match ? toNumber(match[1]) : 0;
}

function parseServingSummary(description: string): string {
    const match = /^Per\s+(.+?)\s*-/i.exec(description);
    if (!match || !match[1]) {
        return 'serving';
    }
    return match[1].trim();
}

function getAxiosErrorDetails(error: unknown): Record<string, unknown> {
    if (axios.isAxiosError(error)) {
        return {
            message: error.message,
            status: error.response?.status,
            data: error.response?.data,
        };
    }

    if (error instanceof Error) {
        return { message: error.message };
    }

    return { error };
}

function logAuthContext(functionName: string, request: CallableRequest<unknown>): void {
    logger.info(`${functionName} auth`, {
        authenticated: !!request.auth,
        uid: request.auth?.uid ?? null,
    });
}

function parseFatSecretErrorNode(errorNode: unknown): FatSecretApiError | null {
    if (!errorNode || typeof errorNode !== 'object') {
        return null;
    }

    const node = errorNode as Record<string, unknown>;
    const codeRaw = node.code;
    const parsedCode = toNumber(codeRaw);
    const code = parsedCode > 0 ? Math.trunc(parsedCode) : null;

    let message = 'FatSecret API request failed.';
    const messageValue = node.message;
    if (typeof messageValue === 'string' && messageValue.trim().length > 0) {
        message = messageValue.trim();
    } else if (messageValue && typeof messageValue === 'object') {
        const nested = messageValue as Record<string, unknown>;
        if (typeof nested.value === 'string' && nested.value.trim().length > 0) {
            message = nested.value.trim();
        }
    }

    return new FatSecretApiError(code, message);
}

function parseFatSecretErrorFromPayload(payload: unknown): FatSecretApiError | null {
    if (!payload || typeof payload !== 'object') {
        return null;
    }

    const data = payload as Record<string, unknown>;
    return parseFatSecretErrorNode(data.error);
}

function parseFatSecretErrorFromAxios(error: unknown): FatSecretApiError | null {
    if (!axios.isAxiosError(error)) return null;
    return parseFatSecretErrorFromPayload(error.response?.data);
}

function extractServingsNode(food: Record<string, unknown>): Record<string, unknown>[] {
    const servingsNode = food.servings;

    if (servingsNode && typeof servingsNode === 'object' && !Array.isArray(servingsNode)) {
        const nested = (servingsNode as Record<string, unknown>).serving;
        return normalizeArray<Record<string, unknown>>(
            nested as Record<string, unknown> | Record<string, unknown>[] | undefined
        );
    }

    return normalizeArray<Record<string, unknown>>(
        servingsNode as Record<string, unknown> | Record<string, unknown>[] | undefined
    );
}

function pickDefaultServing(food: Record<string, unknown>): Record<string, unknown> | null {
    const servings = extractServingsNode(food);
    if (servings.length === 0) return null;

    const defaultServing = servings.find((serving) => toBoolean(serving.is_default));
    return defaultServing ?? servings[0];
}

function mapSearchFood(rawFood: Record<string, unknown>): Record<string, unknown> {
    const description = typeof rawFood.food_description === 'string' ? rawFood.food_description : '';
    const defaultServing = pickDefaultServing(rawFood);
    const servingSummary = typeof rawFood.serving_summary === 'string'
        ? rawFood.serving_summary.trim()
        : '';
    const servingDescription = typeof defaultServing?.serving_description === 'string'
        ? defaultServing.serving_description
        : '';

    const carbsFromServing = toNumber(defaultServing?.carbohydrate) > 0
        ? toNumber(defaultServing?.carbohydrate)
        : toNumber(defaultServing?.carbs);

    return {
        id: String(rawFood.food_id ?? ''),
        name: typeof rawFood.food_name === 'string' ? rawFood.food_name : 'Unknown',
        brand: typeof rawFood.brand_name === 'string' ? rawFood.brand_name : '',
        type: typeof rawFood.food_type === 'string' ? rawFood.food_type : 'Generic',
        description,
        serving_summary: servingSummary.length > 0
            ? servingSummary
            : (servingDescription.length > 0 ? servingDescription : parseServingSummary(description)),
        calories: toNumber(rawFood.calories) > 0
            ? toNumber(rawFood.calories)
            : (toNumber(defaultServing?.calories) > 0
                ? toNumber(defaultServing?.calories)
                : parseMacro(description, 'Calories')),
        protein: toNumber(rawFood.protein) > 0
            ? toNumber(rawFood.protein)
            : (toNumber(defaultServing?.protein) > 0
                ? toNumber(defaultServing?.protein)
                : parseMacro(description, 'Protein')),
        carbs: toNumber(rawFood.carbs) > 0
            ? toNumber(rawFood.carbs)
            : (carbsFromServing > 0
                ? carbsFromServing
                : parseMacro(description, 'Carbs')),
        fat: toNumber(rawFood.fat) > 0
            ? toNumber(rawFood.fat)
            : (toNumber(defaultServing?.fat) > 0
                ? toNumber(defaultServing?.fat)
                : parseMacro(description, 'Fat')),
    };
}

function mapServing(rawServing: Record<string, unknown>): Record<string, unknown> {
    const carbs = toNumber(rawServing.carbohydrate) > 0
        ? toNumber(rawServing.carbohydrate)
        : toNumber(rawServing.carbs);

    return {
        serving_id: String(rawServing.serving_id ?? ''),
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

function isFreshCache(cachedAt: unknown): boolean {
    if (!(cachedAt instanceof admin.firestore.Timestamp)) {
        return false;
    }

    return Date.now() - cachedAt.toMillis() < FOOD_CACHE_TTL_MS;
}

function isValidCachedFood(details: unknown): details is Record<string, unknown> {
    if (!details || typeof details !== 'object') {
        return false;
    }

    const candidate = details as Record<string, unknown>;
    return typeof candidate.id === 'string' &&
        typeof candidate.name === 'string' &&
        Array.isArray(candidate.servings) &&
        candidate.servings.length > 0;
}

function toHttpsError(functionName: string, error: unknown): HttpsError {
    if (error instanceof HttpsError) {
        return error;
    }

    if (error instanceof FatSecretApiError) {
        const code = error.apiCode === 211 ? 'not-found' : 'internal';
        return new HttpsError(code, error.message);
    }

    if (error instanceof Error) {
        return new HttpsError('internal', `${functionName} failed: ${error.message}`);
    }

    return new HttpsError('internal', `${functionName} failed.`);
}

async function getAccessToken(scope: string): Promise<string> {
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
        throw new HttpsError(
            'failed-precondition',
            'FatSecret secrets are not configured.'
        );
    }

    try {
        // Use URLSearchParams for correct encoding of the body
        // Includes client_id and client_secret in the body as recommended for robustness
        const body = new URLSearchParams({
            grant_type: 'client_credentials',
            scope: scope,
            client_id: clientId,
            client_secret: clientSecret
        });

        const response = await axios.post(FATSECRET_TOKEN_URL, body.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            timeout: 15000,
        });

        // Log full successful response for verification
        console.log("FatSecret token success:", JSON.stringify(response.data, null, 2));

        const accessToken = response.data?.access_token as string | undefined;
        const expiresInSeconds = toNumber(response.data?.expires_in) || 3600;

        if (!accessToken) {
            logger.error('FatSecret token response missing token', { response: response.data });
            throw new HttpsError('internal', 'FatSecret token response missing access token.');
        }

        const token = {
            token: accessToken,
            expiresAtMs: Date.now() + (expiresInSeconds * 1000),
            scope,
        };
        cachedTokens.set(scope, token);

        logger.info('FatSecret token refreshed', { expiresInSeconds, scope });
        return accessToken;
    } catch (error) {
        // Enhanced error logging to capture status and full response body/data
        if (axios.isAxiosError(error)) {
            const errorDetails = {
                status: error.response?.status,
                statusText: error.response?.statusText,
                data: error.response?.data,
                headers: error.response?.headers,
                scope
            };
            logger.error('FatSecret token request failed', errorDetails);
            console.error("FatSecret token error details:", JSON.stringify(errorDetails, null, 2));
        } else {
            logger.error('FatSecret token request failed with unknown error', { scope, error });
        }

        if (error instanceof HttpsError) {
            throw error;
        }

        throw new HttpsError('internal', 'Failed to authenticate with FatSecret.');
    }
}

async function callFatSecretGet(
    endpoint: string,
    params: Record<string, string>,
    scope: string
): Promise<Record<string, unknown>> {
    const accessToken = await getAccessToken(scope);

    try {
        const response = await axios.get(endpoint, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
            params: {
                ...params,
                format: 'json',
            },
            timeout: 15000,
        });

        const responseData = response.data as Record<string, unknown>;
        const apiError = parseFatSecretErrorNode(responseData.error);
        if (apiError) {
            throw apiError;
        }

        logger.info('FatSecret GET response', {
            endpoint,
        });

        return responseData;
    } catch (error) {
        const apiError = parseFatSecretErrorFromAxios(error);
        if (apiError) {
            throw apiError;
        }

        if (error instanceof FatSecretApiError || error instanceof HttpsError) {
            throw error;
        }

        logger.error('FatSecret GET failed', {
            endpoint,
            ...getAxiosErrorDetails(error),
        });
        throw new HttpsError('internal', 'FatSecret request failed.');
    }
}



function extractSearchFoodsResponse(
    responseData: Record<string, unknown>
): {
    foods: Record<string, unknown>[];
    maxResults: number;
    totalResults: number;
    pageNumber: number;
} {
    const foodsSearchNode = responseData.foods_search as Record<string, unknown> | undefined;
    const resultsNode = foodsSearchNode?.results as Record<string, unknown> | undefined;

    let foods = normalizeArray<Record<string, unknown>>(
        resultsNode?.food as Record<string, unknown> | Record<string, unknown>[] | undefined
    );

    if (foods.length === 0) {
        const fallbackFoodsNode = responseData.foods as Record<string, unknown> | undefined;
        foods = normalizeArray<Record<string, unknown>>(
            fallbackFoodsNode?.food as Record<string, unknown> | Record<string, unknown>[] | undefined
        );
    }

    const maxResults = toNumber(foodsSearchNode?.max_results) || toNumber(responseData.max_results);
    const totalResults = toNumber(foodsSearchNode?.total_results) || toNumber(responseData.total_results);
    const pageNumber = toNumber(foodsSearchNode?.page_number) || toNumber(responseData.page_number);

    return {
        foods,
        maxResults,
        totalResults,
        pageNumber,
    };
}

function normalizeBarcode(value: string): string {
    const digitsOnly = value.replace(/\D/g, '');
    if (!digitsOnly) {
        throw new HttpsError('invalid-argument', 'Barcode is required.');
    }
    if (digitsOnly.length > 13) {
        throw new HttpsError('invalid-argument', 'Barcode must be 13 digits or fewer.');
    }
    return digitsOnly.padStart(13, '0');
}



export const searchFood = onCall<SearchFoodRequest>(callableOptions, async (request) => {
    logAuthContext('searchFood', request);

    const query = request.data?.query?.trim();
    if (!query) {
        throw new HttpsError('invalid-argument', 'Query is required.');
    }

    const maxResults = Math.min(Math.max(toNumber(request.data?.maxResults), 1), 50) || 20;
    const pageNumber = Math.max(toNumber(request.data?.pageNumber), 0) || 0;
    const region = sanitizeRegion(request.data?.region);
    const language = sanitizeLanguage(request.data?.language);

    try {
        logger.info('searchFood request', { query, maxResults, pageNumber, region, language });

        const responseData = await callFatSecretGet(
            FATSECRET_SEARCH_V4_URL,
            {
                search_expression: query,
                max_results: String(maxResults),
                page_number: String(pageNumber),
                region,
                ...(language ? { language } : {}),
            },
            FATSECRET_SCOPE_PREMIER
        );

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
    } catch (error) {
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

export const getFoodDetails = onCall<GetFoodDetailsRequest>(callableOptions, async (request) => {
    logAuthContext('getFoodDetails', request);

    const foodId = request.data?.foodId?.trim();
    if (!foodId) {
        throw new HttpsError('invalid-argument', 'Food ID is required.');
    }

    const region = sanitizeRegion(request.data?.region);
    const language = sanitizeLanguage(request.data?.language);

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

        const responseData = await callFatSecretGet(
            FATSECRET_FOOD_V5_URL,
            {
                food_id: foodId,
                flag_default_serving: 'true',
                region,
                ...(language ? { language } : {}),
            },
            FATSECRET_SCOPE_PREMIER
        );

        const rawFood = responseData.food as Record<string, unknown> | undefined;
        if (!rawFood) {
            throw new HttpsError('not-found', `Food ${foodId} not found.`);
        }

        const rawServings = extractServingsNode(rawFood);
        const servings = rawServings.map(mapServing);

        if (servings.length === 0) {
            throw new HttpsError('not-found', `Food ${foodId} has no serving data.`);
        }

        const details = {
            id: String(rawFood.food_id ?? foodId),
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
    } catch (error) {
        throw toHttpsError('getFoodDetails', error);
    }
});

export const searchBarcode = onCall<SearchBarcodeRequest>(callableOptions, async (request) => {
    logAuthContext('searchBarcode', request);

    const barcode = request.data?.barcode?.trim();
    if (!barcode) {
        throw new HttpsError('invalid-argument', 'Barcode is required.');
    }

    const region = sanitizeRegion(request.data?.region);
    const language = sanitizeLanguage(request.data?.language);
    const normalizedBarcode = normalizeBarcode(barcode);

    try {
        logger.info('searchBarcode request', { barcode: normalizedBarcode, region, language });

        const responseData = await callFatSecretGet(
            FATSECRET_BARCODE_V2_URL,
            {
                barcode: normalizedBarcode,
                flag_default_serving: 'true',
                region,
                ...(language ? { language } : {}),
            },
            FATSECRET_SCOPE_BARCODE
        );

        const rawFood = responseData.food as Record<string, unknown> | undefined;
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
    } catch (error) {
        if (error instanceof FatSecretApiError && error.apiCode === 211) {
            return { foods: [], foodId: null };
        }
        throw toHttpsError('searchBarcode', error);
    }
});

// ---------------------------------------------------------------------------
// Gemini-powered meal image recognition
// ---------------------------------------------------------------------------

const GEMINI_MEAL_PROMPT = `You are a professional nutritionist and food recognition expert.
Analyze the given meal image carefully.

Your task:
1. Identify ALL food items present in the image.
2. Be specific (e.g., "chapati", "dal tadka", "jeera rice", not "food").
3. Estimate realistic serving size for each item (in grams or common units).
4. Detect multiple items if present.
5. Provide approximate calories and macros (protein, carbs, fat) for each item as a fallback.

STRICT RULES:
- Return ONLY valid JSON.
- No explanation.
- No markdown formatting or extra text.
- Use realistic Indian food naming when applicable.
- If unsure, provide your best professional estimate.

JSON FORMAT:
{
  "mealName": "string - descriptive name",
  "items": [
    {
      "name": "string",
      "quantity": number,
      "servingSize": "string (e.g., '2 pieces', '1 bowl')",
      "estimatedGrams": number,
      "calories": number,
      "protein": number,
      "carbs": number,
      "fat": number
    }
  ]
}`;

interface GeminiMealItem {
    ingredient?: string;
    name?: string;
    estimated_amount?: string;
    amount?: string;
    serving_size?: string;
    calories_estimate?: number;
    protein_estimate?: number;
    carbs_estimate?: number;
    fat_estimate?: number;
    estimated_grams?: number;
    // Alternative names from Gemini output
    servingSize?: string;
    estimatedGrams?: number;
    calories?: number;
    protein?: number;
    carbs?: number;
    fat?: number;
}



function buildFallbackMealResponse(): Record<string, unknown> {
    return {
        meal_title: 'Unidentified Meal',
        serving_container: 'plate',
        items: [
            {
                ingredient: 'Food item',
                estimated_amount: '1 serving',
                serving_size: '100g',
                calories_estimate: 200,
                protein_estimate: 8,
                carbs_estimate: 25,
                fat_estimate: 8,
            },
        ],
    };
}

function validateAndNormalizeMealResponse(parsed: unknown): Record<string, unknown> {
    if (!parsed || typeof parsed !== 'object') {
        logger.warn('Gemini response is not an object, using fallback');
        return buildFallbackMealResponse();
    }

    const data = parsed as any;

    const mealTitle =
        (typeof data.mealName === 'string' && data.mealName.trim().length > 0)
            ? data.mealName.trim()
            : (typeof data.meal_title === 'string' && data.meal_title.trim().length > 0)
                ? data.meal_title.trim()
                : 'Detected Meal';

    const servingContainer =
        typeof data.serving_container === 'string' && data.serving_container.trim().length > 0
            ? data.serving_container.trim().toLowerCase()
            : 'plate';

    const rawItems = (Array.isArray(data.items) ? data.items : []) as GeminiMealItem[];

    if (rawItems.length === 0) {
        logger.warn('Gemini returned zero items, using fallback');
        return buildFallbackMealResponse();
    }

    const validatedItems: Record<string, unknown>[] = [];

    for (const item of rawItems) {
        if (!item || typeof item !== 'object') continue;

        const ingredientName =
            (typeof item.name === 'string' && item.name.trim().length > 0
                ? item.name.trim()
                : typeof item.ingredient === 'string' && item.ingredient.trim().length > 0
                ? item.ingredient.trim()
                : null);

        if (!ingredientName) continue;

        const estimatedAmount =
            typeof item.servingSize === 'string' && item.servingSize.trim().length > 0
                ? item.servingSize.trim()
                : typeof item.estimated_amount === 'string' && item.estimated_amount.trim().length > 0
                ? item.estimated_amount.trim()
                : typeof item.amount === 'string' && item.amount.trim().length > 0
                ? item.amount.trim()
                : '1 serving';

        const servingSize =
            typeof item.estimatedGrams === 'number'
                ? `${item.estimatedGrams}g`
                : typeof item.serving_size === 'string' && item.serving_size.trim().length > 0
                ? item.serving_size.trim()
                : '100g';

        validatedItems.push({
            ingredient: ingredientName,
            estimated_amount: estimatedAmount,
            serving_size: servingSize,
            calories_estimate: toNumber(item.calories ?? item.calories_estimate) || 100,
            protein_estimate: toNumber(item.protein ?? item.protein_estimate) || 3,
            carbs_estimate: toNumber(item.carbs ?? item.carbs_estimate) || 15,
            fat_estimate: toNumber(item.fat ?? item.fat_estimate) || 3,
            estimated_grams: toNumber(item.estimated_grams ?? item.estimatedGrams) || 100,
        });
    }

    if (validatedItems.length === 0) {
        logger.warn('All Gemini items were invalid, using fallback');
        return buildFallbackMealResponse();
    }

    return {
        meal_title: mealTitle,
        serving_container: servingContainer,
        items: validatedItems,
    };
}

export const recognizeMealImage = onCall<RecognizeMealImageRequest>(
    callableOptions,
    async (request) => {
        logAuthContext('recognizeMealImage', request);

        const imageB64 = request.data?.imageB64?.trim();
        if (!imageB64) {
            throw new HttpsError('invalid-argument', 'imageB64 is required.');
        }
        if (imageB64.length > 10_000_000) {
            throw new HttpsError(
                'invalid-argument',
                'imageB64 exceeds the 10 MB limit.'
            );
        }

        if (!genAI) {
            logger.error('Gemini API key is not configured');
            // Return fallback instead of crashing
            return buildFallbackMealResponse();
        }

        try {
            logger.info('recognizeMealImage request', {
                imageSizeChars: imageB64.length,
            });

            const model = genAI.getGenerativeModel({
                model: 'gemini-3.1-flash-lite-preview',
                generationConfig: {
                    responseMimeType: 'application/json',
                    temperature: 0.1,
                },
            });

            const result = await model.generateContent([
                GEMINI_MEAL_PROMPT,
                {
                    inlineData: {
                        mimeType: 'image/jpeg',
                        data: imageB64,
                    },
                },
            ]);

            const responseText = result.response.text();

            logger.info('RAW GEMINI RESPONSE:', { responseText });

            // Attempt to parse JSON — strip markdown fences and any leading/trailing garbage
            let cleanedText = responseText.trim();
            
            // Remove ```json blocks or any ``` blocks
            if (cleanedText.includes('```')) {
                cleanedText = cleanedText
                    .replace(/```json/gi, '')
                    .replace(/```/g, '')
                    .trim();
            }

            // If there's still extra text before the first '{' or after the last '}'
            const firstBrace = cleanedText.indexOf('{');
            const lastBrace = cleanedText.lastIndexOf('}');
            if (firstBrace !== -1 && lastBrace !== -1) {
                cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
            }

            let parsed: unknown;
            try {
                parsed = JSON.parse(cleanedText);
            } catch (parseError) {
                logger.error('Failed to parse Gemini JSON response', {
                    parseError,
                    rawText: cleanedText.substring(0, 1000),
                });
                return buildFallbackMealResponse();
            }

            const validated = validateAndNormalizeMealResponse(parsed);
            const items = validated.items as any[];

            logger.info('recognizeMealImage finalized (Gemini only)', {
                mealTitle: validated.meal_title,
                itemCount: items.length,
            });

            return validated;
        } catch (error) {
            logger.error('recognizeMealImage Gemini analysis failed', {
                error: error instanceof Error ? error.message : error,
                stack: error instanceof Error ? error.stack : undefined,
            });

            // Return fallback instead of crashing
            return buildFallbackMealResponse();
        }
    }
);

export const enrichMealItem = onCall<{ ingredient: string }>(
    callableOptions,
    async (request) => {
        const query = (request.data as any)?.ingredient?.trim();
        if (!query) {
            throw new HttpsError('invalid-argument', 'ingredient is required.');
        }

        logger.info('enrichMealItem request', { query });

        // Try USDA first
        let nutritionData = await fetchFoodFromUSDA(query);
        
        // Fallback to OFF
        if (!nutritionData) {
            logger.info(`USDA failed for "${query}", trying OFF fallback`);
            nutritionData = await fetchFoodFromOFF(query);
        }

        if (nutritionData) {
            logger.info(`Enriched ${query} from ${nutritionData.source}`);
            return nutritionData;
        }

        logger.warn(`No enrichment found for "${query}"`);
        return null;
    }
);
