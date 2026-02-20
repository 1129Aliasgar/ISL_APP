# G-ONE Backend

Backend API server for G-ONE ISL (Indian Sign Language) translation app with system text-to-speech functionality.

## Features

- Text-to-Speech conversion using system TTS (`say` on macOS, `espeak` on Linux, PowerShell on Windows)
- RESTful API endpoints
- Support for voice, speed, volume, and pitch customization
- Cross-platform support

## Installation

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

Edit `.env` file:
```
PORT=8000
NODE_ENV=development
CORS_ORIGIN=*
```

3. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## Platform Requirements

- **macOS**: `say` command (built-in)
- **Linux**: `espeak` or `spd-say` (install with `sudo apt-get install espeak` or `sudo apt-get install speech-dispatcher`)
- **Windows**: PowerShell with SAPI.SpVoice (built-in)

## API Endpoints

### POST /api/speak
Convert text to speech using system TTS.

**Request Body:**
```json
{
  "text": "Hello, how are you?",
  "language": "hi",
  "voice": "Alex",
  "speed": 1.0,
  "volume": 0.8,
  "pitch": 1.0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Text spoken successfully",
  "data": {
    "text": "Hello, how are you?",
    "language": "hi",
    "voice": "Alex",
    "speed": 1.0,
    "volume": 0.8,
    "pitch": 1.0,
    "platform": "darwin"
  }
}
```

### POST /api/text-to-speech
Legacy endpoint (redirects to `/api/speak`).

### GET /api/voices
Get available voices for the current platform.

**Response:**
```json
{
  "success": true,
  "data": [
    { "code": "Alex", "name": "Alex" },
    { "code": "Samantha", "name": "Samantha" }
  ],
  "platform": "darwin"
}
```

### GET /health
Health check endpoint.

## Supported Languages

- `hi` - Hindi
- `en` - English
- `bn` - Bengali
- `gu` - Gujarati
- `mr` - Marathi
- `ta` - Tamil
- `te` - Telugu
- `pa` - Punjabi

## Project Structure

```
backend/
├── controllers/
│   └── textToSpeechController.js
├── routes/
│   └── api.js
├── audio/              # Generated audio files
├── server.js
├── package.json
└── README.md
```

