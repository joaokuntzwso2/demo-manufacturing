// ---- Public API shapes for the agent ----

/// Generic request payload sent to the OEM agent endpoint.
public type AgentRequest record {|
    // Session id used for conversational continuity and memory scoping.
    string sessionId;
    // Raw user message (free text).
    string message;
|};

/// LLM usage metadata for APIM AI Gateway / observability.
/// Token counts are estimates (heuristic), not the provider's exact tokenizer.
public type LlmUsage record {|
    // Name of the underlying LLM model (e.g., "GPT_4O" or "gpt-4o")
    string responseModel;

    // Estimated token counts (prompt + completion)
    int promptTokenCount;
    int completionTokenCount;
    int totalTokenCount;

    // Optional: can be wired to a quota store later.
    int? remainingTokenCount?;
|};

/// Simple response payload returned from the agent endpoint.
public type AgentResponse record {|
    string sessionId;
    string agentName;
    string promptVersion;
    string message;

    // Optional LLM usage info (token estimation).
    LlmUsage? llm?;
|};

/// Generic error body (used for structured error responses).
public type ErrorBody record {|
    string message;
    string? details?;
|};

// ---- Data shapes for tools ----

/// Input for GetOrderContextTool.
public type OrderContextInput record {|
    string orderId;
|};

/// Input for GetLastReadingsTool (optional filter in future; currently unused by backend).
public type LastReadingsInput record {|
    string? plantId?;
|};

/// Input for GetPlantSummaryTool.
public type PlantSummaryInput record {|
    string? plantId?;
|};

/// Input for IngestTelemetryTool (HTTP path via MI).
public type IngestTelemetryInput record {|
    string machine;
    string plant;
    string ts?;
    float temperature;
    float vibration;
|};
