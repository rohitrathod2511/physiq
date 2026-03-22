import axios from 'axios';
import * as logger from 'firebase-functions/logger';
import { defineSecret } from 'firebase-functions/params';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import * as cors from 'cors';

const corsHandler = cors({ origin: true });

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const USDA_API_KEY = defineSecret('USDA_API_KEY');

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
    invoker: 'public' as const,
    secrets: [GEMINI_API_KEY, USDA_API_KEY],
};

const nutritionCache = new Map<string, { expiresAt: number; value: NormalizedFood }>();
const mealCache = new Map<string, { expiresAt: number; value: Record<string, unknown> }>();
const inFlightMealRequests = new Map<string, Promise<Record<string, unknown>>>();
let lastRequestTime = 0;

const QUERY_NORMALIZATION_MAP: Record<string, string> = {
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

interface RecognizeMealImageRequest {
    imageB64?: string;
}

interface GeminiMealItem {
    ingredient?: string;
    name?: string;
    estimated_amount?: string;
    amount?: string;
    serving_size?: string;
    servingSize?: string;
    calories_estimate?: number | null;
    calories?: number | null;
    protein_estimate?: number | null;
    protein?: number | null;
    carbs_estimate?: number | null;
    carbs?: number | null;
    fat_estimate?: number | null;
    fat?: number | null;
    estimated_grams?: number | null;
    estimatedGrams?: number | null;
    quantity?: number | null;
}

interface ValidatedMealItem {
    ingredient: string;
    estimated_amount: string;
    serving_size: string;
    estimated_grams: number | null;
    calories_estimate: number | null;
    protein_estimate: number | null;
    carbs_estimate: number | null;
    fat_estimate: number | null;
}

interface ValidatedMealResponse {
    mealTitle: string;
    servingContainer: string;
    items: ValidatedMealItem[];
}

interface NormalizedFood {
    name: string;
    nutritionPer100g: Record<string, number>;
    servingOptions: {
        label: string;
        grams: number;
    }[];
    source: 'usda' | 'off' | 'unavailable';
    fdcId?: string;
    error?: string;
}

type ClientMealResponse = Record<string, unknown>;

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

function toNullableNumber(value: unknown): number | null {
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

function safeString(value: unknown, fallback = ''): string {
    return typeof value === 'string' && value.trim().length > 0 ? value.trim() : fallback;
}

function isGenericFoodName(value: string): boolean {
    return GENERIC_FOOD_NAMES.has(value.trim().toLowerCase());
}

function normalizeNutritionQuery(query: string): string {
    let normalized = query.toLowerCase().trim();
    normalized = normalized.replace(/[^a-z0-9\s]/g, ' ');
    normalized = normalized.replace(/\s+/g, ' ').trim();

    for (const [source, replacement] of Object.entries(QUERY_NORMALIZATION_MAP)) {
        normalized = normalized.replace(new RegExp(`\\b${source}\\b`, 'g'), replacement);
    }

    return normalized.replace(/\s+/g, ' ').trim();
}

function isInvalidNutritionQuery(query: string): boolean {
    if (!query) {
        return true;
    }

    return isGenericFoodName(query);
}

function getCachedNutrition(query: string): NormalizedFood | null {
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

function setCachedNutrition(query: string, value: NormalizedFood): void {
    nutritionCache.set(query, {
        expiresAt: Date.now() + NUTRITION_CACHE_TTL_MS,
        value,
    });
}

function getCachedMeal(hash: string): ClientMealResponse | null {
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

function setCachedMeal(hash: string, value: ClientMealResponse): void {
    mealCache.set(hash, {
        expiresAt: Date.now() + MEAL_CACHE_TTL_MS,
        value,
    });
}

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function isGeminiRateLimitError(error: unknown): boolean {
    if (typeof error === 'object' && error !== null) {
        const status = (error as { status?: unknown; code?: unknown }).status
            ?? (error as { status?: unknown; code?: unknown }).code;
        if (status === 429 || status === '429') {
            return true;
        }
    }

    const message = error instanceof Error ? error.message : String(error ?? '');
    return message.includes('429') || message.toLowerCase().includes('too many requests');
}

async function callGeminiWithRetry(
    model: { generateContent: (...args: any[]) => Promise<any> },
    input: any,
    retries = 3,
): Promise<any> {
    for (let attempt = 0; attempt <= retries; attempt += 1) {
        try {
            return await model.generateContent(input);
        } catch (error) {
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

function buildUnavailableNutrition(query: string, reason: string): NormalizedFood {
    return {
        name: query,
        nutritionPer100g: {},
        servingOptions: [],
        source: 'unavailable',
        error: reason,
    };
}

function normalizeUSDAResponse(food: any): NormalizedFood {
    const nutrients = food.foodNutrients || food.nutrients || [];

    const findNutrient = (nameOrId: string | number) => {
        return nutrients.find((nutrient: any) =>
            nutrient.nutrientId === nameOrId ||
            nutrient.nutrientNumber === nameOrId ||
            (nutrient.nutrient && (nutrient.nutrient.id === nameOrId || nutrient.nutrient.number === nameOrId)) ||
            (nutrient.name && nutrient.name.toLowerCase().includes(nameOrId.toString().toLowerCase())) ||
            (nutrient.nutrient?.name && nutrient.nutrient.name.toLowerCase().includes(nameOrId.toString().toLowerCase()))
        );
    };

    const getNutrientValue = (id: number, alias?: string) => {
        const nutrient = findNutrient(id) || (alias ? findNutrient(alias) : null);
        return toNumber(nutrient?.amount ?? nutrient?.value);
    };

    let calories = getNutrientValue(1008, 'energy');
    if (calories === 0) calories = getNutrientValue(208, 'kcal');

    const servingOptions: { label: string; grams: number }[] = [{ label: '100g', grams: 100 }];
    if (Array.isArray(food.foodPortions)) {
        for (const portion of food.foodPortions) {
            const grams = toNumber(portion?.gramWeight);
            if (grams <= 0) continue;

            const label = safeString(
                portion?.modifier ??
                portion?.portionDescription ??
                `${portion?.amount ?? ''} ${portion?.measureUnit?.name ?? 'serving'}`,
                'Custom serving'
            );

            servingOptions.push({ label, grams });
        }
    }

    return {
        name: safeString(food.description ?? food.lowercaseDescription, 'Unknown Food'),
        nutritionPer100g: {
            calories,
            protein: getNutrientValue(1003, 'protein'),
            carbs: getNutrientValue(1005, 'carbohydrate'),
            fat: getNutrientValue(1004, 'fat'),
        },
        servingOptions,
        source: 'usda',
        fdcId: food.fdcId ? String(food.fdcId) : undefined,
    };
}

function normalizeOFFResponse(product: any, query: string): NormalizedFood {
    const nutriments = product.nutriments || {};
    const servingQuantity = toNumber(product.serving_quantity);

    const calories = toNullableNumber(nutriments['energy-kcal_100g'] ?? nutriments.energy_kcal_100g);
    const protein = toNullableNumber(nutriments.proteins_100g);
    const carbs = toNullableNumber(nutriments.carbohydrates_100g);
    const fat = toNullableNumber(nutriments.fat_100g);

    const nutritionPer100g: Record<string, number> = {};
    if (calories !== null) nutritionPer100g.calories = calories;
    if (protein !== null) nutritionPer100g.protein = protein;
    if (carbs !== null) nutritionPer100g.carbs = carbs;
    if (fat !== null) nutritionPer100g.fat = fat;

    return {
        name: safeString(product.product_name ?? product.product_name_en, query),
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

async function fetchFoodFromUSDA(query: string): Promise<NormalizedFood | null> {
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
        logger.info('Searching USDA', { query, normalizedQuery });
        const searchResponse = await axios.post(
            `${USDA_SEARCH_URL}?api_key=${apiKey}`,
            {
                query: normalizedQuery,
                pageSize: 5,
                dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
            },
            { timeout: 10000 }
        );

        const foods = searchResponse.data.foods;
        if (!Array.isArray(foods) || foods.length === 0) {
            logger.warn('USDA returned no matches', { normalizedQuery });
            return null;
        }

        const firstMatch = foods[0];
        const fdcId = firstMatch.fdcId;
        const detailsResponse = await axios.get(
            `${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`,
            { timeout: 10000 }
        );

        const normalized = normalizeUSDAResponse(detailsResponse.data);
        setCachedNutrition(`usda:${normalizedQuery}`, normalized);
        return normalized;
    } catch (error) {
        logger.error('fetchFoodFromUSDA error', { query, normalizedQuery, error });
        return null;
    }
}

async function fetchFoodFromOFF(query: string): Promise<NormalizedFood | null> {
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
        const response = await axios.get(OPEN_FOOD_FACTS_SEARCH_URL, {
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
        const product = products.find((candidate: any) => {
            const nutriments = candidate?.nutriments || {};
            return toNullableNumber(nutriments['energy-kcal_100g'] ?? nutriments.energy_kcal_100g) !== null;
        });

        if (!product) {
            logger.warn('OpenFoodFacts returned no nutritionally usable matches', { normalizedQuery });
            return null;
        }

        const normalized = normalizeOFFResponse(product, query);
        setCachedNutrition(`off:${normalizedQuery}`, normalized);
        return normalized;
    } catch (error) {
        logger.error('fetchFoodFromOFF error', { query, normalizedQuery, error });
        return null;
    }
}

function buildErrorMealResponse(error: string, mealTitle = 'Unable to detect meal'): ClientMealResponse {
    return {
        meal_title: mealTitle,
        serving_container: 'plate',
        items: [],
        error,
    };
}

function validateAndNormalizeMealResponse(parsed: unknown): ValidatedMealResponse | null {
    if (!parsed || typeof parsed !== 'object') {
        return null;
    }

    const data = parsed as Record<string, unknown>;
    const itemsRaw = Array.isArray(data.items)
        ? data.items
        : Array.isArray(data.ingredients)
        ? data.ingredients
        : [];

    if (itemsRaw.length === 0) {
        return null;
    }

    const items: ValidatedMealItem[] = [];
    for (const rawItem of itemsRaw) {
        if (!rawItem || typeof rawItem !== 'object') {
            continue;
        }

        const item = rawItem as GeminiMealItem;
        const ingredient = safeString(item.name ?? item.ingredient, '');
        if (!ingredient || isGenericFoodName(ingredient)) {
            continue;
        }

        const quantity = toNullableNumber(item.quantity);
        const servingSize = safeString(item.servingSize ?? item.serving_size, 'serving');
        const estimatedAmount = safeString(item.estimated_amount ?? item.amount)
            || (quantity !== null
                ? `${quantity} ${servingSize}`
                : servingSize || '1 serving');

        items.push({
            ingredient,
            estimated_amount: estimatedAmount,
            serving_size: servingSize || 'serving',
            estimated_grams: toNullableNumber(item.estimated_grams ?? item.estimatedGrams),
            calories_estimate: toNullableNumber(item.calories ?? item.calories_estimate),
            protein_estimate: toNullableNumber(item.protein ?? item.protein_estimate),
            carbs_estimate: toNullableNumber(item.carbs ?? item.carbs_estimate),
            fat_estimate: toNullableNumber(item.fat ?? item.fat_estimate),
        });
    }

    if (items.length === 0) {
        return null;
    }

    const detectedTitle = safeString(data.mealName ?? data.meal_title, '');
    return {
        mealTitle: detectedTitle && !isGenericFoodName(detectedTitle)
            ? detectedTitle
            : items.map((item) => item.ingredient).slice(0, 3).join(', '),
        servingContainer: safeString(data.serving_container ?? data.servingContainer, 'plate').toLowerCase(),
        items,
    };
}

function toClientMealResponse(validated: ValidatedMealResponse, error?: string): ClientMealResponse {
    return {
        meal_title: validated.mealTitle,
        serving_container: validated.servingContainer,
        items: validated.items,
        ...(error ? { error } : {}),
    };
}

function extractJsonPayload(responseText: string): string {
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

export const searchFoodUSDA = onRequest({ region: REGION, secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        const query = safeString(req.body?.query ?? req.query.query, '');
        const normalizedQuery = normalizeNutritionQuery(query);
        if (isInvalidNutritionQuery(normalizedQuery)) {
            res.send([]);
            return;
        }

        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios.post(
                `${USDA_SEARCH_URL}?api_key=${apiKey}`,
                {
                    query: normalizedQuery,
                    pageSize: 20,
                    dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
                },
                { timeout: 10000 }
            );
            res.send(response.data.foods || []);
        } catch (error) {
            logger.error('searchFoodUSDA error', { error, query, normalizedQuery });
            res.status(500).send({ error: 'Search failed.' });
        }
    });
});

export const getFoodDetailsUSDA = onRequest({ region: REGION, secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        const fdcId = req.body?.fdcId || req.query.fdcId;
        if (!fdcId) {
            res.status(400).send({ error: 'FDC ID is required.' });
            return;
        }

        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios.get(`${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`, { timeout: 10000 });
            res.send(normalizeUSDAResponse(response.data));
        } catch (error) {
            logger.error('getFoodDetailsUSDA error', { error, fdcId });
            res.status(500).send({ error: 'Details failed.' });
        }
    });
});

export const recognizeMealImage = onCall<RecognizeMealImageRequest>(callableOptions, async (request) => {
    const imageB64 = request.data?.imageB64?.trim();
    if (!imageB64) {
        throw new HttpsError('invalid-argument', 'imageB64 is required.');
    }
    if (imageB64.length > 10_000_000) {
        throw new HttpsError('invalid-argument', 'imageB64 exceeds the 10 MB limit.');
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
        throw new HttpsError('resource-exhausted', 'Too many requests. Please wait.');
    }
    lastRequestTime = now;

    const geminiKey = GEMINI_API_KEY.value();
    if (!geminiKey) {
        logger.error('Gemini API key is not configured');
        return buildErrorMealResponse('Gemini API key is not configured.');
    }

    const requestPromise = (async (): Promise<ClientMealResponse> => {
        const genAI = new GoogleGenerativeAI(geminiKey);
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
                const parsed = JSON.parse(cleanedText) as unknown;
                logger.info('GEMINI PARSED JSON', { attempt, requestId, parsed });

                const validated = validateAndNormalizeMealResponse(parsed);
                if (validated && validated.items.length > 0) {
                    const response = toClientMealResponse(validated);
                    setCachedMeal(hash, response);
                    return response;
                }
            } catch (parseError) {
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

export const enrichMealItem = onCall<{ ingredient: string }>(callableOptions, async (request) => {
    const query = request.data?.ingredient;
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

    const FOOD_MAP: Record<string, string> = {
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
    const unavailable = buildUnavailableNutrition(
        trimmedQuery,
        'Nutrition unavailable from USDA and OpenFoodFacts.'
    );
    return unavailable;
});
