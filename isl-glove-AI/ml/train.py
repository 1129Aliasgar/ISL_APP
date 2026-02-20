import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from pymongo import MongoClient

from autoencoder import build_autoencoder
from classifier import ALPHABET_LABELS
from classifier import build_classifier
from export_tflite import export_tflite


DB_URI = "mongodb://127.0.0.1:27017/"
DB_NAME = "isl_glove"
COLLECTION_NAME = "sensorwindows"
TIMESTEPS = 50
FEATURES = 11

BASE_DIR = Path(__file__).resolve().parent
NORMALIZER_PATH = BASE_DIR / "normalizer.npz"
LABELS_PATH = BASE_DIR / "labels.json"
REP_DATA_PATH = BASE_DIR / "representative_data.npy"
AUTOENCODER_MODEL_PATH = BASE_DIR / "autoencoder_model.h5"
CLASSIFIER_MODEL_PATH = BASE_DIR / "gesture_model.h5"
TFLITE_PATH = BASE_DIR / "model.tflite"


def load_labeled_windows():
    client = MongoClient(DB_URI)
    collection = client[DB_NAME][COLLECTION_NAME]
    documents = list(collection.find({"gestureLabel": {"$ne": None}}))

    if not documents:
        raise ValueError("No labeled data found in MongoDB")

    X = np.array([doc["data"] for doc in documents], dtype=np.float32)
    y_raw = np.array([str(doc["gestureLabel"]).strip().upper() for doc in documents])

    if X.ndim != 3:
        raise ValueError(f"Expected input shape (samples, timesteps, features), got {X.shape}")
    if X.shape[1] != TIMESTEPS or X.shape[2] != FEATURES:
        raise ValueError(
            f"Expected each sample to have shape ({TIMESTEPS}, {FEATURES}), got {X.shape[1:]}"
        )

    return X, y_raw


def fit_and_save_normalizer(X):
    _, _, features = X.shape
    X_flat = X.reshape(-1, features)

    mean = X_flat.mean(axis=0)
    std = X_flat.std(axis=0)
    std = np.where(std < 1e-8, 1.0, std)

    np.savez(NORMALIZER_PATH, mean=mean, std=std)
    print(f"Saved normalizer stats to {NORMALIZER_PATH.name}")

    X_scaled = (X - mean) / std
    return X_scaled


def encode_labels(y_raw):
    unsupported = sorted({label for label in y_raw if label not in ALPHABET_LABELS})
    if unsupported:
        raise ValueError(f"Unsupported labels found: {unsupported}. Allowed labels: A-Z")

    label_to_idx = {label: idx for idx, label in enumerate(ALPHABET_LABELS)}
    y_idx = np.array([label_to_idx[label] for label in y_raw], dtype=np.int32)
    y_one_hot = tf.keras.utils.to_categorical(y_idx, num_classes=len(ALPHABET_LABELS))

    with open(LABELS_PATH, "w", encoding="utf-8") as f:
        json.dump({"labels": ALPHABET_LABELS}, f, indent=2)
    print(f"Saved label map to {LABELS_PATH.name}")

    return y_one_hot, len(ALPHABET_LABELS)


def train():
    X, y_raw = load_labeled_windows()
    print("Loaded dataset:", X.shape)

    X_scaled = fit_and_save_normalizer(X)
    y_one_hot, num_classes = encode_labels(y_raw)

    samples, timesteps, features = X_scaled.shape

    print("Step 3: Training autoencoder")
    autoencoder, _ = build_autoencoder(timesteps, features)
    autoencoder.fit(
        X_scaled,
        X_scaled,
        epochs=20,
        batch_size=16,
        validation_split=0.2,
        verbose=1,
    )
    autoencoder.save(AUTOENCODER_MODEL_PATH)
    print(f"Saved autoencoder to {AUTOENCODER_MODEL_PATH.name}")

    # Use autoencoder outputs as denoised inputs for classifier training.
    X_denoised = autoencoder.predict(X_scaled, verbose=0)

    print("Step 4: Training CNN-GRU classifier")
    classifier = build_classifier((timesteps, features), num_classes)
    classifier.fit(
        X_denoised,
        y_one_hot,
        epochs=30,
        batch_size=16,
        validation_split=0.2,
        verbose=1,
    )
    classifier.save(CLASSIFIER_MODEL_PATH)
    print(f"Saved classifier to {CLASSIFIER_MODEL_PATH.name}")

    rep_count = min(100, samples)
    np.save(REP_DATA_PATH, X_denoised[:rep_count].astype(np.float32))
    print(f"Saved representative dataset to {REP_DATA_PATH.name}")

    print("Step 5 & 6: Quantize and convert to TFLite")
    export_tflite(CLASSIFIER_MODEL_PATH, TFLITE_PATH, REP_DATA_PATH)
    print(f"TFLite export complete: {TFLITE_PATH.name}")


if __name__ == "__main__":
    train()
