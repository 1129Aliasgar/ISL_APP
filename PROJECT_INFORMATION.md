# ISL Glove AI — Project Information

Reference document for the **G-ONE** (ISL Glove AI) platform.

---

## Project Summary

| Field | Detail |
|-------|--------|
| **Name** | G-ONE / ISL Glove AI System |
| **Purpose** | Translate Indian Sign Language gestures from a smart glove into text and spoken audio |
| **Frontend** | Flutter (`app/`) — Android (iOS planned) |
| **Backend** | Single Node.js + Python service (`isl-glove-AI/`) |
| **Database** | MongoDB |
| **ML** | CNN + GRU classifier, exported as TensorFlow Lite (`ml/model.tflite`) |
| **Hardware** | ESP32-based sensor glove |

---

## System Design

The system uses a **monolithic backend** — one Express API handles authentication, sensor ingestion, ML prediction, and text-to-speech. There is no message broker and no reverse-proxy stack in this repository.

```
┌─────────────┐     HTTP/JSON      ┌──────────────────────┐
│  ESP32      │ ─────────────────► │  isl-glove-AI        │
│  Glove      │   /api/sensors     │  (Node.js + Python)  │
└─────────────┘                    │                      │
                                   │  • Buffer windows    │
┌─────────────┐     HTTP/JSON      │  • ML inference      │
│  G-ONE      │ ◄────────────────► │  • gTTS audio        │
│  Flutter    │   /api/auth        │  • JWT auth          │
└─────────────┘   /api/predict     └──────────┬───────────┘
                                              │
                                              ▼
                                    ┌──────────────────────┐
                                    │  MongoDB             │
                                    │  (users, sensors,    │
                                    │   predictions)       │
                                    └──────────────────────┘
```

---

## Repository Layout

```
ISL_APP/
├── app/                          # Flutter mobile app (G-ONE)
│   ├── lib/
│   │   ├── screens/              # UI screens
│   │   ├── services/             # API & auth clients
│   │   └── utils/constants.dart  # API base URL
│   └── pubspec.yaml
│
├── isl-glove-AI/                 # Backend service
│   ├── server.js                 # Entry point
│   ├── src/
│   │   ├── app.js                # Express app & route mounting
│   │   ├── config/               # DB & env
│   │   ├── controllers/          # Request handlers
│   │   ├── services/             # Business logic (ML, TTS, sensors)
│   │   ├── models/               # Mongoose schemas
│   │   ├── routes/               # API routes
│   │   ├── middlewares/          # Auth, validation, errors
│   │   └── validators/           # Joi schemas
│   ├── ml/
│   │   ├── model.tflite          # Pre-trained model (ready to use)
│   │   ├── train.py              # Full training pipeline
│   │   ├── predict.py            # Standalone inference script
│   │   ├── export_tflite.py      # Keras → TFLite export
│   │   ├── seed_mock_data.py     # Sample MongoDB data for training
│   │   └── labels.json           # Gesture class labels
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── package.json
│   └── example.env
│
├── docker-compose.local.yml      # Backend container (local Mongo on host)
├── docker-compose.prod.yml       # Backend container (external Mongo)
├── README.md                     # Quick start & setup guide
└── PROJECT_INFORMATION.md        # This file
```

---

## Technology Stack

### Backend (`isl-glove-AI`)

- **Runtime:** Node.js 18+
- **Framework:** Express 5
- **Database ODM:** Mongoose (MongoDB)
- **Auth:** JWT + bcrypt
- **Validation:** Joi
- **TTS:** gTTS (Google Text-to-Speech)
- **ML runtime:** Python 3.10, TensorFlow, TFLite

### Frontend (`app`)

- **Framework:** Flutter / Dart
- **Platforms:** Android (primary), Windows/Linux/macOS scaffold present

### Infrastructure

- **Docker:** Optional — backend image only
- **MongoDB:** Required — local, Docker host, or Atlas

---

## API Endpoints

Base path: `/api`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Register a new user |
| POST | `/auth/login` | No | Login, returns JWT |
| GET | `/auth/me` | Yes | Current user profile |
| POST | `/sensors` | No* | Ingest ESP32 sensor timestep |
| POST | `/predict` | Varies | Run prediction on sensor window |
| GET | `/predict/latest/:deviceId` | Varies | Latest prediction for device |
| GET | `/audio/:filename` | No | Serve generated speech files |

\* Sensor endpoint is intended for the ESP32 device; protect in production as needed.

### ESP32 sensor payload

