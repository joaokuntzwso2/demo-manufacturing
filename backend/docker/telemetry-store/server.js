// Telemetry store mock backend.
// Exposes:
//   POST /telemetry       -> store normalized telemetry + trigger alerts
//   GET  /last-readings   -> dump in-memory readings
//   GET  /health          -> health check

const http = require("http");
const url = require("url");

const PORT = 9100;

// In-memory store: last reading per machineId
const lastReadings = Object.create(null);

// Simple thresholds for "event trigger"
const TEMP_THRESHOLD = 80.0;
const VIB_THRESHOLD = 0.8;

function sendJson(res, statusCode, obj) {
  const json = JSON.stringify(obj);
  res.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(json)
  });
  res.end(json);
}

const server = http.createServer((req, res) => {
  const parsed = url.parse(req.url, true);
  const path = parsed.pathname || "";

  // Telemetry ingestion endpoint
  if (req.method === "POST" && path === "/telemetry") {
    let body = "";
    req.on("data", chunk => {
      body += chunk.toString("utf8");
      // Very simple protection against huge payloads
      if (body.length > 1e6) {
        req.socket.destroy();
      }
    });

    req.on("end", () => {
      let payload;
      try {
        payload = JSON.parse(body || "{}");
      } catch (e) {
        console.error("Invalid JSON payload:", e.message);
        return sendJson(res, 400, { error: "Invalid JSON" });
      }

      const {
        machineId,
        plantId,
        timestamp,
        temp,
        vibration
      } = payload;

      if (!machineId || !plantId || typeof temp !== "number" || typeof vibration !== "number") {
        return sendJson(res, 400, {
          error: "Missing or invalid telemetry fields",
          expected: "machineId, plantId, timestamp, temp:number, vibration:number"
        });
      }

      // Store last reading
      lastReadings[machineId] = {
        plantId,
        timestamp,
        temp,
        vibration,
        receivedAt: new Date().toISOString()
      };

      // Simple event trigger logic
      const events = [];
      if (temp > TEMP_THRESHOLD) {
        events.push({
          type: "TEMP_THRESHOLD_BREACHED",
          severity: "HIGH",
          message: `Temperature ${temp}°C above ${TEMP_THRESHOLD}°C`,
          machineId,
          plantId
        });
      }

      if (vibration > VIB_THRESHOLD) {
        events.push({
          type: "VIBRATION_THRESHOLD_BREACHED",
          severity: "HIGH",
          message: `Vibration ${vibration} above ${VIB_THRESHOLD}`,
          machineId,
          plantId
        });
      }

      if (events.length > 0) {
        console.log("=== ALERT EVENTS (simulated) ===");
        events.forEach(evt => console.log(JSON.stringify(evt)));
        console.log("================================");
      }

      return sendJson(res, 200, {
        status: "stored",
        machineId,
        plantId,
        alertsTriggered: events.length,
        events
      });
    });

    return;
  }

  // Quick introspection of last readings
  if (req.method === "GET" && path === "/last-readings") {
    return sendJson(res, 200, {
      count: Object.keys(lastReadings).length,
      readings: lastReadings
    });
  }

  // Health check
  if (req.method === "GET" && path === "/health") {
    return sendJson(res, 200, { status: "UP", service: "telemetry-store" });
  }

  // Not found
  return sendJson(res, 404, { error: "Not found" });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Telemetry store mock listening on port ${PORT}`);
});

