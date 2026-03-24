import ballerinax/ai;

public configurable string BACKEND_BASE_URL = ?;

// OpenAI / LLM configuration
public configurable string OPENAI_API_KEY = ?;
public configurable ai:OPEN_AI_MODEL_NAMES OPENAI_MODEL = ai:GPT_4O;

// Public agent observability names and versions
public configurable string OEM_AGENT_NAME = "OEMOperationsVisibilityAgent";
public const string OEM_PROMPT_VERSION = "oem-visibility-v1.1.0";

// HTTP listener port for the BI agent API.
public configurable int HTTP_LISTENER_PORT = 8293;

// Backend HTTP client configuration
public configurable decimal BACKEND_HTTP_TIMEOUT_SECONDS = 3.0;
public configurable int BACKEND_HTTP_MAX_RETRIES = 1;
public configurable decimal BACKEND_HTTP_RETRY_INTERVAL_SECONDS = 0.5;
public configurable float BACKEND_HTTP_RETRY_BACKOFF_FACTOR = 2.0;
public configurable decimal BACKEND_HTTP_RETRY_MAX_WAIT_SECONDS = 2.0;

// Only treat these status codes as retry-eligible at the HTTP client level.
public configurable int[] BACKEND_HTTP_RETRY_STATUS_CODES = [500, 502, 503, 504];