// MQTT → HTTP bridge
// Subscribes to MQTT telemetry topic and forwards messages to MI HTTP API.

const mqtt = require("mqtt");
const http = require("http");
const { URL } = require("url");

const MQTT_URL = process.env.MQTT_URL || "mqtt://mqtt-broker:1883";
const MQTT_TOPIC = process.env.MQTT_TOPIC || "oem/telemetry/+/+";
const MI_BASE_URL = process.env.MI_BASE_URL || "http://mi:8290";
const TELEMETRY_PATH =
  process.env.TELEMETRY_PATH || "/internal/machine-health/telemetry";

const targetUrl = new URL(MI_BASE_URL);
targetUrl.pathname = TELEMETRY_PATH;

console.log(`[Bridge] MQTT_URL: ${MQTT_URL}`);
console.log(`[Bridge] MQTT_TOPIC: ${MQTT_TOPIC}`);
console.log(
  `[Bridge] MI target: ${targetUrl.protocol}//${targetUrl.host}${targetUrl.pathname}`
);

const client = mqtt.connect(MQTT_URL);

client.on("connect", () => {
  console.log("[Bridge] Connected to MQTT broker, subscribing...");
  client.subscribe(MQTT_TOPIC, err => {
    if (err) {
      console.error("[Bridge] Subscription error:", err);
    } else {
      console.log(`[Bridge] Subscribed to topic: ${MQTT_TOPIC}`);
    }
  });
});

client.on("reconnect", () => {
  console.log("[Bridge] MQTT reconnecting...");
});

client.on("error", err => {
  console.error("[Bridge] MQTT error object:", err);
});

client.on("message", (topic, message) => {
  const payloadStr = message.toString("utf8");
  console.log(`[Bridge] Received on ${topic}: ${payloadStr}`);

  let payload;
  try {
    payload = JSON.parse(payloadStr);
  } catch (e) {
    console.error("[Bridge] Invalid JSON payload from MQTT:", e.message);
    return;
  }

  const body = JSON.stringify(payload);

  const options = {
    hostname: targetUrl.hostname,
    port: targetUrl.port || 80,
    path: targetUrl.pathname + (targetUrl.search || ""),
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(body)
    }
  };

  const req = http.request(options, res => {
    console.log(
      `[Bridge] Forwarded to MI, status=${res.statusCode}, path=${options.path}`
    );
    res.on("data", () => {}); // drain response
  });

  req.on("error", err => {
    console.error("[Bridge] HTTP error when calling MI:", err.message);
  });

  req.write(body);
  req.end();
});
