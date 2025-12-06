# **OEM Visibility Demo – Unified Manufacturing Operations, Telemetry Intelligence & Agentic Insights**

### *Powered by WSO2 Micro Integrator, MQTT, Node.js Services & AI Agent Layer*

This repository delivers a **full-stack, production-grade manufacturing visibility solution** that demonstrates how modern OEMs can unify:

* **Operational Technology (OT)** — shop-floor machine telemetry via MQTT
* **Information Technology (IT)** — ERP & MES enterprise systems
* **Real-time machine health analytics** — telemetry normalization, alerting & storage
* **Enterprise-grade integration** — orchestration, mediation, resiliency, observability
* **AI-driven insights** — an **Agentic Manufacturing Operations Assistant**

All components run end-to-end through **Docker Compose** and emulate a mature Industry 4.0 architecture.

---

# ⭐ **1. What This Demo Enables (Executive Summary)**

This solution showcases how an OEM or industrial manufacturer can:

### ✔ **Achieve real-time operations visibility**

Consolidate ERP orders, MES production status, and machine telemetry into a unified MI-powered API.

### ✔ **Detect anomalies and machine degradation early**

Normalize telemetry and detect temperature/vibration threshold breaches.

### ✔ **Enable OT/IT convergence**

Bring siloed systems (ERP, MES, IoT telemetry) into a single integration backbone.

### ✔ **Provide a digital thread across systems**

Order → Production → Machine Health → Alerts.

### ✔ **Empower supervisors and analysts with AI**

A Ballerina-based **Agentic Operations Assistant** uses MI APIs to generate contextual explanations.

### ✔ **Demonstrate a world-class integration backbone**

Using WSO2 MI for:

* Composite integrations
* MQTT ingest flows
* Transformation & normalization
* Observability & correlation IDs
* Robust mediation patterns

---

# 🏗 **2. System Architecture Overview**

```
                              +------------------------+
                              |      ERP Service       |
Frontends / AI Agent →        |   http://localhost:9001|
                              +------------------------+
                                        |
                                        |
                              +------------------------+
                              |      MES Service       |
                              |   http://localhost:9002|
                              +------------------------+
                                        |
                                        v
+---------------------------------------------------------------+
|                  WSO2 MICRO INTEGRATOR (MI)                   |
|                                                               |
| Facade APIs:                                                  |
|   • GET /internal/orders/orders/{id}                          |
|         ↳ Composite call: ERP → MES → Merge JSON              |
|                                                               |
|   • POST /internal/machine-health/telemetry                   |
|         ↳ Normalizes telemetry and forwards to TelemetryStore |
|                                                               |
|   • GET /internal/machine-health/telemetry/last-readings      |
|   • GET /internal/machine-health/summary                      |
|                                                               |
| MQTT Inbound:                                                 |
|   • Topic: oem/telemetry/{plant}/{machine}                    |
|   • Runs TelemetryNormalizationSeq                            |
+---------------------------------------------------------------+
                                        |
                                        v
                          +------------------------------+
                          |     Telemetry Store Service  |
                          |   http://localhost:9100      |
                          |   • Saves last readings      |
                          |   • Health classification     |
                          |   • Emits simulated alerts    |
                          +------------------------------+
```

---

# 🧠 **3. Agentic Layer – Manufacturing Operations AI Assistant**

The AI assistant is implemented in **Ballerina** and uses the **new tool-calling architecture**.

### The agent can:

* Retrieve **full order context** (ERP header + MES execution)
* Retrieve **latest telemetry readings**
* Retrieve **plant-level health summary**
* Inject telemetry to simulate readings
* Explain operational risks
* Summarize machine degradation
* Provide actionable insights

### **AI Tools (Ballerina)**

| Tool Name               | Purpose                                       |
| ----------------------- | --------------------------------------------- |
| **GetOrderContextTool** | Calls MI composite API → ERP+MES merged order |
| **GetLastReadingsTool** | Calls MI last readings API                    |
| **GetPlantSummaryTool** | Calls MI summary API                          |
| **IngestTelemetryTool** | Posts telemetry to MI for normalization       |

✔ Agent responds **in Brazilian Portuguese**
✔ Uses the strict system prompt
✔ Never bypasses MI; all data goes through integration layer
✔ Does not hallucinate data
✔ Uses structured envelopes for errors & results

---

# 📂 **4. Repository Structure**

```
backend/
├── docker-compose.yml
├── erp-service/
├── mes-service/
├── telemetry-store/
├── mqtt-broker/
└── mqtt-bridge/

oem-visibility-demo/
├── target/*.car
└── src/main/
    ├── wso2mi/
    │   ├── apis/
    │   ├── sequences/
    │   ├── endpoints/
    │   ├── inbound-endpoints/
    │   └── synapse-config/
    └── ballerina/
        ├── agents.bal
        ├── tools.bal
        ├── config.bal
        ├── types.bal
        └── main.bal
```

