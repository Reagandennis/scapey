import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { raw_input } = await req.json();

        if (!raw_input) {
            throw new Error("Missing 'raw_input' in request body.");
        }

        // Replace with your actual LLM call (OpenAI, Gemini, etc.)
        // MOCK LLM response for MVP based on requirements:
        const mockNebulaResponse = {
            summary: "Processed unstructured thought: " + raw_input.substring(0, 20) + "...",
            steps: [
                "First actionable step derived from thought",
                "Second actionable step derived from thought",
                "Final step for structural execution"
            ],
            risks: [
                "Time underestimation",
                "Resource constraints"
            ],
            timeline: "Approx. 2-3 weeks",
            revenue_model: "Subscription-based SaaS (Optional)"
        };

        return new Response(JSON.stringify(mockNebulaResponse), {
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
