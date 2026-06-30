# FaceWatch Backend Architecture — Next Phase

## System Overview

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│  50× RTSP   │────▶│   Ingester   │────▶│   Redis      │────▶│   Worker    │
│   Cameras   │     │   (FFmpeg)   │     │   Streams    │     │   (Celery)  │
└─────────────┘     └──────────────┘     └──────────────┘     └──────┬──────┘
                                                                     │
                          ┌──────────────────────────────────────────┘
                          ▼
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Flutter    │◀───▶│  FastAPI     │◀───▶│  PostgreSQL  │
│  Mobile App │     │  REST API    │     │  + pgvector  │
└─────────────┘     └──────┬───────┘     └──────────────┘
                           │
                    ┌──────▼───────┐
                    │  WebSocket   │
                    │  Real-time   │
                    │  Alerts      │
                    └──────────────┘
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| API Framework | FastAPI (Python 3.12+) |
| Face Inference | InsightFace / ArcFace ONNX |
| Task Queue | Celery + Redis |
| Message Broker | Redis Streams |
| Database | PostgreSQL 16 + pgvector |
| Vector Storage | pgvector (0.8+), IVF index |
| RTSP Ingestion | FFmpeg + OpenCV |
| GPU Runtime | NVIDIA Triton / ONNX Runtime CUDA |
| Monitoring | Prometheus + Grafana + Loki |
| Container | Docker + Docker Compose |
| Auth | JWT (RS256) + Keycloak |
| Reverse Proxy | Nginx |

## Directory Structure

```
backend/
├── docker-compose.yml
├── Dockerfile.api
├── Dockerfile.worker
├── .env.example
├── alembic/
│   └── versions/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI entry point
│   ├── config.py             # Pydantic Settings
│   ├── dependencies.py       # DI: DB session, auth, etc.
│   ├── api/
│   │   ├── __init__.py
│   │   ├── auth.py           # POST /auth/login, /auth/refresh
│   │   ├── cameras.py        # CRUD /cameras
│   │   ├── alerts.py         # GET/PATCH /alerts
│   │   ├── faces.py          # /register-face, /identify
│   │   ├── dashboard.py      # GET /dashboard/stats
│   │   └── ws.py             # WebSocket /ws/alerts
│   ├── models/
│   │   ├── __init__.py
│   │   ├── tenant.py
│   │   ├── user.py
│   │   ├── camera.py
│   │   ├── alert.py
│   │   └── face_embedding.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── camera.py
│   │   ├── alert.py
│   │   └── face.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── face_service.py       # InsightFace wrapper
│   │   ├── liveness_service.py   # Anti-spoofing
│   │   ├── analytics_service.py  # Dwell, frequency, density
│   │   └── notification_service.py
│   └── core/
│       ├── __init__.py
│       ├── security.py       # JWT encode/decode
│       ├── database.py       # SQLAlchemy async engine
│       └── redis.py          # Redis connection
├── worker/
│   ├── __init__.py
│   ├── celery_app.py
│   ├── tasks/
│   │   ├── __init__.py
│   │   ├── detection.py     # consume Redis stream → detect → embed
│   │   ├── recognition.py   # match embedding against pgvector
│   │   └── analytics.py     # compute dwell/crowd stats
│   └── face_processor.py    # InsightFace model loading
├── ingester/
│   ├── __init__.py
│   ├── rtsp_client.py       # cv2.VideoCapture per camera
│   └── frame_pusher.py      # push frames to Redis stream
└── tests/
    ├── conftest.py
    ├── test_api/
    └── test_worker/
```

## Database Schema (Key Tables)

```sql
-- Multi-tenant isolation via tenant_id on every table
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    max_cameras INT DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'operator', 'viewer')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cameras (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name TEXT NOT NULL,
    location TEXT,
    rtsp_url TEXT NOT NULL,
    protocol TEXT DEFAULT 'rtsp',
    status TEXT DEFAULT 'offline',
    fps INT DEFAULT 15,
    is_detecting BOOLEAN DEFAULT true,
    is_recording BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE persons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name TEXT NOT NULL,
    is_blacklisted BOOLEAN DEFAULT false,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE face_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    embedding vector(512) NOT NULL,  -- pgvector
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_face_embeddings_tenant ON face_embeddings(tenant_id);
CREATE INDEX idx_face_embeddings_vector ON face_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    camera_id UUID NOT NULL REFERENCES cameras(id),
    person_id UUID REFERENCES persons(id),
    type TEXT NOT NULL,
    severity TEXT DEFAULT 'warning',
    status TEXT DEFAULT 'unacknowledged',
    confidence REAL,
    snapshot_url TEXT,
    message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES users(id)
);

CREATE TABLE detections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    camera_id UUID NOT NULL REFERENCES cameras(id),
    person_id UUID REFERENCES persons(id),
    confidence REAL,
    face_url TEXT,
    dwell_seconds REAL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- Partition by month for retention
CREATE INDEX idx_detections_tenant_time ON detections(tenant_id, created_at DESC);
```

