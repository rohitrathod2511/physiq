import * as admin from 'firebase-admin';
import axios from 'axios';
import * as logger from 'firebase-functions/logger';
import { defineSecret } from 'firebase-functions/params';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

const FATSECRET_CLIENT_ID = defineSecret('FATSECRET_CLIENT_ID');
const FATSECRET_CLIENT_SECRET = defineSecret('FATSECRET_CLIENT_SECRET');

const REGION = 'us-central1';
const FATSECRET_TOKEN_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_SEARCH_V4_URL = 'https://platform.fatsecret.com/rest/foods/search/v4';
const FATSECRET_FOOD_V5_URL = 'https://platform.fatsecret.com/rest/food/v5';
const FATSECRET_BARCODE_V2_URL =
    'https://platform.fatsecret.com/rest/food/barcode/find-by-id/v2';
const FATSECRET_IMAGE_RECOGNITION_V2_URL =
    'https://platform.fatsecret.com/rest/image-recognition/v2';

const FATSECRET_SCOPE_PREMIER = 'premier';
const FATSECRET_SCOPE_BARCODE = 'barcode';
const FATSECRET_SCOPE_IMAGE_RECOGNITION = 'image-recognition';

const FOOD_CACHE_COLLECTION = 'foods_cache';
const FOOD_CACHE_TTL_MS = 1000 * 60 * 60 * 24 * 30; // 30 days
const TOKEN_REFRESH_BUFFER_MS = 60 * 1000; // refresh 1 minute early

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

interface EatenFoodInput {
    food_id?: number | string;
    food_name?: string;
    food_brand?: string | null;
    serving_description?: string;
    serving_size?: number | string;
}

interface RecognizeMealImageRequest {
    imageB64?: string;
    includeFoodData?: boolean;
    eatenFoods?: EatenFoodInput[];
    region?: string;
    language?: string;
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
    secrets: [FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET],
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

    const body = new URLSearchParams();
    body.set('grant_type', 'client_credentials');
    body.set('scope', scope);

    const authHeader = 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    try {
        const response = await axios.post(FATSECRET_TOKEN_URL, body.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': authHeader,
            },
            timeout: 15000,
        });

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
        if (error instanceof HttpsError) {
            throw error;
        }

        logger.error('FatSecret token request failed', {
            scope,
            ...getAxiosErrorDetails(error),
        });
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

