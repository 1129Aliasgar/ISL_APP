import json
import os
import sys

import numpy as np
import tensorflow as tf


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TFLITE_MODEL_PATH = os.path.join(BASE_DIR, "model.tflite")
KERAS_MODEL_PATH = os.path.join(BASE_DIR, "gesture_model.h5")
NORMALIZER_PATH = os.path.join(BASE_DIR, "normalizer.npz")
LABELS_PATH = os.path.join(BASE_DIR, "labels.json")
TIMESTEPS = 50
FEATURES = 11


def load_label_map():
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)["labels"]


def normalize_input(data):
    stats = np.load(NORMALIZER_PATH)
    mean = stats["mean"]
    std = stats["std"]
    return (data - mean) / std


def resize_window(window: np.ndarray, target_len: int = TIMESTEPS) -> np.ndarray:
    if window.ndim != 2 or window.shape[1] != FEATURES:
        raise ValueError(
            f"Expected input shape (n, {FEATURES}), got {window.shape}"
        )

    length = window.shape[0]
    if length == target_len:
        return window.astype(np.float32)
    if length <= 0:
        raise ValueError("Input window must contain at least one timestep")
    if length < target_len:
        pad_count = target_len - length
        pad_rows = np.repeat(window[-1:, :], pad_count, axis=0)
        return np.concatenate([window, pad_rows], axis=0).astype(np.float32)

    src_idx = np.linspace(0, length - 1, num=length, dtype=np.float32)
    dst_idx = np.linspace(0, length - 1, num=target_len, dtype=np.float32)
    resized = np.stack(
        [np.interp(dst_idx, src_idx, window[:, feature_idx]) for feature_idx in range(FEATURES)],
        axis=1,
    )
    return resized.astype(np.float32)


def predict_with_tflite(input_data):
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    interpreter.set_tensor(input_details[0]["index"], input_data.astype(np.float32))
    interpreter.invoke()
    return interpreter.get_tensor(output_details[0]["index"])[0]


def main():
    labels = load_label_map()

    raw_data = json.loads(sys.argv[1])
    raw_window = np.array(raw_data, dtype=np.float32)
    resized_window = resize_window(raw_window, TIMESTEPS)
    input_data = np.expand_dims(resized_window, axis=0)
    input_data = normalize_input(input_data)

    if os.path.exists(TFLITE_MODEL_PATH):
        probs = predict_with_tflite(input_data)
    elif os.path.exists(KERAS_MODEL_PATH):
        model = tf.keras.models.load_model(KERAS_MODEL_PATH)
        probs = model.predict(input_data, verbose=0)[0]
    else:
        raise FileNotFoundError(
            f"No model found. Expected {TFLITE_MODEL_PATH} or {KERAS_MODEL_PATH}"
        )

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
