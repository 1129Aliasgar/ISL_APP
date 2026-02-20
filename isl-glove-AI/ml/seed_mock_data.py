import numpy as np
from pymongo import MongoClient
from datetime import datetime
import random

# Mongo connection
client = MongoClient("mongodb://127.0.0.1:27017/")
db = client["isl_glove"]
collection = db["sensorwindows"]

# Clear old bad data
collection.delete_many({})
print("Old data cleared.")

NUM_SAMPLES = 30   # number of gesture windows
TIMESTEPS = 50
FEATURES = 11
LABELS = ["A", "B", "C"]

for i in range(NUM_SAMPLES):
    # Generate 50x11 random sensor window
    window = np.random.rand(TIMESTEPS, FEATURES).tolist()

    document = {
        "deviceId": f"glove_{random.randint(1,2)}",
        "windowStart": datetime.utcnow(),
        "data": window,
        "gestureLabel": random.choice(LABELS)  # fake character classes
    }

    collection.insert_one(document)

print(f"{NUM_SAMPLES} mock windows inserted successfully.")
