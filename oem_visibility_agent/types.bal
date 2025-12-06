// ---- Public API shapes for the agent ----

/// Generic request payload sent to the OEM agent endpoint.
public type AgentRequest record {|
    // Session id used for conversational continuity and memory scoping.
    string sessionId;
    // Raw user message (free text).
    string message;
|};

/// Simple response payload returned from the agent endpoint.
public type AgentResponse record {|
    string sessionId;
    string agentName;
    string promptVersion;
    string message;
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
