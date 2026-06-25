# External Gesture Device — Integration Guide

This document is for the **separate laptop** that runs YOLO, maps gestures to sensor templates, and streams data to the ISL backend over WebSocket.

The Flutter app does **not** stream sensor readings. It only:

1. Runs on-phone YOLO (or test buttons) to detect a gesture label
2. Calls your device: `POST /gesture`
3. Listens on the backend **predict socket** for the final text and speaks it

Your laptop handles template mapping and the **sensor socket** stream.

---

## URLs

| Service | Example |
|---------|---------|
| **Your device (this laptop)** | `https://7767-2401-4900-c0c4-8520-987-823d-1946-1bf4.ngrok-free.app` |
| **ISL backend (sensor + predict sockets)** | `https://burthensome-emerald-libidinally.ngrok-free.dev` |
| **Flutter `GESTURE_DEVICE_URL`** | Same as your device ngrok URL |
| **Flutter `WS_BASE_URL`** | Backend ngrok URL (no `/api` suffix) |

---

## What you must expose on the laptop

### `POST /gesture`

Called by the Flutter app when a gesture is detected.

**Request**

```json
{
  "gesture": "A",
  "deviceId": "glove_01"
}
```

**Your code should**

1. Map `gesture` → hardcoded sensor window (50 timesteps × 11 features)
2. Connect to backend **`/sensor`** socket
3. Stream readings → `stream:end` → backend predicts once
4. Return HTTP success (Flutter gets text via its own predict socket)

**Response**

```json
{
  "success": true,
  "gesture": "A",
  "deviceId": "glove_01",
  "message": "Sensor stream completed"
}
```

---

## Backend sensor socket protocol

Connect with Socket.IO client to:

```
<BACKEND_URL>/sensor
```

Use transport `websocket`. For ngrok, add header:

```
ngrok-skip-browser-warning: true
```

### Environment variables (laptop `.env`)

```env
BACKEND_URL=https://burthensome-emerald-libidinally.ngrok-free.dev
DEVICE_TOKEN=local-dev-device-token
STREAM_INTERVAL_MS=15
```

`DEVICE_TOKEN` must match `DEVICE_TOKEN` in the ISL backend `.env`.

---

## Socket events (in order)

### 1. Connect & join

```javascript
const socket = io(`${BACKEND_URL}/sensor`, {
  transports: ['websocket'],
  extraHeaders: { 'ngrok-skip-browser-warning': 'true' },
});

socket.emit('join', {
  deviceId: 'glove_01',
  deviceToken: process.env.DEVICE_TOKEN,
});

socket.on('joined', (data) => {
  // { deviceId, room: 'sensor:glove_01' }
});
```

### 2. Start stream (clears backend buffer)

```javascript
socket.emit('stream:start', { deviceId: 'glove_01' });
```

### 3. Send readings (repeat for each timestep)

Each row in your template is 11 numbers: `[flex×5, accel×3, gyro×3]`.

```javascript
socket.emit('sensor:reading', {
  deviceId: 'glove_01',
  timestamp: new Date().toISOString(),
  sensors: {
    flex: [0.1, 0.2, 0.3, 0.4, 0.5],
    accel: [0.6, 0.7, 0.8],
    gyro: [0.9, 1.0, 1.1],
  },
  end: false,
});
```

Backend replies with:

```json
{ "deviceId": "glove_01", "bufferedCount": 12 }
```

### 4. End stream (triggers one ML prediction)

```javascript
socket.emit('stream:end', { deviceId: 'glove_01' });
```

Backend then:

- Runs `model.tflite` **once**
- Emits to **`/predict`** room `predict:glove_01`:

```json
{
  "deviceId": "glove_01",
  "text": "B",
  "character": "B",
  "confidence": 0.71,
  "probabilities": { "A": 0.12, "B": 0.71, "C": 0.17 },
  "timestamp": "2026-06-25T12:00:00.000Z"
}
```

