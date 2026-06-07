import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenAI } from '@google/genai';

// Initialize the Google Gen AI SDK
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { messages, context } = body;

    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json(
        { error: 'Gemini API key is missing. Please add GEMINI_API_KEY to your .env file.' },
        { status: 500 }
      );
    }

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return NextResponse.json({ error: 'Messages are required' }, { status: 400 });
    }

    // Format context into a readable string for the prompt
    let contextString = '';
    if (context) {
      const now = new Date();
      contextString = `
You are Aurex, a helpful, encouraging, and friendly financial assistant for the SmartSpend app. 
The current date and time right now is: ${now.toLocaleString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' })}.
Use this date to answer questions like "this week", "today", "last month", etc.

Here is the user's current financial context:
- Total Balance: ₹${context.totalBalance}
- Total Income: ₹${context.totalIncome}
- Total Expenses: ₹${context.totalExpense}

All Transactions History:
${context.transactions.map((t: any) => `- ${t.date.split('T')[0]}: ${t.title} (${t.category}) - ${t.type === 'INCOME' ? '+' : '-'}₹${Math.abs(t.amount)}`).join('\n')}

Active Goals:
${context.goals.map((g: any) => `- ${g.name}: ₹${g.saved} / ₹${g.target} saved`).join('\n')}

Please use this context to answer the user's questions in a short, conversational, and helpful manner. Avoid huge blocks of text. Use emojis occasionally!
`;
    }

    // Get the latest user message
    const lastUserMessage = messages[messages.length - 1].content;

    // Call Gemini API
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: contextString + '\n\nUser Question: ' + lastUserMessage,
    });

    return NextResponse.json({
      role: 'ai',
      content: response.text || "I'm sorry, I couldn't generate a response."
    });
  } catch (error: any) {
    console.error('Chat API Error:', error);
    return NextResponse.json(
      { error: error.message || 'An error occurred during chat completion.' },
      { status: 500 }
    );
  }
}
