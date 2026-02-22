import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { idea } = await req.json();

    if (!idea) {
      throw new Error("Missing 'idea' in request body.");
    }

    // Replace with your actual LLM call (OpenAI, Gemini, etc.)
    // MOCK LLM response for MVP based on requirements:
    const mockLLMResponse = {
      mission_title: "Plan for: " + idea.substring(0, 15) + "...",
      mission_description: "Auto-generated structured breakdown for: " + idea,
      priority: "medium", // low, medium, high
      estimated_minutes: 120,
      subtasks: [
        "Analyze requirements",
        "Define technical stack",
        "Draft initial execution strategy",
        "Review constraints and limits"
      ]
    };

    return new Response(JSON.stringify(mockLLMResponse), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