async function callFatSecretJsonPost(
    endpoint: string,
    payload: Record<string, unknown>,
    scope: string
): Promise<Record<string, unknown>> {
    const accessToken = await getAccessToken(scope);

    try {
        const response = await axios.post(endpoint, payload, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            timeout: 25000,
        });

        const responseData = response.data as Record<string, unknown>;
        const apiError = parseFatSecretErrorNode(responseData.error);
        if (apiError) {
            throw apiError;
        }

        logger.info('FatSecret JSON POST response', {
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

        logger.error('FatSecret JSON POST failed', {
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

function sanitizeEatenFoods(input: unknown): Record<string, unknown>[] {
    if (!Array.isArray(input)) {
        return [];
    }

    const results: Record<string, unknown>[] = [];
    for (const entry of input) {
        if (!entry || typeof entry !== 'object') continue;
        const node = entry as Record<string, unknown>;

        const foodId = Math.trunc(toNumber(node.food_id));
        const foodName = typeof node.food_name === 'string' ? node.food_name.trim() : '';
        if (!foodId || !foodName) continue;

        const mapped: Record<string, unknown> = {
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

function mapImageRecognitionFood(raw: Record<string, unknown>): Record<string, unknown> {
    const eaten = raw.eaten as Record<string, unknown> | undefined;
    const nutrition = eaten?.total_nutritional_content as Record<string, unknown> | undefined;
    const suggestedServing = raw.suggested_serving as Record<string, unknown> | undefined;
    const foodNode = raw.food as Record<string, unknown> | undefined;

    const name = typeof raw.food_entry_name === 'string'
        ? raw.food_entry_name
        : (typeof eaten?.food_name_singular === 'string'
            ? eaten.food_name_singular
            : (typeof foodNode?.food_name === 'string' ? foodNode.food_name : 'Detected food'));

    const servingDescription = typeof suggestedServing?.custom_serving_description === 'string'
        ? suggestedServing.custom_serving_description
        : (typeof suggestedServing?.serving_description === 'string'
            ? suggestedServing.serving_description
            : 'serving');

    return {
        id: String(raw.food_id ?? foodNode?.food_id ?? ''),
        name,
        brand: typeof foodNode?.brand_name === 'string' ? foodNode.brand_name : '',
        type: typeof foodNode?.food_type === 'string' ? foodNode.food_type : 'Generic',
        serving_id: String(suggestedServing?.serving_id ?? ''),
        serving_description: servingDescription,
        units: toNumber(eaten?.units) > 0 ? toNumber(eaten?.units) : 1,
        calories: toNumber(nutrition?.calories),
        protein: toNumber(nutrition?.protein),
        carbs: toNumber(nutrition?.carbohydrate),
        fat: toNumber(nutrition?.fat),
        saturated_fat: toNumber(nutrition?.saturated_fat),
        polyunsaturated_fat: toNumber(nutrition?.polyunsaturated_fat),
        monounsaturated_fat: toNumber(nutrition?.monounsaturated_fat),
        cholesterol: toNumber(nutrition?.cholesterol),
        sodium: toNumber(nutrition?.sodium),
        potassium: toNumber(nutrition?.potassium),
        fiber: toNumber(nutrition?.fiber),
        sugar: toNumber(nutrition?.sugar),
        vitamin_a: toNumber(nutrition?.vitamin_a),
        vitamin_c: toNumber(nutrition?.vitamin_c),
        calcium: toNumber(nutrition?.calcium),
        iron: toNumber(nutrition?.iron),
        metric_description: typeof eaten?.metric_description === 'string' ? eaten.metric_description : null,
        total_metric_amount: toNumber(eaten?.total_metric_amount),
        per_unit_metric_amount: toNumber(eaten?.per_unit_metric_amount),
    };
}

function summarizeRecognizedMeal(foods: Record<string, unknown>[]): Record<string, unknown> | null {
    if (foods.length === 0) return null;

    const sum = (key: string): number =>
        foods.reduce((total, item) => total + toNumber(item[key]), 0);

    const names = foods
        .map((item) => (typeof item.name === 'string' ? item.name.trim() : ''))
        .filter((name) => name.length > 0);

    let mealName = 'Scanned meal';
    if (names.length === 1) {
        mealName = names[0];
    } else if (names.length > 1) {
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

export const recognizeMealImage = onCall<RecognizeMealImageRequest>(
    callableOptions,
    async (request) => {
        logAuthContext('recognizeMealImage', request);

        const imageB64 = request.data?.imageB64?.trim();
        if (!imageB64) {
            throw new HttpsError('invalid-argument', 'imageB64 is required.');
        }
        if (imageB64.length > 999982) {
            throw new HttpsError(
                'invalid-argument',
                'imageB64 exceeds the 999,982 character limit.'
            );
        }

        const includeFoodData = toBoolean(request.data?.includeFoodData, true);
        const region = sanitizeRegion(request.data?.region);
        const language = sanitizeLanguage(request.data?.language);
        const eatenFoods = sanitizeEatenFoods(request.data?.eatenFoods);

        try {
            const payload: Record<string, unknown> = {
                image_b64: imageB64,
                include_food_data: includeFoodData,
                region,
                ...(language ? { language } : {}),
                ...(eatenFoods.length > 0 ? { eaten_foods: eatenFoods } : {}),
            };

            logger.info('recognizeMealImage request', {
                region,
                language,
                includeFoodData,
                eatenFoodsCount: eatenFoods.length,
            });

            const responseData = await callFatSecretJsonPost(
                FATSECRET_IMAGE_RECOGNITION_V2_URL,
                payload,
                FATSECRET_SCOPE_IMAGE_RECOGNITION
            );

            const foodsRaw = normalizeArray<Record<string, unknown>>(
                responseData.food_response as
                    | Record<string, unknown>
                    | Record<string, unknown>[]
                    | undefined
            );

            const foods = foodsRaw.map(mapImageRecognitionFood).filter((food) => {
                const id = food.id;
                const name = food.name;
                return (
                    (typeof id === 'string' && id.length > 0) ||
                    (typeof name === 'string' && name.length > 0)
                );
            });

            const meal = summarizeRecognizedMeal(foods);

            logger.info('recognizeMealImage success', {
                items: foods.length,
            });

            return {
                foods,
                meal,
            };
        } catch (error) {
            if (error instanceof FatSecretApiError && error.apiCode === 211) {
                return {
                    foods: [],
                    meal: null,
                    errorCode: 211,
                };
            }
            throw toHttpsError('recognizeMealImage', error);
        }
    }
);
