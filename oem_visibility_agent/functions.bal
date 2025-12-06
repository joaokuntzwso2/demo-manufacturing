import ballerina/time;
import ballerina/lang.'string as string;
import ballerinax/ai;

// ============================================================================
// Correlation IDs & shared helpers
// ============================================================================

public isolated function generateCorrelationId() returns string {
    return "corr-oem-" + time:utcNow().toString();
}

public isolated function generateCorrelationIdForTool(string toolName) returns string {
    time:Utc now = time:utcNow();
    return string `corr-oem-${toolName}-${now.toString()}`;
}

// Safely truncate a string for logging without risking panics on substring.
public isolated function safeTruncate(string value, int maxLen) returns string {
    if value.length() <= maxLen {
        return value;
    }
    return value.substring(0, maxLen);
}

// -----------------------------------------------------------------------------
// Small internal helpers
// -----------------------------------------------------------------------------

isolated function containsAnySubstringIgnoreCase(
    string sourceString,
    readonly & string[] markers
) returns boolean {
    if sourceString.length() == 0 {
        return false;
    }
    string normalized = sourceString.toLowerAscii();
    foreach string marker in markers {
        if string:includes(normalized, marker) {
            return true;
        }
    }
    return false;
}

// --- Transient LLM error detection --------------------------------------------------------

const string[] TRANSIENT_LLM_ERROR_MARKERS = [
    "rate limit",
    "tpm",
    "rpm",
    "timeout",
    "overloaded",
    "server error",
    "unavailable"
];

/// Returns true if the given error likely represents a transient LLM/backend issue
/// that is safe to retry (e.g., rate limits, overloads, timeouts).
public isolated function isTransientLLMError(ai:Error err) returns boolean {
    return containsAnySubstringIgnoreCase(err.message(), TRANSIENT_LLM_ERROR_MARKERS);
}
