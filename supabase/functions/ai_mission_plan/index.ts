import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GEMINI_API_KEY = "AIzaSyDKTZom8TRA3BWcsSl8LxVSl7DkFS4lVn0";

serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
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
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
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
