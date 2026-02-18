const { onRequest, onCall } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const axios = require("axios");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}

setGlobalOptions({ maxInstances: 10, timeoutSeconds: 60 });

// Define Secure Environment Variables
const FATSECRET_CLIENT_ID = defineString("FATSECRET_CLIENT_ID");
const FATSECRET_CLIENT_SECRET = defineString("FATSECRET_CLIENT_SECRET");

// Helper to get OAuth Token
// Matches PHASE 2: Verify Token Generation
async function getAccessToken() {
    const clientId = FATSECRET_CLIENT_ID.value();
    const clientSecret = FATSECRET_CLIENT_SECRET.value();

    logger.info("Getting FatSecret Token...", { hasClientId: !!clientId, hasClientSecret: !!clientSecret });

    const params = new URLSearchParams();
    params.append('grant_type', 'client_credentials');
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);
    params.append('scope', 'basic');

    try {
        const response = await axios.post(
            "https://oauth.fatsecret.com/connect/token",
            params.toString(),
            {
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                }
            }
        );

        if (response.data && response.data.access_token) {
            logger.info("Token obtained successfully", { expiresIn: response.data.expires_in });
            return response.data.access_token;
        } else {
            logger.error("Token response missing access_token", response.data);
            throw new Error("No access_token in response");
        }
    } catch (error) {
        logger.error("Token Generation Failed", { 
            message: error.message, 
            response: error.data,
            status: error.status
        });
        throw error;
    }
}

// --- FATSECRET AUTHENTICATION TEST ENDPOINT ---
exports.getFatSecretToken = onRequest({ cors: true }, async (req, res) => {
  try {
    const token = await getAccessToken();
    res.json({ token, status: "success" });
  } catch (error) {
    res.status(500).send(`Token error: ${error.message}`);
  }
});

// --- SEARCH FOOD (Callable) ---
// invoker: "public" allows unauthenticated calls - food search uses public FatSecret data only
exports.searchFood = onCall({ invoker: "public" }, async (request) => {
  const query = request.data?.query;
  logger.info("searchFood called", { query });

  if (!query) {
      logger.error("Search query missing");
      throw new Error("Missing query");
  }

  try {
    // 1. Get Token
    const accessToken = await getAccessToken();
    logger.info("Using token for search", { tokenSnippet: accessToken.substring(0, 10) + "..." });

    // 2. Search API (v4 POST)
    const searchParams = new URLSearchParams();
    searchParams.append('method', 'foods.search');
    searchParams.append('search_expression', query);
    searchParams.append('format', 'json');
    searchParams.append('page_number', '0');
    searchParams.append('max_results', '20');

    logger.info("Calling FatSecret Search API (POST)...");
    const foodResponse = await axios.post(
      "https://platform.fatsecret.com/rest/server.api",
      searchParams.toString(),
      {
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/x-www-form-urlencoded"
        }
      }
    );

    logger.info("Search API Raw Response", JSON.stringify(foodResponse.data, null, 2));

    // 3. Parse Results
    const data = foodResponse.data;
    
    if (data.error) {
        logger.error("FatSecret API Error", data.error);
        throw new Error(data.error.message || "FatSecret API Error");
    }

    // Normalize 'foods.food' which can be undefined, object, or array
    let foodList = [];
    if (data.foods && data.foods.food) {
        foodList = Array.isArray(data.foods.food) ? data.foods.food : [data.foods.food];
    } else {
        logger.info("No foods found in response structure");
    }

    // Map to simplified structure
    const cleanedFoods = foodList.map(food => ({
      id: food.food_id,
      name: food.food_name,
      description: food.food_description,
      brand: food.brand_name,
      type: food.food_type
    }));

    logger.info("Returning cleaned foods", { count: cleanedFoods.length });
    return { 
        foods: { food: cleanedFoods },
        _debug_raw: data 
    };

  } catch (error) {
    logger.error("SearchFood Generic Error", {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status
    });
    // Return a structured error to the client instead of throwing if possible, or throw generic
    throw new Error(`Search error: ${error.message}`);
  }
});

// --- GET FOOD DETAILS (Callable) ---
// invoker: "public" allows unauthenticated calls - food details use public FatSecret data only
exports.getFoodDetails = onCall({ invoker: "public" }, async (request) => {
  const foodId = request.data?.foodId;
  logger.info("getFoodDetails called", { foodId });

  if (!foodId) {
      logger.error("Missing foodId");
      throw new Error("Missing foodId");
  }

  try {
    // 1. Get Token
    const accessToken = await getAccessToken();

    // 2. Get Details API (v4 POST)
    const detailParams = new URLSearchParams();
    detailParams.append('method', 'food.get.v4');
    detailParams.append('food_id', foodId);
    detailParams.append('format', 'json');

    logger.info("Calling FatSecret Details API (POST)...");
    const detailResponse = await axios.post(
      "https://platform.fatsecret.com/rest/server.api",
      detailParams.toString(),
      {
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/x-www-form-urlencoded"
        }
      }
    );

    logger.info("Food Details Raw Response", JSON.stringify(detailResponse.data, null, 2));

    const data = detailResponse.data;

    if (data.error) {
        logger.error("FatSecret API Error", data.error);
        throw new Error(data.error.message || "FatSecret API Error");
    }

    const foodData = data.food;

    if (!foodData) {
        logger.warn("Food details not found in response");
        throw new Error("Food not found");
    }

    // 3. Normalize Servings
    let servings = [];
    if (foodData.servings && foodData.servings.serving) {
        servings = Array.isArray(foodData.servings.serving) 
            ? foodData.servings.serving 
            : [foodData.servings.serving];
    }

    // 4. Clean Data
    const cleanFood = {
        food_id: foodData.food_id,
        food_name: foodData.food_name,
        brand_name: foodData.brand_name,
        food_type: foodData.food_type,
        servings: servings
    };

    logger.info("Returning cleaned food details", { id: cleanFood.food_id, servingsCount: servings.length });

    return { 
        food: cleanFood,
        _debug_raw: data
    };

  } catch (error) {
    logger.error("getFoodDetails Generic Error", {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status
    });
    throw new Error(`Details error: ${error.message}`);
  }
});
