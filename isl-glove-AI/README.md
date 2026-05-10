#  ISL Glove AI System

AI-powered backend and ML pipeline for Indian Sign Language (ISL) smart glove.

## Architecture

- Single Node backend (`isl-glove-AI`) + MongoDB.
- ESP32 posts sensor timesteps with `deviceId`.
- Backend buffers readings per device until `end=true`.
- On `end=true`, backend predicts gesture and generates speech audio internally.
- Predict response returns JSON + public `audioUrl`.

This project collects real-time hand gesture data from an ESP32-based glove and:

- Stores sensor data in MongoDB
- Creates sliding windows (50 timesteps)
- Saves normalization stats (mean/std) for device-side preprocessing
- Trains an autoencoder for denoising
- Trains a lightweight CNN-GRU character classifier
- Quantizes and exports model to TensorFlow Lite
- Performs character prediction

The system supports:
- Online prediction (via API)
- Offline prediction (via TFLite model)

---

#  Project Structure

```
isl-glove-ai/
│
├── backend/
│   ├── server.js
│   ├── .env
│   ├── src/
│   │   ├── app.js
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── middlewares/
│   │   ├── validators/
│   │   └── utils/
│
├── ml/
│   ├── train.py
│   ├── predict.py
│   ├── model.tflite
|   ├── autoencoder.py
|   ├── classifier.py
|   ├── seed_mock_data.py
│
├── requirements.txt
└── README.md
```

---

#  Sensor Data Flow

ESP32 → `/api/sensors` → MongoDB → Train Model → Export TFLite → `/api/predict`

---

#  ESP32 JSON Schema (IMPORTANT)

ESP32 must send data in this format:

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

When final timestep arrives, send `"end": true`.

## Prediction Behavior

- Variable-length sequences are accepted.
- ML preprocessing resizes every sequence to 50 timesteps:
  - pad (shorter sequences)
  - interpolation compress (longer sequences)
- Labels are dataset-driven from Mongo `gestureLabel` values.

## Local Setup

1. Copy `example.env` to `.env`
2. Install dependencies:
   - `npm install`
   - `pip install -r requirements.txt`
3. Run backend:
   - `npm run dev`

For Docker local stack:

- `docker compose -f ../docker-compose.local.yml up --build`

## Public Audio URLs

Set `PUBLIC_BASE_URL`:

- localhost: `http://localhost:5000`
- ngrok: `https://<your-subdomain>.ngrok-free.app`
- production: your API domain

Model: CNN + GRU

Architecture:

Window (50,11)
→ Conv1D
→ MaxPooling
→ GRU
→ Dense
→ Softmax (3 classes)
→ Argmax
→ Map to ["A","B","C"]
→ Return Character

Why?

- CNN extracts spatial features
- GRU captures time dependencies
- Lightweight for embedded use

---

#  Training

Use Python 3.10 (NOT 3.12)

Create virtual environment:

```
py -3.10 -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Run training:

```
cd ml
python train.py
```

This will generate:

```
autoencoder_model.h5
gesture_model.h5
normalizer.npz
labels.json
model.tflite
```

---

#  Prediction API

POST `/api/predict`

Body:

```json
{
  "data": [
    [11 features],
    ...
    50 timesteps
  ]
}
```

Response:

```json
{
  "prediction": {
    "character": "B",
    "confidence": 0.71,
    "probabilities": {
      "A": 0.12,
      "B": 0.71,
      "C": 0.17
    }
  }
}
```

---

#  Backend Features

✔ Sensor ingestion  
✔ Sliding window creation  
✔ MongoDB storage  
✔ ML training pipeline  
✔ TFLite export  
✔ Prediction endpoint  

---

#  Python Requirements

See `requirements.txt`

---

#  Important Notes

- Training should NOT run in production
- Only use TFLite model for inference in production
- Always use Python 3.10
- Always use virtual environment

---

#  Future Improvements

- Save and reuse scaler
- Add gesture labeling endpoint
- Semi-supervised learning
- ESP32 TinyML deployment

---

#  Author

- 1129Aliasgar
- faizansk25
- meetagrawal12
- roshnishaikh2105-cloud
