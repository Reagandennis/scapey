/// <reference lib="deno.ns" />
import { corsHeaders } from "../_shared/cors.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const MODEL_NAME = "gemini-2.0-flash";


Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        if (!GEMINI_API_KEY) {
            throw new Error("Missing GEMINI_API_KEY environment variable.");
        }

        const { idea } = await req.json();

        if (!idea) {
            throw new Error("Missing 'idea' in request body.");
        }

        const prompt = `You are a productivity assistant. Given a mission idea, generate a structured plan in JSON format exactly matching this schema:
        {
            "mission_title": "string",
            "mission_description": "string",
            "priority": "low" | "medium" | "high",
            "estimated_minutes": number,
            "subtasks": ["string"]
        }
        Idea: ${idea}`;

        const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${GEMINI_API_KEY}`,
            {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ parts: [{ text: prompt }] }],
                    generationConfig: {
                        responseMimeType: "application/json",
                    },
                }),
            }
        );

        if (!response.ok) {
            const errorBody = await response.json();
            throw new Error(`Gemini API Error: ${response.status} ${response.statusText} - ${JSON.stringify(errorBody)}`);
        }

        const result = await response.json();
        const aiText = result.candidates[0].content.parts[0].text;
        const aiResponse = JSON.parse(aiText);

        return new Response(JSON.stringify(aiResponse), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
        });
    } catch (error: any) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 400,
        });
    }
});