Sensor socket receives:

```json
{ "deviceId": "glove_01", "prediction": { "character": "B", ... } }
```

---

## Reference implementation (Node.js)

Add to your laptop project:

```javascript
const { io } = require('socket.io-client');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function streamTemplateToBackend({ backendUrl, deviceToken, deviceId, data, intervalMs = 15 }) {
  const socket = io(`${backendUrl}/sensor`, {
    transports: ['websocket'],
    extraHeaders: { 'ngrok-skip-browser-warning': 'true' },
  });

  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('Socket timeout')), 10000);
    socket.on('connect', () => { clearTimeout(t); resolve(); });
    socket.on('connect_error', reject);
  });

  socket.emit('join', { deviceId, deviceToken });
  await new Promise((resolve) => socket.once('joined', resolve));

  socket.emit('stream:start', { deviceId });

  for (const row of data) {
    socket.emit('sensor:reading', {
      deviceId,
      timestamp: new Date().toISOString(),
      sensors: {
        flex: row.slice(0, 5),
        accel: row.slice(5, 8),
        gyro: row.slice(8, 11),
      },
      end: false,
    });
    if (intervalMs > 0) await sleep(intervalMs);
  }

  await new Promise((resolve, reject) => {
    socket.once('stream:completed', resolve);
    socket.once('error', (e) => reject(new Error(e.message)));
    socket.emit('stream:end', { deviceId });
  });

  socket.disconnect();
}
```

### `POST /gesture` handler example

```javascript
app.post('/gesture', async (req, res) => {
  const { gesture, deviceId } = req.body;
  const template = getTemplateForGesture(gesture); // your hardcoded map
  if (!template) {
    return res.status(404).json({ success: false, message: 'Unknown gesture' });
  }

  await streamTemplateToBackend({
    backendUrl: process.env.BACKEND_URL,
    deviceToken: process.env.DEVICE_TOKEN,
    deviceId,
    data: template,
  });

  res.json({ success: true, gesture, deviceId });
});
```

---

## Sensor window format

| Field | Value |
|-------|-------|
| Timesteps | **50** (backend pads/interpolates if you send fewer) |
| Features per step | **11** = flex[5] + accel[3] + gyro[3] |
| Labels | Match `isl-glove-AI/ml/labels.json` (e.g. A, B, C, HELLO, HI) |

Build templates from real recorded windows when possible — random numbers may cause wrong backend predictions even when YOLO is correct.

---

## Optional: laptop camera + YOLO (no phone)

Your laptop can run the full pipeline without Flutter sending gestures:

1. Webcam frame → YOLO → gesture label
2. Map → template
3. Stream via sensor socket (same as above)

Flutter can still listen on predict socket if the same `deviceId` is used.

---

## Flutter predict socket (for reference)

The app connects to `<BACKEND_URL>/predict` with:

```json
{ "deviceId": "glove_01", "token": "<JWT from login>" }
```

It listens for `prediction:result` and speaks the text locally (no backend TTS).

---

## Checklist for your laptop code

- [ ] `POST /gesture` accepts `{ gesture, deviceId }`
- [ ] Gesture → 50×11 template map implemented
- [ ] `BACKEND_URL` and `DEVICE_TOKEN` configured
- [ ] Sensor socket: `join` → `stream:start` → N × `sensor:reading` → `stream:end`
- [ ] ngrok exposes your laptop HTTP API
- [ ] Backend ngrok is reachable from the laptop
- [ ] Same `deviceId` as set in the Flutter user profile

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Invalid device token` | Match `DEVICE_TOKEN` on laptop and backend `.env` |
| `No buffered data to predict` | Send at least one `sensor:reading` before `stream:end` |
| Flutter never speaks | Ensure app is **Connected** and `deviceId` matches stream |
| ngrok browser warning | Send `ngrok-skip-browser-warning: true` header |
| Wrong prediction | Use realistic templates aligned with training data |
