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

const callableOptions = {
    region: REGION,
    invoker: 'public' as const,
    secrets: [GEMINI_API_KEY, USDA_API_KEY],
};

interface RecognizeMealImageRequest {
    imageB64?: string;
}

interface NormalizedFood {
    name: string;
    nutritionPer100g: Record<string, number>;
    servingOptions: {
        label: string;
        grams: number;
    }[];
    source: 'usda' | 'off';
    fdcId?: string;
}

interface GeminiMealItem {
    ingredient?: string;
    name?: string;
    estimated_amount?: string;
    amount?: string;
    serving_size?: string;
    servingSize?: string;
    calories_estimate?: number;
    calories?: number;
    protein_estimate?: number;
    protein?: number;
    carbs_estimate?: number;
    carbs?: number;
    fat_estimate?: number;
    fat?: number;
    estimated_grams?: number;
    estimatedGrams?: number;
    quantity?: number;
}

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

function safeString(value: unknown, fallback = ''): string {
    return typeof value === 'string' && value.trim().length > 0 ? value.trim() : fallback;
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

    const servingOptions: { label: string; grams: number }[] = [
        { label: '100g', grams: 100 },
    ];

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

function normalizeOFFResponse(product: any): NormalizedFood {
    const nutriments = product.nutriments || {};
    const servingQuantity = toNumber(product.serving_quantity);

    return {
        name: safeString(product.product_name ?? product.product_name_en, 'Unknown Food'),
        nutritionPer100g: {
            calories: toNumber(nutriments['energy-kcal_100g'] ?? nutriments.energy_kcal_100g),
            protein: toNumber(nutriments.proteins_100g),
            carbs: toNumber(nutriments.carbohydrates_100g),
            fat: toNumber(nutriments.fat_100g),
        },
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
    const apiKey = USDA_API_KEY.value();
    if (!apiKey) {
        logger.error('USDA_API_KEY is missing');
        return null;
    }

    try {
        logger.info('Searching USDA', { query });
        const searchResponse = await axios.post(
            `${USDA_SEARCH_URL}?api_key=${apiKey}`,
            {
                query,
                pageSize: 1,
                dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
            },
            { timeout: 10000 }
        );

        const foods = searchResponse.data.foods;
        if (!Array.isArray(foods) || foods.length === 0) {
            logger.warn('USDA returned no matches', { query });
            return null;
        }

        const fdcId = foods[0].fdcId;
        const detailsResponse = await axios.get(
            `${USDA_DETAILS_URL}/${fdcId}?api_key=${apiKey}`,
            { timeout: 10000 }
        );

        return normalizeUSDAResponse(detailsResponse.data);
    } catch (error) {
        logger.error('fetchFoodFromUSDA error', { query, error });
        return null;
    }
}

async function fetchFoodFromOFF(query: string): Promise<NormalizedFood | null> {
    try {
        const url = `https://in.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(query)}&search_simple=1&action=process&json=1&page_size=1`;
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Physiq/1.0 (support@physiq.app)' },
            timeout: 10000,
        });

        const products = response.data.products;
        if (!Array.isArray(products) || products.length === 0) {
            return null;
        }

        return normalizeOFFResponse(products[0]);
    } catch (error) {
        logger.error('fetchFoodFromOFF error', { query, error });
        return null;
    }
}

