// MES mock backend (enhanced + request logging)
// Exposes: GET /mes/orders/:id and GET /health

const http = require("http");
const url = require("url");

const PORT = 9002;

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

  // 🟦 Structured logging (same style as ERP)
  console.log(
    `[MES] ${new Date().toISOString()} - ${req.method} ${path}${
      parsed.search || ""
    }`
  );

  // Route: GET /mes/orders/{id}
  if (req.method === "GET" && path.startsWith("/mes/orders")) {
    // Robust extraction of order id: /mes/orders/:id
    const segments = path.split("/").filter(Boolean); // ["mes","orders","123"]
    const id = segments[2] || "UNKNOWN";

    const now = new Date().toISOString();

    // Simple, demo-friendly MES payload
    const payload = {
      orderId: id,
      currentStation: "PAINT",
      completionPercent: 72,
      line: "LINE-1",
      plant: "SP1",
      shift: "A",
      plannedStart: "2025-12-01T08:00:00Z",
      plannedEnd: "2025-12-01T16:00:00Z",
      actualStart: "2025-12-01T08:12:00Z",
      lastUpdated: now,
      oee: 0.87,
      qualityRate: 0.98,
      availabilityRate: 0.92,
      performanceRate: 0.97,
      bottleneckFlag: false,
      scrapCount: 0,
      reworkCount: 0,
      sourceSystem: "MES"
    };

    return sendJson(res, 200, payload);
  }

  // Health check
  if (req.method === "GET" && path === "/health") {
    return sendJson(res, 200, { status: "UP", service: "mes-service" });
  }

  // Not found fallback
  return sendJson(res, 404, { error: "Not found" });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`MES mock service listening on port ${PORT}`);
});