## API Endpoints

### Authentication
```
POST   /api/v1/auth/login          # Returns JWT + refresh token
POST   /api/v1/auth/refresh        # Refresh access token
POST   /api/v1/auth/logout         # Invalidate refresh token
GET    /api/v1/auth/profile        # Current user profile
```

### Cameras
```
GET    /api/v1/cameras             # List cameras (tenant-scoped)
GET    /api/v1/cameras/:id         # Camera detail
PATCH  /api/v1/cameras/:id         # Update (toggle detection/recording)
GET    /api/v1/cameras/:id/stream  # Get HLS/WebRTC stream URL
POST   /api/v1/cameras/:id/snapshot # Trigger manual snapshot
```

### Alerts
```
GET    /api/v1/alerts                      # Paginated, filterable
GET    /api/v1/alerts/:id                  # Alert detail
PATCH  /api/v1/alerts/:id/acknowledge      # Mark acknowledged
PATCH  /api/v1/alerts/:id/dismiss          # Dismiss
PATCH  /api/v1/alerts/:id/escalate         # Escalate to admin
GET    /api/v1/alerts/count                # Count by status
```

### Faces (Recognition)
```
POST   /api/v1/faces/register             # Register face (upload image → embedding)
POST   /api/v1/faces/identify             # Identify face from image
POST   /api/v1/faces/enroll               # Bulk enroll (multi-image)
DELETE /api/v1/faces/:person_id           # Remove person + embeddings
```

### Persons (Watchlist)
```
GET    /api/v1/persons                    # List all persons
POST   /api/v1/persons                    # Create person record
PATCH  /api/v1/persons/:id                # Update (blacklist status, notes)
DELETE /api/v1/persons/:id                # Remove person
```

### Dashboard
```
GET    /api/v1/dashboard/stats            # Aggregated stats for tenant
```

### WebSocket
```
WS     /ws/alerts?token=<jwt>             # Real-time alert stream
```

## Ingestion Pipeline

### RTSP → Frame → Redis Stream

```python
# ingester/rtsp_client.py
import cv2
import redis
import json
import threading
from time import sleep

r = redis.Redis(host='redis', port=6379)

def ingest_rtsp(camera_id: str, rtsp_url: str, fps: int = 15):
    cap = cv2.VideoCapture(rtsp_url)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    frame_interval = 1.0 / fps

    while True:
        ret, frame = cap.read()
        if not ret:
            sleep(1)
            cap.release()
            cap = cv2.VideoCapture(rtsp_url)
            continue

        _, jpeg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
        r.xadd(
            f'frames:{camera_id}',
            {'data': jpeg.tobytes(), 'camera_id': camera_id},
            maxlen=100  # Drop old frames under backpressure
        )
        sleep(frame_interval)

# Launch per camera in thread pool
for camera in get_active_cameras():
    threading.Thread(
        target=ingest_rtsp,
        args=(camera.id, camera.rtsp_url, camera.fps),
        daemon=True
    ).start()
```

### Worker: Consume → Detect → Embed → Match

```python
# worker/tasks/detection.py
from celery import Celery
import insightface
import numpy as np

app = Celery('face_detection', broker='redis://redis:6379/0')
model = insightface.app.FaceAnalysis(name='buffalo_l')
model.prepare(ctx_id=0, det_size=(640, 640))

@app.task(bind=True, max_retries=3)
def process_frame(self, camera_id: str, frame_bytes: bytes):
    img = np.frombuffer(frame_bytes, dtype=np.uint8).reshape(...)
    faces = model.get(img)

    for face in faces:
        embedding = face.embedding.tolist()
        # Store detection in PostgreSQL
        # Match embedding against pgvector (cosine distance)
        # If match above threshold → create alert
        # Push alert to Redis pub/sub → WebSocket broadcast
```

## Anti-Spoofing / Liveness

Integration points in `worker/liveness.py`:

```python
# Three-stage check
def liveness_check(face_crop: np.ndarray, landmarks: dict) -> float:
    # Stage 1: Texture analysis (LBP histogram SVM)
    texture_score = texture_liveness(face_crop)

    # Stage 2: Frequency analysis (FFT)
    frequency_score = frequency_liveness(face_crop)

    # Stage 3: Deepfake detection CNN
    depth_score = depth_liveness(face_crop)

    return 0.3 * texture_score + 0.3 * frequency_score + 0.4 * depth_score
```

