import ballerina/http;
import ballerina/log;
import ballerinax/ai;
import ballerinax/jaeger as _;
import ballerinax/prometheus as _;

// HTTP listener for the OEM Operations Visibility agent.
listener http:Listener httpListener = new (HTTP_LISTENER_PORT);

// -----------------------------------------------------------------------------
// Small HTTP helpers for consistent responses
// -----------------------------------------------------------------------------

public isolated function buildErrorResponse(int statusCode, ErrorBody body, string correlationId)
        returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    _ = res.setJsonPayload(body);
    if correlationId != "" {
        res.setHeader("X-Correlation-Id", correlationId);
    }
    return res;
}

isolated function buildSuccessResponse(AgentResponse body, string correlationId) returns http:Response {
    http:Response res = new;
    res.statusCode = http:STATUS_OK;
    _ = res.setJsonPayload(body);
    if correlationId != "" {
        res.setHeader("X-Correlation-Id", correlationId);
    }
    return res;
}

isolated function getOrGenerateCorrelationId(http:Request httpReq) returns string {
    string|http:HeaderNotFoundError headerVal = httpReq.getHeader("X-Correlation-Id");

    if headerVal is string {
        string trimmed = headerVal.trim();
        if trimmed.length() > 0 {
            return trimmed;
        }
    }

    return generateCorrelationId();
}

// ---- Shared handler for the OEM agent ----
public isolated function handleAgentRequest(
        ai:Agent agent,
        string agentName,
        string promptVersion,
        AgentRequest req,
        string correlationId,
        string endpointPath
) returns http:Response {

    if req.sessionId.trim().length() == 0 {
        ErrorBody badReqBody = {
            message: "Invalid request",
            details: "sessionId must not be empty"
        };
        log:printError("Agent request rejected: empty sessionId",
            'error = error("BAD_REQUEST"),
            'value = {
                "agentName": agentName,
                "endpointPath": endpointPath,
                "correlationId": correlationId
            });
        return buildErrorResponse(http:STATUS_BAD_REQUEST, badReqBody, correlationId);
    }

    if req.message.trim().length() == 0 {
        ErrorBody badReqBody = {
            message: "Agent execution failed.",
            details: "Try again later or contact support."
        };

        log:printError("Agent request rejected: empty message",
            'error = error("BAD_REQUEST"),
            'value = {
                "agentName": agentName,
                "sessionId": req.sessionId,
                "endpointPath": endpointPath,
                "correlationId": correlationId
            });
        return buildErrorResponse(http:STATUS_BAD_REQUEST, badReqBody, correlationId);
    }

    log:printInfo("OEM agent IN",
        'value = {
            "sessionId": req.sessionId,
            "userMessage": req.message,
            "agentName": agentName,
            "promptVersion": promptVersion,
            "endpointPath": endpointPath,
            "correlationId": correlationId
        }
    );

    string sessionId = req.sessionId;
    string message = req.message;

    string|ai:Error result = agent->run(message, sessionId = sessionId);

    // Optional single retry for transient LLM errors.
    if result is ai:Error && isTransientLLMError(result) {
        log:printWarn("Transient LLM error, retrying once...",
            'value = { "sessionId": sessionId, "correlationId": correlationId, "error": result.message() });

        result = agent->run(message, sessionId = sessionId);
    }

    if result is string {
        log:printInfo("OEM agent OUT",
            'value = {
                "sessionId": sessionId,
                "agentName": agentName,
                "promptVersion": promptVersion,
                "endpointPath": endpointPath,
                "correlationId": correlationId,
                "httpStatus": http:STATUS_OK
            }
        );

        // LLM usage (token estimation) — same pattern as the Pharma project.
        LlmUsage llmUsage = buildLlmUsage(
            OPENAI_MODEL.toString(),
            message,
            result
        );

        AgentResponse resp = {
            sessionId: sessionId,
            agentName: agentName,
            promptVersion: promptVersion,
            message: result,
            llm: llmUsage
        };
        return buildSuccessResponse(resp, correlationId);
    }

    // Error path from agent execution
    log:printError("OEM agent execution failed",
        'error = result,
        'value = {
            "agentName": agentName,
            "sessionId": sessionId,
            "endpointPath": endpointPath,
            "correlationId": correlationId,
            "httpStatus": http:STATUS_INTERNAL_SERVER_ERROR
        });

    ErrorBody body = {
        message: "Agent execution failed",
        details: result.message()
    };

    return buildErrorResponse(http:STATUS_INTERNAL_SERVER_ERROR, body, correlationId);
}

// -----------------------------------------------------------------------------
// Versioned services
// -----------------------------------------------------------------------------

service /v1 on httpListener {

    // OEM Operations Visibility Agent: /v1/chat
    resource isolated function post chat(@http:Payload AgentRequest req, http:Request httpReq)
            returns http:Response {

        string correlationId = getOrGenerateCorrelationId(httpReq);
        return handleAgentRequest(
            oemAgent,
            OEM_AGENT_NAME,
            OEM_PROMPT_VERSION,
            req,
            correlationId,
            "/v1/chat"
        );
    }

    // Simple liveness endpoint for orchestration / readiness checks: /v1/health
    resource isolated function get health() returns http:Response {
        http:Response res = new;
        res.statusCode = http:STATUS_OK;
        _ = res.setJsonPayload({ status: "UP", component: "OEM-Operations-Visibility-Agent" });
        return res;
    }

    // Optional readiness endpoint.
    resource isolated function get health/ready() returns http:Response {
        http:Response res = new;
        _ = res.setJsonPayload({
            status: "UP",
            component: "OEM-Operations-Visibility-Agent",
            dependencies: ["OpenAI", "MI/APIM-Backend"]
        });
        res.statusCode = http:STATUS_OK;
        return res;
    }
}
