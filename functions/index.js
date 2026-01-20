const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin (if not already initialized in another file, but safe to call here)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

setGlobalOptions({ maxInstances: 10, timeoutSeconds: 60 });

exports.estimateNutrition = onRequest({ cors: true }, async (req, res) => {
  try {
    // 1. Validate Method
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // 2. Validate Body
    const { type, input, image, mimeType } = req.body || {};

    logger.info("Request received", {
      type,
      hasInput: !!input,
      hasImage: !!image,
      mimeType,
    });

    let prompt;
    let imagePart;

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

      // Vertex AI format: inlineData
      imagePart = {
        inlineData: {
          mimeType: mimeType || "image/jpeg",
          data: image,
        },
      };
    } 
    else {
      logger.warn("Invalid request body", req.body);
      return res.status(400).send("Invalid input payload");
    }

    // 3. Get Access Token (Service Account)
    // No API ID required, automatic via Google Cloud IAM
    const accessToken = await admin.credential.applicationDefault().getAccessToken();
    const token = accessToken.access_token;

    // 4. Project ID
    const projectId = process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
    if (!projectId) {
         logger.error("Could not determine Project ID");
         return res.status(500).send("Server configuration error: Missing Project ID");
    }

    // 5. Vertex AI Request
    const model = "gemini-2.5-flash"; 
    const location = "us-central1"; 
    const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/publishers/google/models/${model}:generateContent`;

    const parts = [{ text: prompt }];
    if (imagePart) parts.push(imagePart);

    const payload = {
      contents: [{ role: "user", parts: parts }],
      generationConfig: {
        temperature: 0.2, // Lower temperature for more deterministic JSON
        maxOutputTokens: 1024,
      }
    };

    logger.info("Calling Vertex AI", { 
        model, 
        project: projectId,
        hasImage: !!imagePart 
    });

    // Use native fetch (Node 18+)
    const vertexRes = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify(payload),
    });

    if (!vertexRes.ok) {
      const errText = await vertexRes.text();
      logger.error("Vertex AI API Error", {
        status: vertexRes.status,
        body: errText,
      });
      return res.status(500).send(`Vertex AI Error: ${errText}`);
    }

    const vertexData = await vertexRes.json();
    const aiText = vertexData?.candidates?.[0]?.content?.parts?.[0]?.text;

    logger.info("Raw Vertex AI Response", { aiText });

    if (!aiText) {
      logger.error("Empty Vertex AI response", vertexData);
      return res.status(500).send("AI returned empty response");
    }

    // 6. Parse JSON Safely
    let clean = aiText;
    // Remove markdown code blocks if present
    clean = clean.replace(/```json/g, "").replace(/```/g, "").trim();
    
    // Find first '{' and last '}'
    const start = clean.indexOf("{");
    const end = clean.lastIndexOf("}");
    
    if (start !== -1 && end !== -1) {
      clean = clean.substring(start, end + 1);
    }

    let parsed;
    try {
      parsed = JSON.parse(clean);
    } catch (parseErr) {
      logger.error("JSON Parse Failed", { 
        error: parseErr.message, 
        raw: aiText, 
        cleaned: clean 
      });
      return res.status(500).send("Failed to parse AI response");
    }

    return res.json(parsed);

  } catch (err) {
    logger.error("Fatal Function Error", err);
    return res.status(500).send("Internal Server Error");
  }
});
