import ballerina/http;
import ballerina/log;
import ballerinax/ai;

// ============================================================================
// Backend HTTP client (MI / APIM) for OEM visibility flows
// ============================================================================

final http:Client backendClient = checkpanic new (BACKEND_BASE_URL, {
    timeout: BACKEND_HTTP_TIMEOUT_SECONDS,
    retryConfig: {
        count: BACKEND_HTTP_MAX_RETRIES,
        interval: BACKEND_HTTP_RETRY_INTERVAL_SECONDS,
        backOffFactor: BACKEND_HTTP_RETRY_BACKOFF_FACTOR,
        maxWaitInterval: BACKEND_HTTP_RETRY_MAX_WAIT_SECONDS,
        statusCodes: BACKEND_HTTP_RETRY_STATUS_CODES
    },
    secureSocket: {
        // DEMO ONLY: TLS disabled for local/docker.
        // In production, configure proper TLS/mTLS here.
        enable: false
    }
});

// ============================================================================
// Standardized envelope builder
// ============================================================================
//
// All tools return JSON envelopes shaped as:
//
// {
//   "tool": "...",
//   "status": "SUCCESS" | "ERROR",
//   "errorCode": "...",
//   "httpStatus": ...,
//   "safeToRetry": true|false,
//   "message": "...",
//   "result": <any>,          // backend JSON payload (on SUCCESS)
//   "correlationId": "..."
// }

isolated function buildBackendSuccessEnvelope(
    string toolName,
    int httpStatus,
    json result,
    string correlationId
) returns json {
    return {
        tool: toolName,
        status: "SUCCESS",
        errorCode: "",
        httpStatus: httpStatus,
        safeToRetry: false,
        message: "",
        result: result,
        correlationId: correlationId
    };
}

isolated function buildBackendErrorEnvelope(
    string toolName,
    string errorCode,
    int httpStatus,
    string message,
    boolean safeToRetry,
    string correlationId
) returns json {
    return {
        tool: toolName,
        status: "ERROR",
        errorCode: errorCode,
        httpStatus: httpStatus,
        safeToRetry: safeToRetry,
        message: message,
        result: (),
        correlationId: correlationId
    };
}

// Build a standardized error envelope for client-side failures (network, parsing, etc.).
public isolated function buildClientErrorEnvelope(string toolName, error err, string correlationId) returns json {
    return buildBackendErrorEnvelope(
        toolName,
        "BACKEND_CLIENT_ERROR",
        500,
        err.message(),
        false,
        correlationId
    );
}

// Common header builder (correlation + interaction id + optional bearer token).
isolated function buildBackendHeaders(string corrId) returns map<string|string[]> {
    map<string|string[]> headers = {
        "X-Correlation-Id": corrId,
        "x-fapi-interaction-id": corrId
    };

    return headers;
}

// Decide if an HTTP status is transient (safe to retry at the LLM level).
isolated function isRetryableStatusCode(int statusCode) returns boolean {
    return statusCode == 503 || statusCode == 502 || statusCode == 504;
}

// ============================================================================
// Agent tools
// ============================================================================

// -------------- GetOrderContextTool -----------------