```json
{
  "deviceId": "glove_01",
  "timestamp": "2026-02-20T12:00:00.000Z",
  "sensors": {
    "flex": [0, 189, 0, 16, 0],
    "accel": [70, 96, 1631],
    "gyro": [13, 12, 4]
  },
  "gestureLabel": "hello",
  "end": false
}
```

Send `"end": true` on the final timestep of a gesture to trigger prediction.

---

## Environment Variables

Copy `isl-glove-AI/example.env` to `.env`.

| Variable | Required | Default / Example | Purpose |
|----------|----------|-------------------|---------|
| `PORT` | No | `5000` | HTTP listen port |
| `NODE_ENV` | No | `development` | Runtime mode |
| `MONGO_URI` | Yes | `mongodb://127.0.0.1:27017/isl_glove` | MongoDB connection |
| `MODEL_PATH` | No | `ml/model.tflite` | TFLite model path |
| `PYTHON_PATH` | No | `python` | Python binary for ML subprocess |
| `JWT_SECRET` | Yes | — | JWT signing secret |
| `PUBLIC_BASE_URL` | Yes | `http://localhost:5000` | Base URL embedded in audio links |

**Docker local:** `MONGO_URI=mongodb://host.docker.internal:27017/isl_glove`

**Docker prod:** Set `MONGO_URI`, `JWT_SECRET`, and `PUBLIC_BASE_URL` via environment or `.env` before `docker compose -f docker-compose.prod.yml up`.

---

## ML Pipeline

### Included model

`isl-glove-AI/ml/model.tflite` is **already trained and committed**. The backend uses it for inference out of the box — **no training step is required** to run the system.

### Model architecture

- Input: sliding window of **50 timesteps × 11 features** (flex, accel, gyro)
- CNN → MaxPooling → GRU → Dense → Softmax
- Output: character classes (e.g. A, B, C) from `labels.json`

### Regenerating the model

| Step | Command | Notes |
|------|---------|-------|
| 1. Virtual env | `py -3.10 -m venv venv` | Python **3.10 only** |
| 2. Dependencies | `pip install -r requirements.txt` | From `isl-glove-AI/` |
| 3. Seed data (optional) | `python ml/seed_mock_data.py` | Populates MongoDB with sample windows |
| 4. Train | `python ml/train.py` | Reads `sensorwindows` from MongoDB |
| 5. Output | `ml/model.tflite` | Auto-exported at end of `train.py` |

**Training outputs:** `autoencoder_model.h5`, `gesture_model.h5`, `normalizer.npz`, `labels.json`, `model.tflite`

**Production rule:** Run training offline only. Deploy with the exported `.tflite` file.

---

## Flutter App Configuration

| Setting | Location | Notes |
|---------|----------|-------|
| API base URL | `app/lib/utils/constants.dart` | `baseUrl` must point to your backend `/api` prefix |
| App name | `AppConstants.appName` | Displayed as **G-ONE** |

### Build commands

```bash
# Development
cd app && flutter pub get && flutter run

# Release APK
flutter build apk --release --no-tree-shake-icons
```

APK output: `app/build/app/outputs/flutter-apk/app-release.apk`

---

## Docker

### Images & compose files

| File | Use case |
|------|----------|
| `docker-compose.local.yml` | Dev — backend on port 5000, Mongo on host |
| `docker-compose.prod.yml` | Prod — external Mongo (e.g. Atlas) |
| `isl-glove-AI/Dockerfile` | Node 18 + Python 3.10 multi-stage image |

### Local Docker checklist

1. `docker network create isl-network` (first time only)
2. MongoDB running on host port `27017`
3. `docker compose -f docker-compose.local.yml up --build`

### Production Docker checklist

1. Set `MONGO_URI`, `JWT_SECRET`, `PUBLIC_BASE_URL`
2. `docker compose -f docker-compose.prod.yml up --build -d`

---

## MongoDB Collections

| Collection | Purpose |
|------------|---------|
| `users` | Registered app users |
| `sensorwindows` | Buffered / stored sensor windows for training |
| `predictionresults` | Prediction history per device |
| `audioassets` | Metadata for generated TTS files |

Database name: **`isl_glove`** (default)

---

## Authors & License

**Contributors**

- 1129Aliasgar
- faizansk25
- meetagrawal12
- roshnishaikh2105-cloud

**License:** MIT

---

## Related Docs

- [README.md](README.md) — Quick start and setup
- [isl-glove-AI/README.md](isl-glove-AI/README.md) — Backend & ML deep dive
- [app/README.md](app/README.md) — Flutter app overview