export const searchFoodUSDA = onRequest({ region: REGION, secrets: [USDA_API_KEY] }, async (req, res) => {
    return corsHandler(req, res, async () => {
        const query = req.body?.query || req.query.query;
        if (!query) {
            res.status(400).send({ error: 'Query is required.' });
            return;
        }

        try {
            const apiKey = USDA_API_KEY.value();
            const response = await axios.post(
                `${USDA_SEARCH_URL}?api_key=${apiKey}`,
                {
                    query,
                    pageSize: 20,
                    dataType: ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
                },
                { timeout: 10000 }
            );
            res.send(response.data.foods || []);
        } catch (error) {
            logger.error('searchFoodUSDA error', { error, query });
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

const GEMINI_MEAL_PROMPT = `You are a professional nutritionist and food recognition expert.
Analyze the given meal image carefully.

Return ONLY valid JSON in this exact format:
{
  "mealName": "string",
  "items": [
    {
      "name": "string",
      "quantity": 1,
      "servingSize": "string",
      "estimatedGrams": 100
    }
  ]
}

Rules:
- No markdown
- No explanation
- No extra text
- Detect all visible items
- Use specific food names (e.g., "apple", "chicken breast", "white rice") - never generic words like food, meal, dish, item, or food item.
- If you cannot identify a specific item, use the most specific category possible (e.g., "fruit", "meat", "grain") but avoid the aforementioned generic terms.
- Estimate the quantity and serving size based on the image.
- estimatedGrams should be the estimated weight in grams for one serving.`;

function buildFallbackMealResponse(): Record<string, unknown> {
    return {
        meal_title: 'Scanned Meal',
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
                estimated_grams: 100,
            },
        ],
    };
}

function isGenericFoodName(value: string): boolean {
    const normalized = value.trim().toLowerCase();
    return normalized === 'food' || normalized === 'meal' || normalized === 'dish' || normalized === 'item' || normalized === 'food item';
}

function validateAndNormalizeMealResponse(parsed: unknown): Record<string, unknown> {
    if (!parsed || typeof parsed !== 'object') {
        logger.warn('Gemini response was not a JSON object');
        return buildFallbackMealResponse();
    }

    const data = parsed as Record<string, unknown>;
    const itemsRaw = Array.isArray(data.items)
        ? data.items
        : Array.isArray(data.ingredients)
        ? data.ingredients
        : [];

    if (itemsRaw.length === 0) {
        logger.warn('Gemini returned no items');
        return buildFallbackMealResponse();
    }

    const validatedItems: Record<string, unknown>[] = [];
    for (const rawItem of itemsRaw) {
        if (!rawItem || typeof rawItem !== 'object') {
            continue;
        }

        const item = rawItem as GeminiMealItem;
        const ingredientName = safeString(item.name ?? item.ingredient, '');
        if (!ingredientName || isGenericFoodName(ingredientName)) {
            continue;
        }

        const quantity = toNumber(item.quantity);
        const servingLabel = safeString(item.servingSize ?? item.serving_size, '');
        const estimatedGrams = toNumber(item.estimated_grams ?? item.estimatedGrams);
        const estimatedAmount = safeString(item.estimated_amount ?? item.amount)
            || (quantity > 0
                ? `${quantity} ${servingLabel || (quantity === 1 ? 'serving' : 'servings')}`
                : servingLabel || '1 serving');

        validatedItems.push({
            ingredient: ingredientName,
            estimated_amount: estimatedAmount,
            serving_size: servingLabel || (estimatedGrams > 0 ? `${estimatedGrams}g` : '100g'),
            calories_estimate: toNumber(item.calories ?? item.calories_estimate) || 100,
            protein_estimate: toNumber(item.protein ?? item.protein_estimate) || 3,
            carbs_estimate: toNumber(item.carbs ?? item.carbs_estimate) || 15,
            fat_estimate: toNumber(item.fat ?? item.fat_estimate) || 3,
            estimated_grams: estimatedGrams || 100,
        });
    }

    if (validatedItems.length === 0) {
        logger.warn('Gemini items were unusable after validation');
        return buildFallbackMealResponse();
    }

    const detectedTitle = safeString(data.mealName ?? data.meal_title, '');
    const mealTitle = detectedTitle && !isGenericFoodName(detectedTitle)
        ? detectedTitle
        : validatedItems.map((item) => String(item.ingredient)).slice(0, 3).join(', ') || 'Scanned Meal';

    return {
        meal_title: mealTitle,
        serving_container: safeString(data.serving_container ?? data.servingContainer, 'plate').toLowerCase(),
        items: validatedItems,
    };
}

export const recognizeMealImage = onCall<RecognizeMealImageRequest>(callableOptions, async (request) => {
    const imageB64 = request.data?.imageB64?.trim();
    if (!imageB64) {
        throw new HttpsError('invalid-argument', 'imageB64 is required.');
    }
    if (imageB64.length > 10_000_000) {
        throw new HttpsError('invalid-argument', 'imageB64 exceeds the 10 MB limit.');
    }

    const geminiKey = GEMINI_API_KEY.value();
    if (!geminiKey) {
        logger.error('Gemini API key is not configured');
        return buildFallbackMealResponse();
    }

    try {
        const genAI = new GoogleGenerativeAI(geminiKey);
        const model = genAI.getGenerativeModel({
            model: 'gemini-3-flash',
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
        logger.info('RAW GEMINI RESPONSE', { responseText });

        let cleanedText = responseText.trim()
            .replace(/```json/gi, '')
            .replace(/```/g, '')
            .trim();

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
                cleanedText: cleanedText.substring(0, 1000),
            });
            return buildFallbackMealResponse();
        }

        const validated = validateAndNormalizeMealResponse(parsed);
        logger.info('recognizeMealImage finalized', {
            mealTitle: validated.meal_title,
            itemCount: Array.isArray(validated.items) ? validated.items.length : 0,
        });
        return validated;
    } catch (error) {
        logger.error('recognizeMealImage failed', {
            error: error instanceof Error ? error.message : error,
            stack: error instanceof Error ? error.stack : undefined,
        });
        return buildFallbackMealResponse();
    }
});

export const enrichMealItem = onCall<{ ingredient: string }>(callableOptions, async (request) => {
    const query = request.data?.ingredient?.trim();
    if (!query) {
        throw new HttpsError('invalid-argument', 'ingredient is required.');
    }

    logger.info('enrichMealItem request', { query });

    let nutritionData = await fetchFoodFromUSDA(query);
    if (!nutritionData) {
        logger.info('USDA failed, trying OpenFoodFacts', { query });
        nutritionData = await fetchFoodFromOFF(query);
    }

    if (nutritionData) {
        logger.info('enrichMealItem success', { query, source: nutritionData.source });
        return nutritionData;
    }

    logger.warn('No enrichment found', { query });
    return null;
});
