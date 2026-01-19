import * as functions from 'firebase-functions';
// We use native fetch available in Node 18
// If you are on an older Node version, you might need 'node-fetch' or similar.
// But Firebase Functions Node 18 runtime supports global fetch.

export const estimateNutrition = functions.https.onRequest(async (req, res) => {
  // CORS Headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const apiKey = functions.config().gemini?.key;
    if (!apiKey) {
      console.error('Gemini API key not configured.');
      res.status(500).json({ error: 'Server configuration error: Gemini API key missing.' });
      return;
    }

    const { prompt, image, mimeType } = req.body;

    if (!prompt) {
      res.status(400).json({ error: 'Missing prompt in request body.' });
      return;
    }

    // Construct the payload for Gemini
    const parts: any[] = [{ text: prompt }];

    if (image) {
      parts.push({
        inline_data: {
          mime_type: mimeType || 'image/jpeg',
          data: image
        }
      });
    }

    const requestBody = {
      contents: [{ parts }]
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Gemini API Error:', response.status, errorText);
      res.status(500).json({ error: `Gemini API failed: ${response.statusText}` });
      return;
    }

    const data = await response.json();

    // Parse the response to get the raw text
    // Structure: candidates[0].content.parts[0].text
    const candidates = (data as any).candidates;
    if (!candidates || candidates.length === 0) {
      res.status(500).json({ error: 'No candidates returned from Gemini.' });
      return;
    }

    const text = candidates[0].content?.parts?.[0]?.text;
    if (!text) {
      res.status(500).json({ error: 'No text content in Gemini response.' });
      return;
    }

    // Return the raw text as requested
    res.status(200).send(text);

  } catch (error) {
    console.error('Internal Function Error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});