@ai:AgentTool {
    name: "GetOrderContextTool",
    description: "Fetches full OEM order context (ERP header + MES execution) for a given orderId."
}
public isolated function getOrderContextTool(OrderContextInput input) returns json {
    string corrId = generateCorrelationIdForTool("getOrderContext");

    log:printInfo(string `GetOrderContextTool starting, correlationId=${corrId}, orderId=${input.orderId}`);

    // MI facade: GET /internal/orders/orders/{id}
    string path = string `/internal/orders/orders/${input.orderId}`;
    map<string|string[]> headers = buildBackendHeaders(corrId);

    http:Response|error respOrErr = backendClient->get(path, headers);
    if respOrErr is error {
        log:printError(string `GetOrderContextTool HTTP call failed, correlationId=${corrId}`, respOrErr);
        return buildClientErrorEnvelope("GetOrderContextTool", respOrErr, corrId);
    }

    http:Response resp = respOrErr;
    json|error payloadOrErr = resp.getJsonPayload();
    if payloadOrErr is error {
        log:printError(
            string `GetOrderContextTool invalid JSON payload, statusCode=${resp.statusCode}, correlationId=${corrId}`,
            payloadOrErr
        );
        return buildClientErrorEnvelope("GetOrderContextTool", payloadOrErr, corrId);
    }

    json payload = payloadOrErr;

    log:printInfo(string `GetOrderContextTool HTTP call completed, statusCode=${resp.statusCode}, correlationId=${corrId}`);

    if resp.statusCode >= 200 && resp.statusCode < 300 {
        return buildBackendSuccessEnvelope(
            "GetOrderContextTool",
            resp.statusCode,
            payload,
            corrId
        );
    }

    boolean safeToRetry = isRetryableStatusCode(resp.statusCode);
    return buildBackendErrorEnvelope(
        "GetOrderContextTool",
        safeToRetry ? "BACKEND_UNAVAILABLE" : "BACKEND_HTTP_ERROR",
        resp.statusCode,
        "Backend returned HTTP status " + resp.statusCode.toString(),
        safeToRetry,
        corrId
    );
}

// -------------- GetLastReadingsTool -----------------

@ai:AgentTool {
    name: "GetLastReadingsTool",
    description: "Gets latest telemetry readings for all machines via MI (/internal/machine-health/telemetry/last-readings)."
}
public isolated function getLastReadingsTool(LastReadingsInput input) returns json {
    string corrId = generateCorrelationIdForTool("getLastReadings");

    // plantId is optional → use member access, not field access
    string plantFilter = "";
    string? optPlantFilter = input["plantId"];
    if optPlantFilter is string {
        plantFilter = optPlantFilter;
    }

    log:printInfo(string `GetLastReadingsTool starting, correlationId=${corrId}, plantFilter=${plantFilter}`);

    // MI facade: GET /internal/machine-health/telemetry/last-readings
    string path = "/internal/machine-health/telemetry/last-readings";
    map<string|string[]> headers = buildBackendHeaders(corrId);

    http:Response|error respOrErr = backendClient->get(path, headers);
    if respOrErr is error {
        log:printError(string `GetLastReadingsTool HTTP call failed, correlationId=${corrId}`, respOrErr);
        return buildClientErrorEnvelope("GetLastReadingsTool", respOrErr, corrId);
    }

    http:Response resp = respOrErr;
    json|error payloadOrErr = resp.getJsonPayload();
    if payloadOrErr is error {
        log:printError(
            string `GetLastReadingsTool invalid JSON payload, statusCode=${resp.statusCode}, correlationId=${corrId}`,
            payloadOrErr
        );
        return buildClientErrorEnvelope("GetLastReadingsTool", payloadOrErr, corrId);
    }

    json payload = payloadOrErr;

    log:printInfo(string `GetLastReadingsTool HTTP call completed, statusCode=${resp.statusCode}, correlationId=${corrId}`);

    if resp.statusCode >= 200 && resp.statusCode < 300 {
        // NOTE: Any filtering by plantId can be done by the LLM on this payload.
        return buildBackendSuccessEnvelope(
            "GetLastReadingsTool",
            resp.statusCode,
            payload,
            corrId
        );
    }

    boolean safeToRetry = isRetryableStatusCode(resp.statusCode);
    return buildBackendErrorEnvelope(
        "GetLastReadingsTool",
        safeToRetry ? "BACKEND_UNAVAILABLE" : "BACKEND_HTTP_ERROR",
        resp.statusCode,
        "Backend returned HTTP status " + resp.statusCode.toString(),
        safeToRetry,
        corrId
    );
}

// -------------- GetPlantSummaryTool -----------------

