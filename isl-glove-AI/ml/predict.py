import json
import os
import sys

import numpy as np
import tensorflow as tf


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "gesture_model.h5")
NORMALIZER_PATH = os.path.join(BASE_DIR, "normalizer.npz")
LABELS_PATH = os.path.join(BASE_DIR, "labels.json")


def load_label_map():
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)["labels"]


def normalize_input(data):
    stats = np.load(NORMALIZER_PATH)
    mean = stats["mean"]
    std = stats["std"]
    return (data - mean) / std


def main():
    model = tf.keras.models.load_model(MODEL_PATH)
    labels = load_label_map()

    raw_data = json.loads(sys.argv[1])
    input_data = np.array([raw_data], dtype=np.float32)
    input_data = normalize_input(input_data)

    probs = model.predict(input_data, verbose=0)[0]
    class_idx = int(np.argmax(probs))
    predicted_label = labels[class_idx]
    confidence = float(probs[class_idx])

    payload = {
        "character": predicted_label,
        "confidence": confidence,
        "probabilities": {labels[i]: float(probs[i]) for i in range(len(labels))},
    }
    print(json.dumps(payload))


if __name__ == "__main__":
    main()
