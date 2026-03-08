from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

import tensorflow as tf


@dataclass
class DatasetInfo:
    class_names: List[str]
    num_classes: int
    train_counts: Dict[str, int]
    class_weights: Dict[int, float]


def _count_images_by_class(directory: Path) -> Dict[str, int]:
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    counts: Dict[str, int] = {}
    for class_dir in sorted([p for p in directory.iterdir() if p.is_dir()]):
        count = sum(1 for f in class_dir.rglob("*") if f.is_file() and f.suffix.lower() in exts)
        counts[class_dir.name] = count
    return counts


def _make_class_weights(class_names: List[str], counts: Dict[str, int]) -> Dict[int, float]:
    total = sum(counts.get(name, 0) for name in class_names)
    num_classes = len(class_names)
    weights: Dict[int, float] = {}

    for idx, name in enumerate(class_names):
        class_count = counts.get(name, 0)
        if class_count <= 0:
            weights[idx] = 1.0
        else:
            weights[idx] = total / (num_classes * class_count)
    return weights


def load_datasets(
    data_dir: str,
    img_size: int,
    batch_size: int,
    seed: int = 42,
    crop_to_aspect_ratio: bool = True,
) -> Tuple[tf.data.Dataset, tf.data.Dataset, DatasetInfo]:
    data_dir = Path(data_dir).resolve()
    train_dir = data_dir / "train"
    val_dir = data_dir / "val"

    if not train_dir.exists():
        raise FileNotFoundError(f"Không thấy thư mục train: {train_dir}")
    if not val_dir.exists():
        raise FileNotFoundError(f"Không thấy thư mục val: {val_dir}")

    common_kwargs = dict(
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="int",
        interpolation="bilinear",
        crop_to_aspect_ratio=crop_to_aspect_ratio,
    )

    train_ds = tf.keras.utils.image_dataset_from_directory(
        train_dir,
        shuffle=True,
        seed=seed,
        **common_kwargs,
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        val_dir,
        shuffle=False,
        **common_kwargs,
    )

    class_names = list(train_ds.class_names)
    train_counts = _count_images_by_class(train_dir)
    class_weights = _make_class_weights(class_names, train_counts)

    info = DatasetInfo(
        class_names=class_names,
        num_classes=len(class_names),
        train_counts=train_counts,
        class_weights=class_weights,
    )

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.cache().shuffle(8 * batch_size, seed=seed).prefetch(autotune)
    val_ds = val_ds.cache().prefetch(autotune)
    return train_ds, val_ds, info


def build_leaf_augmentation() -> tf.keras.Sequential:

    return tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal_and_vertical"),
            tf.keras.layers.RandomRotation(0.10),
            tf.keras.layers.RandomTranslation(0.08, 0.08),
            tf.keras.layers.RandomZoom(height_factor=(-0.12, 0.10), width_factor=(-0.12, 0.10)),
            tf.keras.layers.RandomContrast(0.15),
            tf.keras.layers.RandomBrightness(0.12, value_range=(0, 255)),
        ],
        name="leaf_augmentation",
    )