@ai:AgentTool {
    name: "GetPlantSummaryTool",
    description: "Queries plant health summary (distribution of machines by NORMAL/WARNING/CRITICAL)."
}
public isolated function getPlantSummaryTool(PlantSummaryInput input) returns json {
    string corrId = generateCorrelationIdForTool("getPlantSummary");

    string plantId = "";
    string? optPlantId = input["plantId"];
    if optPlantId is string {
        plantId = optPlantId;
    }

    log:printInfo(string `GetPlantSummaryTool starting, correlationId=${corrId}, plantId=${plantId}`);

    // MI facade: GET /internal/machine-health/summary
    string path = "/internal/machine-health/summary";
    map<string|string[]> headers = buildBackendHeaders(corrId);

    http:Response|error respOrErr = backendClient->get(path, headers);
    if respOrErr is error {
        log:printError(string `GetPlantSummaryTool HTTP call failed, correlationId=${corrId}`, respOrErr);
        return buildClientErrorEnvelope("GetPlantSummaryTool", respOrErr, corrId);
    }

    http:Response resp = respOrErr;
    json|error payloadOrErr = resp.getJsonPayload();
    if payloadOrErr is error {
        log:printError(
            string `GetPlantSummaryTool invalid JSON payload, statusCode=${resp.statusCode}, correlationId=${corrId}`,
            payloadOrErr
        );
        return buildClientErrorEnvelope("GetPlantSummaryTool", payloadOrErr, corrId);
    }

    json payload = payloadOrErr;

    log:printInfo(string `GetPlantSummaryTool HTTP call completed, statusCode=${resp.statusCode}, correlationId=${corrId}`);

    if resp.statusCode >= 200 && resp.statusCode < 300 {
        return buildBackendSuccessEnvelope(
            "GetPlantSummaryTool",
            resp.statusCode,
            payload,
            corrId
        );
    }

    boolean safeToRetry = isRetryableStatusCode(resp.statusCode);
    return buildBackendErrorEnvelope(
        "GetPlantSummaryTool",
        safeToRetry ? "BACKEND_UNAVAILABLE" : "BACKEND_HTTP_ERROR",
        resp.statusCode,
        "Backend returned HTTP status " + resp.statusCode.toString(),
        safeToRetry,
        corrId
    );
}

// -------------- IngestTelemetryTool -----------------

@ai:AgentTool {
    name: "IngestTelemetryTool",
    description: "Injects HTTP telemetry into /internal/machine-health/telemetry to simulate machine readings."
}
public isolated function ingestTelemetryTool(IngestTelemetryInput input) returns json {
    string corrId = generateCorrelationIdForTool("ingestTelemetry");

    log:printInfo(string `IngestTelemetryTool starting, correlationId=${corrId}, machine=${input.machine}, plant=${input.plant}`);

    string path = "/internal/machine-health/telemetry";
    map<string|string[]> headers = buildBackendHeaders(corrId);

    // ts is optional → use member access
    string ts = "";
    string? optTs = input["ts"];
    if optTs is string {
        ts = optTs;
    }

    json body = {
        machine: input.machine,
        plant: input.plant,
        ts: ts,
        temperature: input.temperature,
        vibration: input.vibration
    };

    http:Response|error respOrErr = backendClient->post(path, body, headers);
    if respOrErr is error {
        log:printError(string `IngestTelemetryTool HTTP call failed, correlationId=${corrId}`, respOrErr);
        return buildClientErrorEnvelope("IngestTelemetryTool", respOrErr, corrId);
    }

    http:Response resp = respOrErr;
    json|error payloadOrErr = resp.getJsonPayload();
    if payloadOrErr is error {
        log:printError(
            string `IngestTelemetryTool invalid JSON payload, statusCode=${resp.statusCode}, correlationId=${corrId}`,
            payloadOrErr
        );
        return buildClientErrorEnvelope("IngestTelemetryTool", payloadOrErr, corrId);
    }

    json payload = payloadOrErr;

    log:printInfo(string `IngestTelemetryTool HTTP call completed, statusCode=${resp.statusCode}, correlationId=${corrId}`);

    if resp.statusCode >= 200 && resp.statusCode < 300 {
        return buildBackendSuccessEnvelope(
            "IngestTelemetryTool",
            resp.statusCode,
            payload,
            corrId
        );
    }

    boolean safeToRetry = isRetryableStatusCode(resp.statusCode);
    return buildBackendErrorEnvelope(
        "IngestTelemetryTool",
        safeToRetry ? "BACKEND_UNAVAILABLE" : "BACKEND_HTTP_ERROR",
        resp.statusCode,
        "Backend returned HTTP status " + resp.statusCode.toString(),
        safeToRetry,
        corrId
    );
}
