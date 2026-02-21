# Physiq: FatSecret Integration & Data Flow

This document explains the end-to-end data flow for the food search and image recognition features in the Physiq app. It details how the Flutter frontend communicates with the Firebase backend and the FatSecret API.

## 1. High-Level Architecture

The application uses a **Serverless Proxy** architecture. The Flutter app never communicates with FatSecret directly. Instead, it calls Firebase Cloud Functions, which securely handle authentication and API requests to FatSecret.

**Flow:**
`Flutter App`  <-->  `Firebase Cloud Functions`  <-->  `FatSecret API`

---

## 2. Food Search Flow
**Scenario:** User types "apple" in the `FoodDatabaseScreen`.

### Step 1: Frontend - UI Layer
- **File:** `lib/screens/food/food_database_screen.dart` (or `meal/food_database_screen.dart`)
- **Action:** User enters text into the search bar.
- **Code:** The UI calls `FoodService.searchFoods("apple")`.

### Step 2: Frontend - Service Layer
- **File:** `lib/services/food_service.dart`
- **Method:** `searchFoods(String query)`
- **Authentication:** 
  1. Calls `_ensureAuthenticatedUser()` to check if the user is logged in (Firebase Auth).
  2. If the user is anonymous or authenticated, it proceeds.
- **Cloud Call:** Executes `_functions.httpsCallable('searchFood')` with the payload `{'query': 'apple', 'region': 'US'}`.

### Step 3: Backend - Cloud Function
- **File:** `functions/src/nutrition.ts`
- **Export:** `searchFood`
- **Logic:**
  1. Receives the `query` from the app.
  2. Calls `callFatSecretGet` with the URL `FATSECRET_SEARCH_V4_URL`.
  3. **OAuth Token:** Calls `getAccessToken()` to retrieve a valid OAuth 2.0 token from FatSecret (using Client Credentials flow).
  4. **API Request:** Sends a GET request to FatSecret: `https://platform.fatsecret.com/rest/foods/search/v4`.
  5. **Response:** Parses the JSON response from FatSecret and returns a cleaned-up list of foods to the app.

### Step 4: Frontend - Response Handling
- **File:** `lib/services/food_service.dart`
- **Method:** `_extractFoodsFromResponse`
- **Logic:**
  1. Receives the JSON result from the Cloud Function.
  2. Maps the raw JSON into `Food` objects using `_mapSearchFood`.
  3. Returns `List<Food>` to the UI for display.

---

## 3. Image Recognition (Snap Meal) Flow
**Scenario:** User takes a photo in `SnapMealScreen`.

### Step 1: Frontend - UI Layer
- **File:** `lib/screens/meal/snap_meal_screen.dart`
- **Action:** User taps the shutter button (`_onSnap`).
- **Code:** Captures the image, reads bytes, and calls `_foodService.recognizeMealFromImageBytes(bytes)`.

### Step 2: Frontend - Service Layer
- **File:** `lib/services/food_service.dart`
- **Method:** `recognizeMealFromImageBytes(Uint8List imageBytes)`
- **Logic:**
  1. Converts image bytes to a Base64 string.
  2. Calls the Cloud Function: `_functions.httpsCallable('recognizeMealImage')` with payload `{'imageB64': '...', 'includeFoodData': true}`.

### Step 3: Backend - Cloud Function
- **File:** `functions/src/nutrition.ts`
- **Export:** `recognizeMealImage`
- **Logic:**
  1. **Validation:** Checks if image size is under the limit (approx 1MB).
  2. **OAuth:** Gets an access token with scope `image-recognition`.
  3. **API Request:** Post data to `https://platform.fatsecret.com/rest/image-recognition/v2`.
  4. **Processing:** Calls FatSecret's AI to analyze the image.
  5. **Response:** Returns identified foods and nutritional estimates.

### Step 4: Frontend - Result Display
- **File:** `lib/screens/meal/meal_preview_screen.dart`
- **Logic:**
  1. `FoodService` parses the result into `MealRecognitionResult`.
  2. The app navigates to `MealPreviewScreen` with the detected food and nutrition data pre-filled.

---

## 4. Key Files & Roles

| Component | File Path | Role |
|-----------|-----------|------|
| **UI (Camera)** | `lib/screens/meal/snap_meal_screen.dart` | Handles camera, gallery picking, and initiates scanning. |
| **UI (Search)** | `lib/screens/food/meal_food_search.dart` | Search bar UI and results list. |
| **Service** | `lib/services/food_service.dart` | The **Bridge**. Handles Firebase Auth and calls Cloud Functions. Maps JSON to Dart models. |
| **Data Model** | `lib/models/food_model.dart` | Defines the `Food` object structure used throughout the app. |
| **Backend** | `functions/src/nutrition.ts` | The **Brain**. Securely holds API keys. Managing OAuth tokens. Communicates with FatSecret. |

## 5. Troubleshooting Common Issues

### "Unauthenticated" Error
- **Cause:** The app tried to call a Cloud Function before Firebase Auth completed initialization.
- **Fix:** `FoodService` automatically retries the call if it detects an auth error.

### "Internal" Error / No Results
- **Cause:** 
    1. FatSecret API keys in Google Cloud Secret Manager are invalid.
    2. FatSecret API rate limit reached.
    3. IP address blocked by FatSecret (requires Premier plan whitelisting).
- **Debugging:** Check the **Google Cloud Console > Cloud Functions > Logs** for the `fatsecret-nutrition` or `searchFood` function. The logs (which we recently improved) will show the exact error from FatSecret.
