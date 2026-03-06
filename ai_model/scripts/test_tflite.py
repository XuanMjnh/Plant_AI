"""
test_tflite.py
--------------
Test nhanh file .tflite trên máy tính.

Ví dụ:
python scripts/test_tflite.py --tflite outputs/model.tflite --labels outputs/labels.txt --image ../test.jpg
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
import tensorflow as tf


def load_labels(path: Path):
    return [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def preprocess(image_path: Path, size: int) -> np.ndarray:
    img = Image.open(image_path).convert("RGB")
    img = img.resize((size, size))
    arr = np.asarray(img).astype(np.float32)   # không chia 255
    arr = np.expand_dims(arr, axis=0)
    return arr


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tflite", required=True)
    parser.add_argument("--labels", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--img_size", type=int, default=224)
    parser.add_argument("--topk", type=int, default=10)
    args = parser.parse_args()

    labels = load_labels(Path(args.labels))
    x = preprocess(Path(args.image), args.img_size)

    interpreter = tf.lite.Interpreter(model_path=str(Path(args.tflite)))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print("INPUT DETAILS:", input_details)
    print("OUTPUT DETAILS:", output_details)
    print("INPUT SHAPE:", x.shape)
    print("INPUT DTYPE:", x.dtype)
    print("INPUT MIN/MAX:", x.min(), x.max())

    interpreter.set_tensor(input_details[0]["index"], x)
    interpreter.invoke()

    y = interpreter.get_tensor(output_details[0]["index"])[0]

    idx = np.argsort(-y)[: args.topk]
    print("Kết quả:")
    for i in idx:
        print(f"- {i:2d} | {labels[i]}: {float(y[i]):.6f}")


if __name__ == "__main__":
    main()