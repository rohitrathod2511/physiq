const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { setGlobalOptions } = require("firebase-functions");

// Optimize cold starts
setGlobalOptions({ maxInstances: 10 });

// The function is deployed to: https://<region>-<project-id>.cloudfunctions.net/estimateNutrition
exports.estimateNutrition = onRequest({ cors: true }, async (req, res) => {
  try {
    // 1. Validate Request
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const { prompt, image, mimeType } = req.body;
    if (!prompt) {
      res.status(400).send("Missing prompt");
      return;
    }

    // 2. Get API Key from Environment
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      logger.error("GEMINI_API_KEY is not set in environment.");
      res.status(500).send("Server Configuration Error: API Key missing");
      return;
    }

    // 3. Construct Gemini Payload
    const parts = [{ text: prompt }];

    // If image is provided in base64
    if (image) {
      parts.push({
        inline_data: {
          mime_type: mimeType || "image/jpeg",
          data: image
        }
      });
    }

    const payload = {
      contents: [{ parts }]
    };

    // 4. Call Gemini API
    const model = "gemini-1.5-flash";
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const response = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      logger.error("Gemini API Failed", { status: response.status, body: errorText });
      res.status(500).send(`AI Error: ${response.statusText}`);
      return;
    }

    const data = await response.json();

    // 5. Extract Text
    const candidates = data.candidates;
    if (!candidates || candidates.length === 0) {
      logger.error("No candidates in response", data);
      res.status(500).send("AI returned no results.");
      return;
    }

    const rawText = candidates[0].content?.parts?.[0]?.text;
    if (!rawText) {
      logger.error("No text in candidate", candidates[0]);
      res.status(500).send("AI returned empty text.");
      return;
    }

    // Return raw text (Flutter will parse)
    res.status(200).send(rawText);

  } catch (error) {
    logger.error("Internal Function Error", error);
    res.status(500).send("Internal Server Error");
  }
});
