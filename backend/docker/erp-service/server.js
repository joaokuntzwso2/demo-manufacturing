// ERP mock backend (enhanced for manufacturing context)
// Exposes:
//   GET /erp/orders/:id   -> detailed order header from ERP
//   GET /erp/orders       -> list/sample of recent orders (demo only)
//   GET /health           -> health check

const http = require("http");
const url = require("url");

const PORT = process.env.PORT || 9001;

// --- Simple in-memory "ERP" order dataset for demo purposes ---

const ORDERS_DB = {
  "1001": {
    orderId: "1001",
    customer: "ACME Corp",
    customerCode: "ACME_BR",
    customerSegment: "AUTOMOTIVE_OEM",
    status: "RELEASED",
    priority: "HIGH",
    orderDate: "2025-01-10",
    requestedDeliveryDate: "2025-01-20",
    plant: "SP1",
    incoterm: "FOB",
    currency: "USD",
    total: 24500.0,
    productionType: "MAKE_TO_ORDER",
    materialCode: "CHASSIS-ASSY-01",
    materialDescription: "Chassis Assembly - Sedan Platform",
    quantity: 50,
    uom: "PCS",
    sourceSystem: "ERP"
  },
  "1002": {
    orderId: "1002",
    customer: "Global Motors",
    customerCode: "GMOT_US",
    customerSegment: "AUTOMOTIVE_OEM",
    status: "CONFIRMED",
    priority: "MEDIUM",
    orderDate: "2025-01-11",
    requestedDeliveryDate: "2025-01-28",
    plant: "SP1",
    incoterm: "CIF",
    currency: "USD",
    total: 7800.0,
    productionType: "MAKE_TO_STOCK",
    materialCode: "BUMPER-PLASTIC-01",
    materialDescription: "Front Bumper - Black",
    quantity: 200,
    uom: "PCS",
    sourceSystem: "ERP"
  }
};

function buildOrderFromId(id) {
  // If we don't have a pre-defined order, generate a synthetic but realistic one.
  if (ORDERS_DB[id]) {
    return ORDERS_DB[id];
  }

  const today = new Date();
  const orderDate = new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000);
  const deliveryDate = new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000);

  return {
    orderId: id,
    customer: "Default OEM Customer",
    customerCode: "OEM_DEFAULT",
    customerSegment: "GENERAL_MANUFACTURING",
    status: "PROCESSING",
    priority: "NORMAL",
    orderDate: orderDate.toISOString().substring(0, 10),
    requestedDeliveryDate: deliveryDate.toISOString().substring(0, 10),
    plant: "SP1",
    incoterm: "EXW",
    currency: "USD",
    total: 1234.56,
    productionType: "MAKE_TO_ORDER",
    materialCode: "GENERIC-PART",
    materialDescription: "Generic Manufacturing Part",
    quantity: 100,
    uom: "PCS",
    sourceSystem: "ERP"
  };
}

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

  // Basic structured logging for demo
  console.log(
    `[ERP] ${new Date().toISOString()} - ${req.method} ${path}${
      parsed.search || ""
    }`
  );

  // Route: GET /erp/orders/{id}
  if (req.method === "GET" && path.startsWith("/erp/orders/")) {
    const id = path.split("/").pop();

    const payload = buildOrderFromId(id);
    return sendJson(res, 200, payload);
  }

  // Route: GET /erp/orders  (simple listing for demos / dashboards)
  if (req.method === "GET" && path === "/erp/orders") {
    const list = Object.values(ORDERS_DB);
    return sendJson(res, 200, {
      count: list.length,
      orders: list
    });
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
