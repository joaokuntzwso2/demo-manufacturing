````markdown
# **OEM Visibility Demo – Unified Manufacturing Operations, Telemetry Intelligence & Agentic Insights**

### *Powered by WSO2 Micro Integrator, API Manager, MQTT, Node.js Services & AI Agent Layer*

This repository delivers a **full-stack manufacturing visibility platform** that demonstrates how modern OEMs can unify:

* **Operational Technology (OT)** — shop-floor machine telemetry via MQTT
* **Information Technology (IT)** — ERP & MES enterprise systems
* **Real-time machine health analytics** — telemetry normalization, alerting & storage
* **Enterprise-grade integration** — orchestration, mediation, resiliency, observability
* **API governance and lifecycle management** — via **WSO2 API Manager**
* **AI-driven insights** — through an **Agentic Manufacturing Operations Assistant**

All components run end-to-end through **Docker Compose**, emulating a realistic **Industry 4.0 integration architecture**.

---

# **1. What This Demo Enables (Executive Summary)**

This solution demonstrates how an OEM or industrial manufacturer can:

### ✔ Achieve real-time operations visibility

Consolidate **ERP orders, MES production status, and machine telemetry** into a unified integration layer powered by **WSO2 Micro Integrator**.

### ✔ Detect anomalies and machine degradation early

Normalize telemetry streams and detect **temperature and vibration threshold breaches**.

### ✔ Enable OT/IT convergence

Bring siloed systems (ERP, MES, IoT telemetry) into a single **integration backbone**.

### ✔ Provide a digital thread across systems

```text
Order → Production → Machine Health → Alerts
````

### ✔ Empower supervisors and analysts with AI

A **Ballerina-based Agentic Operations Assistant** uses MI APIs to generate contextual explanations and operational insights.

### ✔ Demonstrate a world-class integration backbone

Using WSO2 technologies for:

* Composite integrations
* MQTT ingest flows
* Transformation & normalization
* Observability & correlation IDs
* Robust mediation patterns
* API lifecycle management

---

# 🧠 **3. Agentic Layer – Manufacturing Operations AI Assistant**

The AI assistant:

* ONLY communicates in **English**
* Uses **tool-calling via WSO2 MI APIs**
* NEVER accesses backend systems directly

### AI Tools

| Tool                | Purpose                  |
| ------------------- | ------------------------ |
| GetOrderContextTool | ERP + MES composite      |
| GetLastReadingsTool | Latest telemetry         |
| GetPlantSummaryTool | Plant health aggregation |
| IngestTelemetryTool | Inject telemetry         |

---

# 🚀 **5. Running the Demo**

```bash
docker compose up -d --build
docker compose ps
```

---

# 🧪 **6. End-to-End Test Guide**

---

## 6.1 Quick Health Checks

```bash
curl -s http://localhost:9001/health | jq
curl -s http://localhost:9002/health | jq
curl -s http://localhost:9100/health | jq
curl -s http://localhost:8290/internal/machine-health/summary | jq
curl -s http://localhost:8293/v1/health | jq
curl -s http://localhost:8293/v1/health/ready | jq
```

### Expected Behavior

| Component         | Expected             |
| ----------------- | -------------------- |
| ERP/MES/Telemetry | `status: UP`         |
| MI                | returns summary JSON |
| Agent             | `status: UP`         |

---

## 6.2 Backend Tests

### ERP

```bash
curl -s http://localhost:9001/erp/orders | jq
```

**Expected:** list of demo orders

```bash
curl -s http://localhost:9001/erp/orders/1001 | jq
```

**Expected:** full ERP order

---

### MES

```bash
curl -s http://localhost:9002/mes/orders/1001 | jq
```

**Expected:** execution details (station, OEE, completion %)

---

### Telemetry Store

#### Normal telemetry

```bash
curl -s -X POST http://localhost:9100/telemetry \
-H 'Content-Type: application/json' \
-d '{"machineId":"M-100","plantId":"SP1","timestamp":"2026-03-24T10:00:00Z","temp":72.4,"vibration":0.31}' | jq
```

**Expected:**

* status: stored
* healthState: NORMAL

---

#### Critical telemetry

```bash
curl -s -X POST http://localhost:9100/telemetry \
-H 'Content-Type: application/json' \
-d '{"machineId":"M-200","plantId":"SP1","timestamp":"2026-03-24T10:05:00Z","temp":84.2,"vibration":0.91}' | jq
```

**Expected:**

* healthState: CRITICAL
* alert events triggered

---

## 6.3 WSO2 MI Tests

### Telemetry via MI

```bash
curl -s -X POST http://localhost:8290/internal/machine-health/telemetry \
-H 'Content-Type: application/json' \
-d '{"machine":"M-101","plant":"SP1","ts":"2026-03-24T10:10:00Z","temperature":65.5,"vibration":0.21}' | jq
```

**Flow:** Host → MI → Telemetry Store
**Expected:** `"status": "accepted"`

---

### Composite Order API

```bash
curl -s http://localhost:8290/internal/orders/orders/1001 | jq
```

**Flow:** MI → ERP + MES
**Expected:**

```json
{
  "orderId": "1001",
  "erpRaw": {...},
  "mesRaw": {...}
}
```

---

## 6.4 MQTT End-to-End

```bash
docker exec -i mqtt-broker mosquitto_pub \
-h localhost -p 1883 \
-t oem/telemetry/SP1/M-300 \
-m '{"machine":"M-300","plant":"SP1","ts":"2026-03-24T10:20:00Z","temperature":58.4,"vibration":0.18}'
```

**Flow:** MQTT → Bridge/MI → Telemetry Store
**Expected:** machine appears in readings

---

# 🤖 **7. AI Agent Tests (ENGLISH ONLY)**

---

## Chat Format

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-H 'X-Correlation-Id: vp-demo-001' \
-d '{
  "sessionId":"demo-session-1",
  "message":"Give me an executive summary of plant SP1."
}' | jq
```

