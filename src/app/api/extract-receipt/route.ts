import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { image } = body;

    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json(
        { error: 'Gemini API key is missing. Please add GEMINI_API_KEY to your .env file.' },
        { status: 500 }
      );
    }

    if (!image) {
      return NextResponse.json({ error: 'Image is required' }, { status: 400 });
    }

    // image is expected to be a data URL like "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ..."
    const match = image.match(/^data:(image\/[a-zA-Z+]+);base64,(.+)$/);
    if (!match) {
        return NextResponse.json({ error: 'Invalid image format' }, { status: 400 });
    }
    const mimeType = match[1];
    const base64Data = match[2];

    const prompt = `
Analyze this image (which could be a receipt, a bill, or a screenshot of multiple transactions like PhonePe/GPay).
Extract ALL visible transactions. Return an ARRAY of JSON objects.
For each transaction, extract the following:
- amount: The total amount as a positive number (without currency symbols).
- title: A short description of the merchant, person, or place.
- category: Pick ONE of the most appropriate categories from this list: "Food", "Transport", "Subscriptions", "Entertainment", "Shopping", "Bills", "Other". If unsure, use "Other".
- date: The date and time of the transaction in ISO 8601 format (YYYY-MM-DDTHH:mm). If the time is missing, assume 12:00 PM. If the date is entirely missing, use the current date and time.

Return ONLY the raw JSON array of objects, without any markdown formatting or backticks. It must be a perfectly valid JSON array. Example:
[
  {
    "amount": 25.50,
    "title": "Starbucks",
    "category": "Food",
    "date": "2023-10-27T12:00"
  }
]
`;

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        {
          role: 'user',
          parts: [
            { text: prompt },
            {
              inlineData: {
                data: base64Data,
                mimeType: mimeType,
              }
            }
          ]
        }
      ],
      config: {
        responseMimeType: "application/json",
      }
    });

    const resultText = response.text || "{}";
    let parsedData = {};
    try {
        parsedData = JSON.parse(resultText);
    } catch (e) {
        // Fallback cleanup if the model still returned markdown
        const cleanedText = resultText.replace(/```json/g, '').replace(/```/g, '').trim();
        parsedData = JSON.parse(cleanedText);
    }

    return NextResponse.json(parsedData);
  } catch (error: any) {
    console.error('Extract API Error:', error);
    return NextResponse.json(
      { error: error.message || 'An error occurred during receipt extraction.' },
      { status: 500 }
    );
  }
}
