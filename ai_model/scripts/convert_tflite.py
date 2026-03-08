from __future__ import annotations

import argparse
from pathlib import Path

import tensorflow as tf


def convert_dynamic_range(converter: tf.lite.TFLiteConverter) -> None:
    converter.optimizations = [tf.lite.Optimize.DEFAULT]


def convert_float16(converter: tf.lite.TFLiteConverter) -> None:
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keras_path", required=True, help="Đường dẫn model.keras")
    parser.add_argument("--out_tflite", required=True, help="Đường dẫn xuất model.tflite")
    parser.add_argument("--quant", choices=["none", "dynamic", "float16"], default="dynamic")
    args = parser.parse_args()

    keras_path = Path(args.keras_path)
    out_tflite = Path(args.out_tflite)
    out_tflite.parent.mkdir(parents=True, exist_ok=True)

    model = tf.keras.models.load_model(keras_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if args.quant == "dynamic":
        convert_dynamic_range(converter)
    elif args.quant == "float16":
        convert_float16(converter)

    tflite_model = converter.convert()
    out_tflite.write_bytes(tflite_model)

    print("✅ Convert xong!")
    print(f"- TFLite: {out_tflite}")
    print(f"- Quant: {args.quant}")


if __name__ == "__main__":
    main()
