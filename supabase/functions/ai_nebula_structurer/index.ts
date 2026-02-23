/// <reference lib="deno.ns" />
import { corsHeaders } from "../_shared/cors.ts";



const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { raw_input } = await req.json();

        if (!raw_input) {
            throw new Error("Missing 'raw_input' in request body.");
        }

        const prompt = `You are a brainstorming assistant. Structure this raw thought into a formal project brief in JSON format exactly matching this schema:
        {
            "summary": "string",
            "steps": ["string"],
            "risks": ["string"],
            "timeline": "string",
            "revenue_model": "optional string"
        }
        Raw Thought: ${raw_input}`;

        const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
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

        const result = await response.json();

        if (!response.ok) {
            throw new Error(`Gemini API Error: ${JSON.stringify(result)}`);
        }

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
