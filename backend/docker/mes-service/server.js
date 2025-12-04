// MES mock backend
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

  // Route: GET /mes/orders/{id}
  if (req.method === "GET" && path.startsWith("/mes/orders/")) {
    const id = path.split("/").pop();
    const now = new Date().toISOString();

    const payload = {
      orderId: id,
      currentStation: "PAINT",
      completionPercent: 72,
      line: "LINE-1",
      plant: "SP1",
      lastUpdated: now,
      sourceSystem: "MES"
    };

    return sendJson(res, 200, payload);
  }

  // Health check
  if (req.method === "GET" && path === "/health") {
    return sendJson(res, 200, { status: "UP", service: "mes-service" });
  }

  // Not found
  return sendJson(res, 404, { error: "Not found" });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`MES mock service listening on port ${PORT}`);
});

