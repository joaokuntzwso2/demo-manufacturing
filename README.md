# **OEM Visibility Demo – Manufacturing Operations Visibility Using WSO2 Micro Integrator + MQTT + Node.js Backends**

This repository delivers a **complete, runnable manufacturing visibility scenario**, showing how WSO2 Micro Integrator unifies:

* **Operational Technology (OT)**: Machine telemetry via MQTT
* **Information Technology (IT)**: ERP & MES systems
* **Real-time machine health**: Normalization, ingestion & alerting
* **Unified enterprise API** for OEM dashboards, supervisors, and analytics

The repo includes:

✔ ERP & MES mock backends (Node.js)
✔ Telemetry Store (Node.js) with alert logic
✔ Mosquitto MQTT broker
✔ WSO2 MI integration artifacts (APIs, sequences, inbound, endpoints)
✔ Fully orchestrated Docker Compose environment

---

# **1. Repository Structure (Your Actual Folder Layout)**

```
Manufacturing/
├── README.md        ← this file
├── backend/
│   └── docker/
│       ├── docker-compose.yml
│       ├── erp-service/
│       │   ├── Dockerfile
│       │   └── server.js
│       ├── mes-service/
│       │   ├── Dockerfile
│       │   └── server.js
│       ├── telemetry-store/
│       │   ├── Dockerfile
│       │   └── server.js
│       └── mqtt-broker/
│           └── mosquitto.conf
└── oem-visibility-demo/         ← WSO2 MI Integration Project
    ├── deployment/
    ├── src/main/wso2mi/artifacts/
    │   ├── apis/
    │   ├── endpoints/
    │   ├── inbound-endpoints/
    │   └── sequences/
    └── target/oem-visibility-demo_1.0.0.car
```

Everything you need to run the demo is here.

---

# **2. High-Level Architecture**

```
                                 +----------------------+
                                 |   ERP Backend (Node) |
                                 |   http://localhost:9001
                                 +----------------------+

                                 +----------------------+
                                 |   MES Backend (Node) |
Frontend (Postman, Curl)  --->   |   http://localhost:9002
/internal/orders/{id}            +----------------------+

+---------------------------------------------------------------+
|                 WSO2 MICRO INTEGRATOR (MI)                    |
|                                                               |
| APIs:                                                         |
|  • /internal/orders → merges ERP + MES                        |
|  • /internal/machine-health → HTTP telemetry ingestion        |
|                                                               |
| MQTT Inbound Endpoint:                                        |
|  • Topic: oem/telemetry/{plant}/{machine}                     |
|  • Executes: TelemetryNormalizationSeq                        |
|                                                               |
| Normalized telemetry forwarded to:                            |
|  → Telemetry Store (Node.js @ localhost:9100)                 |
+---------------------------------------------------------------+

                               ^
                               |
       POST /telemetry (JSON)  |
                               |
                     +------------------------+
                     |   Telemetry Store      |
                     |   Alerts + last values |
                     |   http://localhost:9100|
                     +------------------------+

                               ^
                               |
                               |
                    +-------------------------+
                    |   MQTT Broker (Mosquitto)|
                    |      port 1883           |
                    +--------------------------+
```

---

# **3. Running the Backend Environment**

Navigate to:

```
backend/docker/
```

Start everything:

```bash
docker compose up --build
```

This launches:

| Service         | Path                           | Port |
| --------------- | ------------------------------ | ---- |
| mqtt-broker     | backend/docker/mqtt-broker     | 1883 |
| erp-service     | backend/docker/erp-service     | 9001 |
| mes-service     | backend/docker/mes-service     | 9002 |
| telemetry-store | backend/docker/telemetry-store | 9100 |

---

# **4. Backend Implementations**

## **4.1 ERP Service – `backend/docker/erp-service/server.js`**

---

## **4.2 MES Service – `backend/docker/mes-service/server.js`**

---

## **4.3 Telemetry Store – `backend/docker/telemetry-store/server.js`**