Threshold: `match_confidence > 0.6 AND liveness_score > 0.85`

## Analytics Microservices

### 1. Dwell Time Calculator
- Tracks `person_id` per camera across time windows
- Groups consecutive detections within 120s gap
- Alert if dwell exceeds configurable threshold (e.g., 300s)

### 2. Frequent Visitor Tracker
- Materialized view: `visits_7d` grouped by person_id
- `SELECT person_id, COUNT(*) as visits FROM detections WHERE created_at > NOW() - INTERVAL '7 days' GROUP BY person_id`
- Alert if visits > threshold (e.g., 10 visits/day)

### 3. Crowd Density Estimator
- `SELECT COUNT(*) FROM detections WHERE camera_id = $1 AND created_at > NOW() - INTERVAL '1 minute'`
- Bucketed heatmap: group by camera_id + 5-min window
- Alert if count > 80% of zone capacity

## Production Deployment

### Docker Compose

```yaml
version: '3.9'
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: facewatch
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          memory: 4G

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
    volumes:
      - redisdata:/data

  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:${DB_PASSWORD}@postgres/facewatch
      - REDIS_URL=redis://redis:6379/0
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 1G

  worker:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:${DB_PASSWORD}@postgres/facewatch
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 2
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api

  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}

volumes:
  pgdata:
  redisdata:
```

## 30-Day Backend Build Sprint

| Day | Deliverable |
|-----|-------------|
| 1 | Docker Compose scaffold: postgres, redis, API skeleton |
| 3 | `database.py` + alembic migrations (all tables with RLS) |
| 5 | Auth endpoints: `/auth/login`, `/auth/refresh`, JWT middleware |
| 7 | Camera CRUD + RTSP ingester pushing frames to Redis |
| 10 | Celery worker: consume Redis stream → InsightFace detection → embedding |
| 12 | pgvector matching: identify against registered embeddings |
| 14 | Alert creation + CRUD endpoints |
| 16 | WebSocket: Redis pub/sub → `/ws/alerts` broadcast |
| 18 | Face enrollment endpoint (upload → detect → store embedding) |
| 20 | Liveness detection integration (texture + depth CNN) |
| 22 | Analytics: dwell time aggregation (materialized view) |
| 24 | Analytics: crowd density + frequent visitor |
| 26 | Dashboard stats endpoint (aggregation queries) |
| 28 | Prometheus metrics + Grafana dashboard + Loki logging |
| 30 | Load test with 10 simulated RTSP streams, tune thresholds |

## API Client Configuration (Flutter)

The Flutter app connects to `ApiClient` via `baseUrl` stored in `SecureStorage`:

```dart
// Set in main.dart
final baseUrl = (await secureStorage.getBaseUrl()) ?? 'https://api.facewatch.io/v1';

final apiClient = ApiClient(
  baseUrl: baseUrl,
  getToken: () => secureStorage.getToken(),
  onUnauthorized: () => authService.logout(),
);
```

WebSocket connects to the same origin with `wss://`:

```dart
final wsClient = WebSocketClient(
  baseWsUrl: baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://'),
  getToken: () => secureStorage.getToken(),
  onMessage: handleAlert,
);
```

## Environment Variables

```bash
# .env.example
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost/facewatch
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=your-256-bit-secret
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7
MODEL_PATH=/models/insightface
LIVENESS_THRESHOLD=0.85
MATCH_THRESHOLD=0.60
MAX_CAMERAS_PER_TENANT=50
FRAME_QUALITY=70
INGESTION_FPS=15
GRAFANA_PASSWORD=admin
DB_PASSWORD=changeme
```

## Monitoring & Observability

- **Metrics**: Prometheus exports on `/metrics` (request count, latency, worker queue depth, GPU utilization)
- **Logs**: Structured JSON logs → Loki (`tenant_id`, `camera_id`, `trace_id` via `structlog`)
- **Dashboards**: Grafana panels for real-time FPS, detection rate, alert volume per tenant
- **Alerts**: Prometheus AlertManager for worker down, queue backlog > 1000, GPU OOM

## SOC2 Preparation

- **RLS**: Row-level security on all tables via `tenant_id`
- **Audit Log**: `audit_log` table for all mutations (who, what, when)
- **Encryption at Rest**: RDS encryption + encrypted EBS for GPU nodes
- **Encryption in Transit**: TLS 1.3 on all endpoints
- **Access Control**: RBAC with admin/operator/viewer roles
- **Backup**: Daily pg_dump to S3 with 30-day retention
