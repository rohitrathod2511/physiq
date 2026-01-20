"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.estimateNutrition = void 0;
const https_1 = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const firebase_functions_1 = require("firebase-functions");
const admin = require("firebase-admin");
const node_fetch_1 = require("node-fetch");
// Ensure admin is initialized (idempotent check)
if (admin.apps.length === 0) {
    admin.initializeApp();
}
(0, firebase_functions_1.setGlobalOptions)({ maxInstances: 10, timeoutSeconds: 60 });
exports.estimateNutrition = (0, https_1.onRequest)({ cors: true }, async (req, res) => {
    var _a, _b, _c, _d, _e;
    try {
        // 1. Validate Method
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }
        // 2. Validate Body
        const { type, input, image, mimeType } = req.body || {};
        logger.info("Request received", {
            type,
            hasInput: !!input,
            hasImage: !!image,
            mimeType,
        });
        let prompt = "";
        let imagePart = undefined;
        // Strict JSON schema prompt
        const jsonInstruction = `
Return ONLY a valid JSON object with exactly these keys:
{
  "meal_name": "string",
  "calories": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number
}
IMPORTANT: Return ONLY valid JSON. No markdown. No extra text. No backticks.
Do NOT wrap the response in \`\`\`json ... \`\`\`.
    `.trim();
        if (type === "text" && input) {
            prompt = `
Analyze this meal description: "${input}".
Estimate the nutrition facts.
${jsonInstruction}
      `.trim();
        }
        else if (type === "voice" && input) {
            prompt = `
Analyze this spoken meal description: "${input}".
Estimate the nutrition facts.
${jsonInstruction}
      `.trim();
        }
        else if (type === "image" && image) {
            prompt = `
Identify this food/meal from the image.
Estimate the nutrition facts.
${jsonInstruction}
      `.trim();
            // Vertex AI / Gemini inline data format
            imagePart = {
                inline_data: {
                    mime_type: mimeType || "image/jpeg",
                    data: image,
                },
            };
        }
        else {
            logger.warn("Invalid request body", req.body);
            res.status(400).send("Invalid input payload");
            return;
        }
        // 3. Auth (Service Account)
        const projectId = process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
        const location = "us-central1";
        const modelId = "gemini-1.5-flash";
        // Get Access Token
        const accessTokenObj = await admin.credential.applicationDefault().getAccessToken();
        const accessToken = accessTokenObj.access_token;
        // 4. Vertex AI Request
        const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${modelId}:generateContent`;
        logger.info("Using Vertex AI API", {
            model: modelId,
            projectId,
            url
        });
        const parts = imagePart ? [{ text: prompt }, imagePart] : [{ text: prompt }];
        const vertexBody = {
            contents: [{
                    role: "user",
                    parts: parts
                }],
            generationConfig: {
                temperature: 0.2,
                topK: 32,
                topP: 0.95,
                maxOutputTokens: 1024,
                responseMimeType: "application/json"
            }
        };
        const geminiRes = await (0, node_fetch_1.default)(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${accessToken}`
            },
            body: JSON.stringify(vertexBody),
        });
        if (!geminiRes.ok) {
            const errText = await geminiRes.text();
            logger.error("Vertex AI API Error", {
                status: geminiRes.status,
                body: errText,
            });
            res.status(500).send(errText);
            return;
        }
        const geminiData = await geminiRes.json();
        const aiText = (_e = (_d = (_c = (_b = (_a = geminiData === null || geminiData === void 0 ? void 0 : geminiData.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text;
        logger.info("Raw Vertex Response", { aiText });
        if (!aiText) {
            logger.error("Empty Vertex response", geminiData);
            res.status(500).send("AI returned empty response");
            return;
        }
        // 5. Parse JSON Safely
        let clean = aiText;
        clean = clean.replace(/```json/g, "").replace(/```/g, "").trim();
        const start = clean.indexOf("{");
        const end = clean.lastIndexOf("}");
        if (start !== -1 && end !== -1) {
            clean = clean.substring(start, end + 1);
        }
        let parsed;
        try {
            parsed = JSON.parse(clean);
        }
        catch (parseErr) {
            logger.error("JSON Parse Failed", {
                error: parseErr.message,
                raw: aiText,
                cleaned: clean
            });
            res.status(500).send("Failed to parse AI response");
            return;
        }
        res.json(parsed);
    }
    catch (err) {
        logger.error("Fatal Function Error", err);
        res.status(500).send("Internal Server Error");
    }
});
//# sourceMappingURL=nutrition.js.map