---

# 🚀 **5. Running the Demo**

From:

```
backend/docker/
```

Run:

```bash
docker compose up --build
```

### Available services:

| Service         | Port | Description                           |
| --------------- | ---- | ------------------------------------- |
| MQTT Broker     | 1883 | Machine telemetry ingestion           |
| ERP Service     | 9001 | Order header, customer, value         |
| MES Service     | 9002 | Production progress                   |
| Telemetry Store | 9100 | Machine health storage & alerts       |
| WSO2 MI         | 8290 | Integration layer / composite APIs    |
| AI Agent        | 8293 | Ballerina-based operational assistant |

---

# 🧪 **6. Testing End-to-End**

---

## **6.1 Publish MQTT telemetry**

```bash
mosquitto_pub -h localhost -p 1883 \
  -t "oem/telemetry/SP1/M-100" \
  -m '{"machine":"M-100","plant":"SP1","ts":"2025-12-04T10:05:00Z","temperature":81.3,"vibration":0.9}'
```

---

## **6.2 Retrieve last telemetry readings from MI**

```bash
curl -s http://localhost:8290/internal/machine-health/telemetry/last-readings | jq
```

---

## **6.3 Retrieve plant summary**

```bash
curl -s http://localhost:8290/internal/machine-health/summary | jq
```

---

## **6.4 Unified order view (ERP + MES)**

```bash
curl -s http://localhost:8290/internal/orders/orders/12345 | jq
```

---

## **6.5 HTTP telemetry ingestion via MI**

```bash
curl -s -X POST http://localhost:8290/internal/machine-health/telemetry \
  -H "Content-Type: application/json" \
  -d '{"machine":"M-200","plant":"SP1","ts":"2025-12-04T11:00Z","temperature":70,"vibration":0.14}' | jq
```

---

# 🤖 **7. Testing the AI Agent**

---

## **Agent health**

```bash
curl -s http://localhost:8293/v1/health | jq
```

---

## **Ask about order 12345**

```bash
curl -s -X POST http://localhost:8293/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "sess1",
    "message": "Qual é o status da ordem 12345?"
  }' | jq
```

---

## **Ask about plant health**

```bash
curl -s -X POST http://localhost:8293/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "sess2",
    "message": "Resumo da saúde das máquinas da planta SP1."
  }' | jq
```

---

## **Ask the agent to inject telemetry**

```bash
curl -s -X POST http://localhost:8293/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "sess3",
    "message": "Injete telemetria na máquina M-300 com temperatura 92."
  }' | jq
```

---

# 🛠 **8. WSO2 Integration Components**

### **APIs**

| Name                    | Purpose                                    |
| ----------------------- | ------------------------------------------ |
| `OrderCompositeAPI.xml` | Calls ERP + MES → merges JSON              |
| `MachineHealthAPI.xml`  | Telemetry ingest + last-readings + summary |

### **MQTT Inbound**

* `TelemetryMQTTInbound.xml`

### **Sequences**

* `TelemetryNormalizationSeq.xml`
* `ForwardToTelemetryStoreSeq.xml`

### **Endpoints**

* `ERPServiceEP.xml`
* `MESServiceEP.xml`
* `TelemetryStoreEP.xml`

### **Agent Layer (Ballerina)**

* Tools call MI only
* Correlation IDs end-to-end
* Standard envelopes for success/error
* Retry-aware, robust, deterministic behavior

---

# 🏭 **9. Why This Matters for OEMs & Industrial Enterprises**

### 🔧 OT/IT Convergence

Factory → MES → ERP → MI → BI in one pipeline.

### 📊 True Operational Visibility

Order progress + machine state + alerts in one digital thread.

### ⚠️ Predictive Maintenance Foundation

Temperature/vibration detection → alerts → BI agent → human action.

### 🤝 Digital Thread Enablement

Order → Routing → Telemetry → Execution → Insights.

### 🧠 AI-Assisted Operations

Natural-language insights for:

* production supervisors
* maintenance engineers
* quality leaders

### 🧩 Composable Integration Architecture

Extendable into:

* SCADA
* CMMS
* Historian
* SAP/Oracle ERPs
* Kafka pipelines

---

# ✅ **10. Summary**

This repository demonstrates a **modern Industry 4.0 integration architecture**, including:

* MQTT machine telemetry
* Normalization, routing & alerting
* Unified ERP + MES view via composite integration
* Robust API-led orchestration
* Real-time analytics via telemetry-store
* AI-powered operational insights
* Fully Dockerized demo stack