**Expected Response Structure:**

```json
{
  "sessionId": "...",
  "agentName": "...",
  "promptVersion": "...",
  "message": "...",
  "llm": {...}
}
```

---

## Demo Prompts

---

### A. Plant Summary

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-plant",
  "message":"Give me an executive summary of the operational health of plant SP1."
}' | jq
```

**Expected:**

* High-level plant overview
* Machine distribution (NORMAL/WARNING/CRITICAL)

---

### B. Critical Machines

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-plant",
  "message":"Which machines are in warning or critical state in plant SP1 and why?"
}' | jq
```

**Expected:**

* List of machines
* Explanation (temperature / vibration)

---

### C. Operational Recommendations

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-plant",
  "message":"Based on the current telemetry, what operational actions do you recommend to avoid bottlenecks in SP1?"
}' | jq
```

**Expected:**

* Actionable insights
* Maintenance / load balancing suggestions

---

### D. Order Context

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-order",
  "message":"Explain the operational context of order 1001."
}' | jq
```

**Expected:**

* Customer
* Plant
* Priority
* MES execution

---

### E. Executive Order Summary

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-order",
  "message":"Summarize order 1001 for an executive: customer, plant, priority, dates, and execution status."
}' | jq
```

---

### F. Risk vs Priority Order

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-order",
  "message":"Is there any operational risk that could impact a high priority order like 1001?"
}' | jq
```

---

### G. Inject Telemetry via Agent

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-sim",
  "message":"Register telemetry for machine M-900 in plant SP1 with temperature 82.5 and vibration 0.91, then explain the operational impact."
}' | jq
```

**Flow:** Agent → MI → Telemetry Store

---

### Confirm via MI

```bash
curl -s http://localhost:8290/internal/machine-health/summary | jq
```

---

### H. Follow-up

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H 'Content-Type: application/json' \
-d '{
  "sessionId":"demo-session-sim",
  "message":"Given the condition of machine M-900, what are the next recommended operational and maintenance actions?"
}' | jq
```

---

# 🏭 **9. Why This Matters**

✔ OT/IT convergence
✔ Real-time operational visibility
✔ AI-driven decision support
✔ Scalable integration architecture
