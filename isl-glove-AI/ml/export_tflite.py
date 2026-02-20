from pathlib import Path

import numpy as np
import tensorflow as tf


def _representative_dataset_generator(data: np.ndarray):
    for sample in data:
        yield [np.expand_dims(sample.astype(np.float32), axis=0)]


def export_tflite(
    model_path: str | Path = "gesture_model.h5",
    output_path: str | Path = "model.tflite",
    representative_data_path: str | Path = "representative_data.npy",
):
    model_path = Path(model_path)
    output_path = Path(output_path)
    representative_data_path = Path(representative_data_path)

    if not model_path.exists():
        raise FileNotFoundError(f"Model not found: {model_path}")

    model = tf.keras.models.load_model(model_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    if representative_data_path.exists():
        rep_data = np.load(representative_data_path).astype(np.float32)
        converter.representative_dataset = lambda: _representative_dataset_generator(rep_data)
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.float32
        converter.inference_output_type = tf.float32

    tflite_model = converter.convert()
    output_path.write_bytes(tflite_model)
    return output_path


if __name__ == "__main__":
    out = export_tflite()
    print(f"TFLite model created: {out}")
