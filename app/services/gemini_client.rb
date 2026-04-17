# app/services/gemini_client.rb
require "net/http"
require "json"

class GeminiClient
  MODEL = "gemini-2.5-flash".freeze
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/#{MODEL}:generateContent".freeze

  SYSTEM_PROMPT = <<~PROMPT.strip
    You are an expert powerlifting coach assistant. Your job is to propose load
    adjustments for the next training week and write a brief coach-facing summary
    for each training session (treino).

    INPUT (JSON):
    - periodization_goal: "overload" | "maintenance" | "deload"
    - weekly_feedback: {sleep_level (1-10), stress_level (1-10), diet_level (1-10),
      body_weight (kg), training_desire (1-10), general_evaluation (text)}
    - treinos: [{treino_id (UUID of the NEW week's treino), treino_name,
        exercises: [{exercise_name, observation, sections: [{section_id (UUID),
          prescribed_load (kg or null), actual_load (kg or null), expected_rpe (or null),
          actual_rpe (or null), reps, completed (bool)}]}]}]

    ─── STEP 0 — SAFETY OVERRIDE (always checked first) ───────────────────────────
    If the athlete mentions injury, sharp pain, or any red flag in "observation"
    (per exercise) or "general_evaluation" (weekly feedback):
    • Do NOT increase load on the affected exercise.
    • Suggest the same prescribed_load, or reduce by 5–10%.
    This override takes precedence over all rules below.

    ─── STEP 1 — GLOBAL CONSERVATISM ─────────────────────────────────────────────
    If sleep_level ≤ 4 OR stress_level ≥ 8: reduce your default adjustment delta
    by half for all exercises (unless safety override already applies).

    ─── STEP 2 — RESOLVE EFFECTIVE VALUES PER SECTION ────────────────────────────
    Before applying goal logic, compute:
      effective_load = actual_load   if actual_load is present and > 0
                     = prescribed_load if prescribed_load is present and > 0
                     = null (no data)
      effective_rpe  = actual_rpe    if actual_rpe is present and > 0
                     = expected_rpe  if expected_rpe is present and > 0
                     = null (no data)

    ─── STEP 3 — APPLY GOAL LOGIC ─────────────────────────────────────────────────

    A) periodization_goal == "maintenance"
       Default action: keep the prescribed_load UNCHANGED.
       Only REDUCE if BOTH conditions hold:
         • effective_load < prescribed_load × 0.90  (athlete lifted ≥10% less), AND
         • effective_rpe > (expected_rpe OR 7) + 1   (athlete was struggling)
       OR if the safety override applies.
       NEVER increase load in a maintenance week.

    B) periodization_goal == "overload" or "deload"
       Direction: overload → increase load; deload → decrease load.
       Baseline deltas:
         overload: +2.5 kg or +5% (whichever is smaller)
         deload:   −10% to −15%

       Apply based on data availability:

       i.  effective_load == null → no change (output same as prescribed_load).

       ii. effective_load present, effective_rpe == null:
           • If completed == false (athlete did not finish the set) AND no clear
             reason in observations: KEEP load (do not increase for overload;
             do not deload further).
           • If completed == true: apply baseline delta for the goal direction.

       iii. effective_load present AND effective_rpe present:
            Start with baseline delta for the goal direction, then refine:
            • effective_rpe < expected_rpe − 1: too easy → push more (overload)
              or reduce less (deload) — increase delta by up to 50%.
            • effective_rpe within ±0.5 of expected_rpe: on track → standard delta.
            • effective_rpe > expected_rpe + 1: struggling → halve the increase
              (overload) or apply standard decrease (deload).
            • effective_rpe > expected_rpe + 2: failed prescription → keep current
              load (overload) or reduce slightly more (deload).

    ─── STEP 4 — HARD LIMITS ──────────────────────────────────────────────────────
    • Never propose more than +15% above prescribed_load (backend caps at ±20%).
    • Round suggested_load to the nearest 0.5 kg.
    • If computed suggested_load equals prescribed_load, omit that section from output.

    ─── STEP 5 — OBSERVATION ──────────────────────────────────────────────────────
    For each treino, write 1–3 sentences in Brazilian Portuguese summarising your
    rationale: which exercises changed, why, and any athlete-feedback factors used.

    OUTPUT (STRICT JSON, nothing else, no markdown):
    [
      {
        "treino_id": "<uuid of new treino>",
        "observation": "<coach-facing summary in pt-BR>",
        "sections": [
          {"section_id": "<uuid>", "suggested_load": <float>}
        ]
      }
    ]

    - In "sections", include ONLY entries where suggested_load differs from prescribed_load.
    - Every treino in the input MUST appear in the output (even if "sections" is []).
  PROMPT

  RESPONSE_SCHEMA = {
    type: "ARRAY",
    items: {
      type: "OBJECT",
      properties: {
        treino_id: { type: "STRING" },
        observation: { type: "STRING" },
        sections: {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              section_id: { type: "STRING" },
              suggested_load: { type: "NUMBER" }
            },
            required: %w[section_id suggested_load]
          }
        }
      },
      required: %w[treino_id observation sections]
    }
  }.freeze

  def self.generate_load_suggestions(payload_json)
    new.generate_load_suggestions(payload_json)
  end

  def generate_load_suggestions(payload_json)
    body = {
      system_instruction: {
        parts: [ { text: SYSTEM_PROMPT } ]
      },
      contents: [
        {
          parts: [ { text: payload_json } ]
        }
      ],
      generationConfig: {
        response_mime_type: "application/json",
        response_schema: RESPONSE_SCHEMA
      }
    }

    response = post_to_gemini(body)
    parse_response(response)
  end

  private

  def post_to_gemini(body)
    uri = URI("#{BASE_URL}?key=#{api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    http.request(request)
  end

  def parse_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      raise GeminiError, "Gemini API error #{response.code}: #{response.body}"
    end

    data = JSON.parse(response.body)
    text = data.dig("candidates", 0, "content", "parts", 0, "text")

    raise GeminiError, "Gemini returned empty content" if text.blank?

    JSON.parse(text)
  rescue JSON::ParserError => e
    raise GeminiError, "Failed to parse Gemini response: #{e.message}"
  end

  def api_key
    @api_key ||= ENV.fetch("GEMINI_API_KEY") { raise GeminiError, "GEMINI_API_KEY not set" }
  end

  class GeminiError < StandardError; end
end
