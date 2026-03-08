from __future__ import annotations

import argparse
from pathlib import Path
from typing import List

import numpy as np
from PIL import Image, ImageOps
import tensorflow as tf


def load_labels(path: Path) -> List[str]:
    return [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def preprocess(image_path: Path, size: int) -> np.ndarray:
    img = Image.open(image_path).convert("RGB")
    # Gần giống crop_to_aspect_ratio=True khi train.
    img = ImageOps.fit(img, (size, size), method=Image.Resampling.BILINEAR)
    arr = np.asarray(img).astype(np.float32)
    arr = np.expand_dims(arr, axis=0)
    return arr


def adapt_input_dtype(x: np.ndarray, input_detail: dict) -> np.ndarray:
    dtype = input_detail["dtype"]
    if dtype == np.float32:
        return x.astype(np.float32)

    scale, zero_point = input_detail.get("quantization", (0.0, 0))
    if scale and dtype in (np.uint8, np.int8):
        q = np.round(x / scale + zero_point)
        info = np.iinfo(dtype)
        q = np.clip(q, info.min, info.max)
        return q.astype(dtype)

    return x.astype(dtype)


def dequantize_output(y: np.ndarray, output_detail: dict) -> np.ndarray:
    scale, zero_point = output_detail.get("quantization", (0.0, 0))
    if scale:
        return (y.astype(np.float32) - zero_point) * scale
    return y.astype(np.float32)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tflite", required=True)
    parser.add_argument("--labels", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--img_size", type=int, default=224)
    parser.add_argument("--topk", type=int, default=5)
    args = parser.parse_args()

    labels = load_labels(Path(args.labels))
    x = preprocess(Path(args.image), args.img_size)

    interpreter = tf.lite.Interpreter(model_path=str(Path(args.tflite)))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    x_input = adapt_input_dtype(x, input_details[0])

    print("INPUT DETAILS:", input_details)
    print("OUTPUT DETAILS:", output_details)
    print("INPUT SHAPE:", x_input.shape)
    print("INPUT DTYPE:", x_input.dtype)

    interpreter.set_tensor(input_details[0]["index"], x_input)
    interpreter.invoke()

    y = interpreter.get_tensor(output_details[0]["index"])[0]
    y = dequantize_output(y, output_details[0])

    idx = np.argsort(-y)[: args.topk]
    print("Kết quả:")
    for i in idx:
        label = labels[i] if i < len(labels) else f"class_{i}"
        print(f"- {i:2d} | {label}: {float(y[i]):.6f}")


if __name__ == "__main__":
    main()
