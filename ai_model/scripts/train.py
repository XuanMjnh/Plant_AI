"""
train.py
--------
Chạy train mô hình và xuất:
- outputs/model.keras
- outputs/labels.txt

Ví dụ:
python -m scripts.train --data_dir dataset --img_size 224 --batch 32 --epochs 15
"""

from __future__ import annotations

import argparse
from pathlib import Path

import tensorflow as tf

from src.config import TrainConfig
from src.data import load_datasets, build_augmentation
from src.model import build_simple_cnn, build_mobilenetv2_transfer


def save_labels(labels, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(labels), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", required=True, help="Thư mục chứa train/ và val/")
    parser.add_argument("--img_size", type=int, default=224)
    parser.add_argument("--batch", type=int, default=32)
    parser.add_argument("--epochs", type=int, default=15)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--transfer", action="store_true", help="Bật transfer learning MobileNetV2")
    parser.add_argument("--out_dir", default="outputs", help="Thư mục lưu model/labels")
    args = parser.parse_args()

    cfg = TrainConfig(
        img_size=args.img_size,
        batch_size=args.batch,
        epochs=args.epochs,
        learning_rate=args.lr,
        use_transfer_learning=args.transfer,
    )

    train_ds, val_ds, info = load_datasets(args.data_dir, cfg.img_size, cfg.batch_size)

    # Augmentation áp dụng cho train (không áp dụng cho val)
    aug = build_augmentation()

    def augment(x, y):
        return aug(x, training=True), y

    train_ds_aug = train_ds.map(augment, num_parallel_calls=tf.data.AUTOTUNE)

    # Build model
    if cfg.use_transfer_learning:
        model = build_mobilenetv2_transfer(cfg.img_size, info.num_classes)
    else:
        model = build_simple_cnn(cfg.img_size, info.num_classes)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=cfg.learning_rate),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"],
    )

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=3, restore_best_weights=True
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(Path(args.out_dir) / "model.keras"),
            monitor="val_accuracy",
            save_best_only=True,
        ),
    ]

    model.summary()

    model.fit(
        train_ds_aug,
        validation_data=val_ds,
        epochs=cfg.epochs,
        callbacks=callbacks,
    )

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # ModelCheckpoint đã lưu model.keras; nếu bạn muốn lưu chắc chắn:
    model.save(out_dir / "model.keras")

    # labels.txt theo đúng thứ tự class_names
    save_labels(info.class_names, out_dir / "labels.txt")

    print("Done!")
    print(f"- Model: {out_dir/'model.keras'}")
    print(f"- Labels: {out_dir/'labels.txt'}")


if __name__ == "__main__":
    main()
