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

```
Order → Production → Machine Health → Alerts
```

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

# 🏗 **2. System Architecture Overview**

```
                         +-----------------------+
                         |      ERP Service      |
                         |   http://localhost:9001
                         +-----------------------+
                                   |
                                   |
                         +-----------------------+
                         |      MES Service      |
                         |   http://localhost:9002
                         +-----------------------+
                                   |
                                   v
+----------------------------------------------------------------+
|              WSO2 MICRO INTEGRATOR (Integration Layer)         |
|                                                                |
| Facade APIs                                                    |
|                                                                |
| GET  /internal/orders/orders/{id}                              |
|      ↳ Composite orchestration: ERP → MES → JSON merge         |
|                                                                |
| POST /internal/machine-health/telemetry                        |
|      ↳ Normalize telemetry → Telemetry Store                   |
|                                                                |
| GET  /internal/machine-health/telemetry/last-readings          |
| GET  /internal/machine-health/summary                          |
|                                                                |
| MQTT Inbound                                                   |
| Topic: oem/telemetry/{plant}/{machine}                         |
| Runs TelemetryNormalizationSeq                                 |
+----------------------------------------------------------------+
                                   |
                                   v
                      +------------------------------+
                      |     Telemetry Store Service  |
                      |   http://localhost:9100      |
                      |                              |
                      | • Stores latest readings     |
                      | • Machine health state       |
                      | • Simulated alert events     |
                      +------------------------------+

                         ↑
                         |
                WSO2 API Manager
           (Service Catalog + API Lifecycle)

                         ↑
                         |
                 AI Agent (Ballerina)
```

---

# 🧠 **3. Agentic Layer – Manufacturing Operations AI Assistant**

The AI assistant is implemented in **Ballerina** and uses a **tool-calling architecture** to interact with the integration layer.

The agent **never accesses backend systems directly**.
All data flows through the **WSO2 Micro Integrator APIs**.

### Capabilities

The assistant can:

* Retrieve **full order context** (ERP + MES)
* Retrieve **latest telemetry readings**
* Retrieve **plant health summary**
* Inject telemetry events to simulate machine behavior
* Explain operational risks
* Identify production bottlenecks
* Provide contextual operational insights

---

### AI Tools

| Tool                    | Purpose                                         |
| ----------------------- | ----------------------------------------------- |
| **GetOrderContextTool** | Calls MI composite API → ERP + MES merged order |
| **GetLastReadingsTool** | Retrieves latest machine telemetry              |
| **GetPlantSummaryTool** | Retrieves plant-level health summary            |
| **IngestTelemetryTool** | Injects telemetry via MI                        |

Agent guarantees:

✔ Responses in **Brazilian Portuguese**
✔ Strict system prompt enforcement
✔ Never bypasses MI
✔ Structured error envelopes
✔ Deterministic tool usage

---

# 📂 **4. Repository Structure**

```
.
├── docker-compose.yml
├── backend/
│   └── docker/
│       ├── erp-service/
│       ├── mes-service/
│       ├── telemetry-store/
│       ├── mqtt-broker/
│       └── mqtt-bridge/
│
├── oem-visibility-demo/
│   ├── deployment/
│   │   ├── deployment.toml
│   │   └── libs/
│   │
│   ├── src/main/wso2mi/
│   │   ├── artifacts/
│   │   │   ├── apis/
│   │   │   ├── sequences/
│   │   │   ├── endpoints/
│   │   │   └── inbound-endpoints/
│   │   │
│   │   └── resources/
│   │       ├── api-definitions/
│   │       └── metadata/
│   │
│   └── target/
│       └── oem-visibility-demo_1.0.0.car
│
├── oem_visibility_agent/
│   ├── agents.bal
│   ├── tools.bal
│   ├── main.bal
│   └── types.bal
│
└── openapi/
```

---

# 🚀 **5. Running the Demo**

From the **repository root**, run:

```bash
docker compose up --build
```

The entire environment will start automatically.

---

