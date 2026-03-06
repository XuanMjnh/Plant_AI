"""
data.py
-------
Tạo dataset train/val từ thư mục ảnh theo chuẩn:

dataset/
  train/
    Healthy/
    DiseaseA/
  val/
    Healthy/
    DiseaseA/

Kỹ thuật:
- image_dataset_from_directory: tự tạo labels theo tên folder
- augmentation: tăng dữ liệu (xoay/lật/zoom) để model tổng quát hơn
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Tuple, List

import tensorflow as tf


@dataclass
class DatasetInfo:
    class_names: List[str]
    num_classes: int


def load_datasets(
    data_dir: str,
    img_size: int,
    batch_size: int,
) -> Tuple[tf.data.Dataset, tf.data.Dataset, DatasetInfo]:
    """
    Đọc dataset từ data_dir.
    Kỳ vọng có 2 thư mục con: train/ và val/
    """
    data_dir = str(Path(data_dir).resolve())
    train_dir = str(Path(data_dir) / "train")
    val_dir = str(Path(data_dir) / "val")

    if not Path(train_dir).exists():
        raise FileNotFoundError(f"Không thấy thư mục train: {train_dir}")
    if not Path(val_dir).exists():
        raise FileNotFoundError(f"Không thấy thư mục val: {val_dir}")

    # label_mode="int" => labels dạng số nguyên 0..(num_classes-1)
    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="int",
        shuffle=True,
        seed=42,
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        val_dir,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="int",
        shuffle=False,
    )

    class_names = train_ds.class_names
    info = DatasetInfo(class_names=class_names, num_classes=len(class_names))

    # Tối ưu pipeline: cache + prefetch
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

    return train_ds, val_ds, info


def build_augmentation() -> tf.keras.Sequential:
    """
    Augmentation nhẹ để tránh phá nát ảnh.
    Bạn có thể tăng/giảm tuỳ dataset.
    """
    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.05),
            tf.keras.layers.RandomZoom(0.1),
            tf.keras.layers.RandomContrast(0.1),
        ],
        name="augmentation",
    )
