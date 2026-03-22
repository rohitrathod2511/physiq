# Physiq Snap Meal Backend

## What was broken

The Snap Meal backend had multiple production issues:

- Legacy FatSecret code still existed in the project and could be called by stale builds.
- Gemini responses could include generic names or invalid JSON.
- Gemini requests could burst fast enough to trigger `429 Too Many Requests`.
- The Gemini prompt was longer than necessary and increased token usage.
- Repeated scans of the same image were not cached or deduplicated.
- Generic Gemini items were converted into fake fallback rows like `Food item` with static nutrition.
- USDA requests were using poor or generic queries such as `food` or `meal`.
- OpenFoodFacts fallback was not optimized for Indian food coverage.
- Logs did not clearly show raw Gemini output, cleaned JSON, and parsed payloads.
- Failed enrichment paths could silently degrade into fake calorie values.

## What was fixed

### 1. FatSecret removed completely

- Removed all FatSecret backend logic, endpoints, auth flow, and helper files.
- Removed all app-side FatSecret models and services.
- Reworked `DescribeMealScreen` to use the existing `FoodService` instead of any FatSecret-specific flow.
- Rebuilt Firebase Functions so `functions/lib/nutrition.js` no longer contains FatSecret code.

### 2. Gemini detection hardened

- Switched the model to `gemini-3.1-flash-lite-preview`.
- Kept `temperature: 0.1` and `responseMimeType: application/json`.
- Replaced the prompt with a shorter JSON-only prompt to reduce token usage.
- Added one retry pass if Gemini returns invalid JSON or only generic items.

### 3. Gemini rate-limit protection added

- Added an in-memory throttle so new Gemini requests on the same function instance cannot run more than once every 3 seconds.
- Added exponential backoff for Gemini `429` responses with delays of `1s`, `2s`, and `4s`.
- Added in-memory meal response caching so repeated scans of the same image reuse the cached Gemini result.
- Added in-flight request deduplication so duplicate frontend calls for the same image join the active promise instead of opening a second Gemini request.

### 4. Validation logic fixed

- Generic names like `food`, `meal`, and `item` are discarded.
- No static fake fallback nutrition is generated anymore.
- If Gemini still fails after retry, the function returns a structured error response with an empty `items` array.

### 5. USDA and OFF enrichment improved

- Added query normalization for:
  - `roti` -> `whole wheat bread`
  - `chapati` -> `whole wheat bread`
  - `paneer` -> `cottage cheese`
  - `dal` -> `lentils`
  - `sabzi` -> `vegetable curry`
- Generic queries are rejected before USDA/OFF lookup.
- USDA remains the primary nutrition source.
- OpenFoodFacts India (`https://in.openfoodfacts.org`) is used only as fallback.
- OFF now looks at 5 results and picks the first product with valid calorie data.
- If both providers fail, the backend returns `source: unavailable` and an error message instead of fake nutrition.

### 6. Production logging added

The backend now logs:

- `GEMINI RAW RESPONSE`
- `GEMINI CLEANED TEXT`
- `GEMINI PARSED JSON`
- `Gemini 429 error, retrying...`
- USDA lookup attempts
- OpenFoodFacts fallback attempts
- Enrichment failures and unavailable nutrition responses

### 7. Fresh backend build completed

- Ran `npm.cmd run build` in `functions/`.
- This refreshed the deployable functions bundle from the new TypeScript source.

## How the system works now

1. The client sends the image to `recognizeMealImage`.
2. The backend first checks meal cache and active in-flight requests for the same image.
3. New Gemini calls are throttled to reduce burst traffic and `429` errors.
4. Gemini returns strict JSON only.
5. The backend cleans and parses the response.
6. If Gemini returns `429`, exponential backoff retries the same request.
7. Generic items are removed.
8. If the first Gemini response is unusable, the backend retries once with a stricter retry prompt.
9. Valid item names are sent to `enrichMealItem` one by one.
10. `enrichMealItem` normalizes the query and tries USDA first.
11. If USDA fails, it falls back to OpenFoodFacts India.
12. If both fail, the backend returns an unavailable-nutrition object instead of fake calories.

## 429 handling

- `recognizeMealImage` rejects new uncached requests that arrive within 3 seconds on the same function instance.
- `callGeminiWithRetry()` retries Gemini `429` failures up to 3 times with exponential backoff.
- Same-image requests are cached in memory for 10 minutes.
- Same-image duplicate requests reuse the active promise while the first request is still running.

## How retry works

- Attempt 1 runs immediately.
- If Gemini returns `429`, the backend waits `1s` and retries.
- The second `429` waits `2s`.
- The third `429` waits `4s`.
- If Gemini still fails, the backend returns a structured error response and no fake nutrition data.

## How caching works

- Meal detection cache key: first 100 characters of `imageB64`.
- Cache TTL: 10 minutes for Gemini meal detection.
- Nutrition lookup cache TTL: 15 minutes for USDA and OpenFoodFacts responses.
- In-flight dedupe prevents duplicate Gemini requests while the first identical image is still processing.

## Environment variables / secrets

Set these Firebase Function secrets before deploy:

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set USDA_API_KEY
```

## Deploy steps

From `functions/`:

```bash
npm run build
```

From the repo root:

```bash
firebase deploy --only functions
```

## Debug checklist

Use this checklist if Snap Meal still behaves unexpectedly:

- Confirm `GEMINI_API_KEY` is set in Firebase secrets.
- Confirm `USDA_API_KEY` is set in Firebase secrets.
- Run `npm run build` inside `functions/` before deploy.
- Deploy with `firebase deploy --only functions`.
- Check Firebase logs for:
  - `GEMINI RAW RESPONSE`
  - `GEMINI CLEANED TEXT`
  - `GEMINI PARSED JSON`
  - `Gemini 429 error, retrying...`
  - `Searching USDA`
  - `USDA failed, trying OpenFoodFacts`
- Verify Gemini is returning specific food names, not generic placeholders.
- Verify enrichment responses are `usda`, `off`, or `unavailable` — never fake nutrition rows.

## Future improvements

- Add persistent cache storage in Firestore or Redis for repeated food lookups.
- Replace per-instance rate limiting with a distributed rate limiter for multi-instance scale.
- Add confidence scoring per Gemini item.
- Add stronger Indian-food synonym expansion beyond roti/paneer/dal/sabzi.
- Add ranking logic for USDA result selection instead of always using the first match.
- Add backend integration tests for Gemini parsing and enrichment fallbacks.
