# Database-First Nutrition System - Ingestion Scripts

This folder contains scripts to populate your Firestore database with food data, enabling the new "Database-First" architecture.

## 1. Prerequisites
- Node.js (v18+)
- Firebase CLI installed (`npm install -g firebase-tools`)
- A Firebase Service Account Key (for local admin access)

### Setup Service Account
1. Go to Firebase Console > Project Settings > Service Accounts.
2. Click "Generate New Private Key".
3. Save the file as `physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json` inside the `functions/` directory (one level up from here).

## 2. Ingest Indian Foods (Task B)
This script uploads a curated list of top Indian foods from `indian_foods.json`.

```bash
cd functions/scripts
node ingest_indian.js
```

## 3. Ingest USDA Data (Task A)
This script fetches generic food data from the USDA API and uploads it to Firestore.

**Configuration:**
- Open `ingest_usda.js`.
- Replace `YOUR_API_KEY_HERE` with your actual USDA API Key.

**Run:**
```bash
cd functions/scripts
# If you need to install dependencies first:
# npm install axios firebase-admin
node ingest_usda.js
```

## 4. Firestore Schema Created
- **foods**: Collection of normalized food items (per 100g).
- **food_aliases**: Collection mapping search terms (e.g., "chapati") to food IDs.

## notes
- The scripts use `firebase-admin` to write directly to Firestore.
- Ensure your Firestore rules allow reads for authenticated users on these collections.