### Available services

| Service               | Port | Description                        |
| --------------------- | ---- | ---------------------------------- |
| MQTT Broker           | 1884 | Machine telemetry ingestion        |
| ERP Service           | 9001 | Order header information           |
| MES Service           | 9002 | Production execution status        |
| Telemetry Store       | 9100 | Machine health storage             |
| WSO2 Micro Integrator | 8290 | Integration layer                  |
| WSO2 API Manager      | 9443 | API Publisher / Dev Portal         |
| AI Agent              | 8293 | Manufacturing operations assistant |

---

# 🧪 **6. Testing End-to-End**

## Publish MQTT telemetry

```bash
mosquitto_pub -h localhost -p 1884 \
-t "oem/telemetry/SP1/M-100" \
-m '{"machine":"M-100","plant":"SP1","ts":"2025-12-04T10:05:00Z","temperature":81.3,"vibration":0.9}'
```

---

## Retrieve telemetry readings

```bash
curl -s http://localhost:8290/internal/machine-health/telemetry/last-readings | jq
```

---

## Retrieve plant health summary

```bash
curl -s http://localhost:8290/internal/machine-health/summary | jq
```

---

## Unified order view

```bash
curl -s http://localhost:8290/internal/orders/orders/1001 | jq
```

---

## HTTP telemetry ingestion

```bash
curl -s -X POST http://localhost:8290/internal/machine-health/telemetry \
-H "Content-Type: application/json" \
-d '{"machine":"M-200","plant":"SP1","ts":"2025-12-04T11:00Z","temperature":70,"vibration":0.14}'
```

---

# 🤖 **7. Testing the AI Agent**

### Agent health

```bash
curl -s http://localhost:8293/v1/health | jq
```

---

### Ask about an order

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H "Content-Type: application/json" \
-d '{
"sessionId": "sess1",
"message": "Qual é o status da ordem 1001?"
}'
```

---

### Ask about plant health

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H "Content-Type: application/json" \
-d '{
"sessionId": "sess2",
"message": "Resumo da saúde das máquinas da planta SP1."
}'
```

---

### Inject telemetry via AI

```bash
curl -s -X POST http://localhost:8293/v1/chat \
-H "Content-Type: application/json" \
-d '{
"sessionId": "sess3",
"message": "Injete telemetria na máquina M-300 com temperatura 92."
}'
```

---

# 🛠 **8. WSO2 Integration Components**

### APIs

| Artifact                   | Description                     |
| -------------------------- | ------------------------------- |
| `OrderCompositeAPI.xml`    | Composite call to ERP + MES     |
| `MachineHealthService.xml` | Telemetry ingestion & analytics |

---

### MQTT Inbound

```
TelemetryMQTTInbound.xml
```

Consumes telemetry from:

```
oem/telemetry/{plant}/{machine}
```

---

### Sequences

```
TelemetryNormalizationSeq.xml
CommonInSeq.xml
CommonOutSeq.xml
CommonFaultSeq.xml
```

---

### Endpoints

```
ERPServiceEP.xml
MESServiceEP.xml
```

---

### API Manager Service Catalog

The Micro Integrator publishes deployed services to **WSO2 API Manager Service Catalog**, allowing:

* API creation from existing integrations
* governance and lifecycle management
* secure exposure of backend services

---

# 🏭 **9. Why This Matters for Industrial Enterprises**

### OT / IT Convergence

Factory → MES → ERP → Integration → Analytics.

### Operational Visibility

Production status + machine state + alerts in one digital thread.

### Predictive Maintenance Foundation

Telemetry analysis → alerts → AI insights → human action.

### Digital Thread Enablement

Order → Routing → Telemetry → Execution → Insights.

### AI-Assisted Operations

Natural-language operational intelligence for:

* production supervisors
* maintenance engineers
* quality teams

### Composable Integration Architecture

Extendable to:

* SCADA
* CMMS
* Historian systems
* SAP / Oracle ERP
* Kafka pipelines
* streaming analytics