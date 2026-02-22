# ISL Glove AI System

![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python&logoColor=white)

![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Database-47A248?logo=mongodb&logoColor=white)

![Flutter](https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-ML-FF6F00?logo=tensorflow&logoColor=white)

![Traefik](https://img.shields.io/badge/Traefik-Proxy-24A1C1?logo=traefikproxy&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-Message_Broker-FF6600?logo=rabbitmq&logoColor=white)

![License](https://img.shields.io/badge/License-MIT-yellow)

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)
- [System Requirements](#system-requirements)
- [Setup Guide](#full-system-setup)
- [Contribution Guide](#contribution-guide)

## Overview

The **ISL Glove AI System** is a distributed, containerized architecture designed to:

- Collect sensor data from a ESP32-based glove
- Process the data using Machine Learning models and send predictions to RabbitMQ
- Receive predictions from RabbitMQ and Convert predicted text into speech
- Return processed results back to the Flutter frontend application

The system consists of three independent services that communicate through RabbitMQ message queues, ensuring scalability, modularity, and scalability.

---

## System Architecture

The project includes:

1. **Flutter Frontend Application**
2. **Text-to-Speech (TTS) Backend – Node.js**
3. **ISL Glove AI Backend – Node.js + Python (Machine Learning)**

```
graph LR
A[ ESP32 Glove ] --> B [Node Isl Glove AI Backend ]
B --> C[ MongoDB Service ]
B --> D[ RabbitMQ Service ]
D --> E[ TTS Service ]
E --> F[ Flutter Frontend ]
```

### Communication Flow

1. The ESP32 sends sensor data to the Node.js backend.
2. The backend recieves the data and publishes the message to RabbitMQ.
3. The TTS service consumes the message from the queue.
4. The service processes the request and converts text to speech.
5. The result is sent back user by Flutter application.

This distributed architecture ensures better scalability and service separation.

---

## Project Structure

```
root/
│
├── app/                  # Flutter frontend application
│
├── backend/          # Text-to-Speech backend (Node.js)
│   └── README.md
│
├── isl-glove-AI/         # ML + Node.js backend
│   ├── ml/
│   │   ├── train.py
│   │   └── predict.py
│   │
│   ├── src/
│   └── README.md
│
└── README.md
```

---

## Technologies Used

- Node.js
- Python
- Flutter
- RabbitMQ
- Docker
- Docker Compose
- Machine Learning

---

## System Requirements

Ensure the following tools are installed:

- Node.js (v18 or higher recommended)
- Python (3.10 recommended)
- Docker
- Docker Compose
- RabbitMQ (via Docker)
- MongoDB 
- Flutter

---

# Full System Setup

---

## 1. Clone the Repository

```bash
git clone <your-repository-url>
cd <repository-folder>
```

---

## 2. Quick Setup (Recommended)

1. Install Docker and Docker Compose.
2. Start the Docker daemon.
3. Run the following command:

```bash
docker compose -f docker-compose.gateway.yml -f docker-compose.services.yml up -d --scale backend=1 --scale isl-server=2
```

This command:
- Starts all required services
- Scales the backend service to 1 instance
- Scales the ISL server to 2 instances

---

### MANUAL SETUP

## 1. Start RabbitMQ Using Docker (Manual Method)

If not using Docker Compose, start RabbitMQ manually:

```bash
docker run -d \
  --hostname rabbitmq \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  rabbitmq:3-management
```

### RabbitMQ Dashboard

```
http://localhost:15672
```

### Default Credentials

- Username: `guest`
- Password: `guest`

---

## 2. Start Backend Service

```bash
cd backend
npm install
npm start
```

---

## 3. Start ISL Glove AI Service

```bash
cd isl-glove-AI
npm install
npm start
```

## 4. strat Python Backend

```bash
venv py-3.10 -m pip install -r requirements.txt
venv\Scripts\activate
venv> cd ml
venv> python train.py
```

## Service Responsibilities

### Flutter Frontend
- Handles user interactions
- Manage TTS speech settings
- Displays prediction and TTS output

### Backend (Node.js)
- Receives Data form RabbitMQ
- Converts text to speech
- Returns processed results

### ISL Glove AI Service
- Handle incomming data form ESP32
- Provides Machine Learning predictions
- Executes Python scripts (`train.py`, `predict.py`)
- Sends prediction results back via RabbitMQ to TTS backend

### Flutter Frontend
- Handles user interactions
- Manage TTS speech settings
- Displays prediction and TTS output

---

## Documentation References

| Component     | Documentation |
|--------------|--------------|
| [Frontend](app/README.md) | Flutter Application Docs |
| [TTS Backend](backend/README.md) | Node.js TTS Service Docs |
| [ISL Glove AI](isl-glove-AI/README.md) | ML + Backend Docs |

---

# Contribution Guide

To contribute to this project:

1. Fork the repository.
2. Create and switch to a development branch:

```bash
git switch -c <username>dev
```

3. Make your changes.
4. Commit your updates.
5. Create a Pull Request for review.

---

## Notes

- Docker Compose is the recommended method for running the full system.
- Ensure RabbitMQ is running before starting backend services.
- Verify that required ports are available before launching containers.
- Keep services modular to allow independent scaling and maintenance.

---