✔ Stores last readings
✔ Evaluates thresholds
✔ Emits simulated alerts
✔ Works with MI normalization flow

---

# **5. Deploying and Running WSO2 Micro Integrator**

## **5.1 Build the CAR**

From:

```
oem-visibility-demo/
```

Run:

```bash
mvn clean install
```

The file appears at:

```
oem-visibility-demo/target/oem-visibility-demo_1.0.0.car
```

## **5.2 Deploy to MI**

Copy the CAR:

```bash
cp oem-visibility-demo/target/oem-visibility-demo_1.0.0.car \
  ~/Applications/wso2mi-4.5.0/repository/deployment/server/carbonapps/
```

Start MI:

```bash
~/Applications/wso2mi-4.5.0/bin/micro-integrator.sh
```

Expected logs:

```
Initializing API: MachineHealthService
Initializing API: OrderStatusService
Inbound endpoint deployed: TelemetryMQTTInbound
```

---

# **6. Testing the End-to-End Flow**

---

## **6.1 Publish MQTT Telemetry**

```bash
mosquitto_pub -h localhost -p 1883 \
  -t "oem/telemetry/SP1/M-100" \
  -m '{"machine":"M-100","plant":"SP1","ts":"2025-12-04T10:05:00Z","temperature":81.3,"vibration":0.9}'
```

### ✔ MI Log Output (important!)

Inside MI console you should see:

```
[TelemetryNormalizationSeq] TelemetryNormalizationSeq = Normalizing telemetry message
```

### ✔ Telemetry Store Output (Docker logs)

In the `docker compose up` terminal:

```
=== ALERT EVENTS ===
[
  {
    "type": "TEMP_THRESHOLD_BREACHED",
    "temp": 81.3
  }
]
====================
```

Inspect stored values:

```bash
curl http://localhost:9100/last-readings
```

---

## **6.2 Test Unified Order API**

```bash
curl http://localhost:8290/internal/orders/orders/123
```

Returns:

```json
{
  "orderId": "123",
  "erpRaw": {...},
  "mesRaw": {...}
}
```

---

## **6.3 Test HTTP Telemetry Ingestion**

```bash
curl -X POST http://localhost:8290/internal/machine-health/telemetry \
  -H "Content-Type: application/json" \
  -d '{"machine":"M-200","plant":"SP2","ts":"2025-12-04T11:00Z","temperature":72,"vibration":0.03}'
```

MI log:

```
MachineHealthService = HTTP telemetry ingestion
```

---

# **7. WSO2 Integration Artifacts Overview**

These are located in:

```
oem-visibility-demo/src/main/wso2mi/artifacts/
```

| File                              | Description                                |
| --------------------------------- | ------------------------------------------ |
| **OrderStatusService.xml**        | Calls ERP + MES, merges results            |
| **MachineHealthService.xml**      | HTTP telemetry ingestion                   |
| **TelemetryMQTTInbound.xml**      | MQTT listener                              |
| **TelemetryNormalizationSeq.xml** | Normalizes telemetry and forwards to store |
| **ERPServiceEP.xml**              | Backend endpoint                           |
| **MESServiceEP.xml**              | Backend endpoint                           |

---

# **8. Storytelling – Why This Demo Matters**

This demo illustrates:

### ✔ **OT/IT Convergence**

Bringing machine telemetry (MQTT) into enterprise decision flows.

### ✔ **Unified operations visibility**

ERP + MES + Machine telemetry → one API.

### ✔ **Event-driven operations**

Telemetry triggers alerts in real time.

### ✔ **Low-code Enterprise Integration**

MI Designer shows all mediation visually.

### ✔ **Digital Thread Foundation**

Orders, equipment, and health data linked across systems.

---

# **9. Summary**

You now have a **production-grade demonstration** of:

* MQTT → WSO2 MI → Normalization → Telemetry Store
* ERP+MES unified APIs
* Full Dockerized backend
* Real-time alerting and observability

Perfect for demos, PoCs, stakeholder presentations, and OT/IT modernization scenarios.