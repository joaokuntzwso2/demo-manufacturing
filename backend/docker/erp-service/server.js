// ERP mock backend
// Exposes: GET /erp/orders/:id and GET /health

const http = require("http");
const url = require("url");

const PORT = 9001;

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

  // Route: GET /erp/orders/{id}
  if (req.method === "GET" && path.startsWith("/erp/orders/")) {
    const id = path.split("/").pop();

    const payload = {
      orderId: id,
      status: "PROCESSING",
      customer: "ACME Corp",
      orderDate: "2025-01-15",
      total: 1234.56,
      currency: "USD",
      plant: "SP1",
      sourceSystem: "ERP"
    };

    return sendJson(res, 200, payload);
  }

  // Health check
  if (req.method === "GET" && path === "/health") {
    return sendJson(res, 200, { status: "UP", service: "erp-service" });
  }

  // Not found
  return sendJson(res, 404, { error: "Not found" });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`ERP mock service listening on port ${PORT}`);
});

