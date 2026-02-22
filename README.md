#  ISL Glove AI System

##  Overview

This repository contains a complete system consisting of:

1.  **Flutter Frontend App**
2.  **TTS Backend (Node.js)**
3.  **ISL Glove AI Backend (Node.js + Python ML)**

The system processes sensor data, performs machine learning predictions, and converts text to speech using a distributed backend architecture.

---

##  Project Structure

```root/
│
├── app/ # Flutter frontend application
│
├── tts-backend/ # Text-to-Speech backend (Node.js)
│ └── README.md
│
├── isl-glove-AI/ # ML + Node.js backend
│ ├── ml/
│ │ ├── train.py
│ │ └── predict.py
│ │── src/
│ └── README.md
└── README.md 
```

---

##  Technologies Used

- Node.js
- Python
- Flutter
- RabbitMQ
- Docker
- Machine Learning

---

##  System Requirements

- Node.js (v18+ recommended)
- Python (3.10 recommended)
- Docker
- Docker Compose
- RabbitMQ (via Docker)

---

# Full System Setup

---

##  Clone Repository

```bash
git clone <your-repository-url>
cd <repository-folder>

```
## Start RabbitMQ Using Docker

```
docker run -d \
  --hostname rabbitmq \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  rabbitmq:3-management

```
- RabbitMQ Dashboard:

`http://localhost:15672`

- Default Credentials:


- username: ` guest`
- password: `guest`

## Start Backend

```
cd backend 
npm install
npm start
```
## Start ISL_Golve_AI

```
cd isl-glove-AI 
npm install
npm start
```

## Communication Flow

- Flutter app sends data to Node.js backend
- Backend publishes message to RabbitMQ
- ML or TTS service consumes the message
- Service processes request
- Response is sent back through queue
- Backend returns response to frontend

## Documentation References

| Component    | Documentation             |
| ------------ | ------------------------- |
| Frontend     | `\app\README.md`          |
| TTS Backend  | `\backend\README.md`  |
| ISL Glove AI | `\isl-glove-AI\README.md` |


# How to contribute 

- Make a fork of repo 
- Change branch to dev with cmd - `git switch -c dev `
- Make changes
- Create a pull request 
