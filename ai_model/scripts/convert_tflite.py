"""
convert_tflite.py
-----------------
Convert Keras model -> TensorFlow Lite.

Ví dụ:

python scripts/convert_tflite.py --keras_path outputs/model.keras --out_tflite outputs/model.tflite


Bạn có thể bật quantization để model nhẹ hơn:
- --quant dynamic: quant weight động (dễ, thường ổn)
- int8 full: cần representative dataset (có code mẫu bên dưới)
"""

from __future__ import annotations

import argparse
from pathlib import Path

import tensorflow as tf


def convert_dynamic_range(converter: tf.lite.TFLiteConverter) -> None:
    # Quantization dạng dynamic-range (nhẹ, dễ, không cần representative dataset)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keras_path", required=True, help="Đường dẫn model.keras")
    parser.add_argument("--out_tflite", required=True, help="Đường dẫn xuất model.tflite")
    parser.add_argument("--quant", choices=["none", "dynamic"], default="dynamic")
    args = parser.parse_args()

    keras_path = Path(args.keras_path)
    out_tflite = Path(args.out_tflite)
    out_tflite.parent.mkdir(parents=True, exist_ok=True)

    model = tf.keras.models.load_model(keras_path)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if args.quant == "dynamic":
        convert_dynamic_range(converter)

    tflite_model = converter.convert()
    out_tflite.write_bytes(tflite_model)

    print("✅ Convert xong!")
    print(f"- TFLite: {out_tflite}")


if __name__ == "__main__":
    main()
