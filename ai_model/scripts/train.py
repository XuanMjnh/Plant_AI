"""
Train tối ưu cho nhận diện bệnh lá cây.

Điểm khác với bản cũ:
- Mặc định dùng EfficientNetB0 transfer learning.
- Train 2 giai đoạn: freeze -> fine-tune.
- Có class weights nếu dữ liệu lệch lớp.
- Có metadata để Flutter/TFLite giữ đúng preprocess.
"""

from __future__ import annotations
import sys
import argparse
import json
from pathlib import Path

import tensorflow as tf


ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from src.config import TrainConfig
from src.data import build_leaf_augmentation, load_datasets
from src.model import build_model, unfreeze_top_layers


def save_labels(labels, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(labels), encoding="utf-8")


def save_metadata(cfg: TrainConfig, class_names, out_dir: Path) -> None:
    metadata = {
        "img_size": cfg.img_size,
        "architecture": cfg.architecture,
        "top_k": cfg.top_k,
        "class_names": list(class_names),
        "preprocess": {
            "input_range": "0_255_float",
            "embedded_in_model": True,
            "crop_to_aspect_ratio": cfg.crop_to_aspect_ratio,
            "inference_hint": "resize_center_crop_then_rgb",
        },
    }
    (out_dir / "model_meta.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def compile_model(model: tf.keras.Model, learning_rate: float) -> None:
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=[
            "accuracy",
            tf.keras.metrics.SparseTopKCategoricalAccuracy(k=2, name="top2_acc"),
        ],
    )


def build_callbacks(out_dir: Path, patience: int, reduce_lr_patience: int):
    return [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=patience,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.2,
            patience=reduce_lr_patience,
            min_lr=1e-7,
            verbose=1,
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(out_dir / "model.keras"),
            monitor="val_accuracy",
            save_best_only=True,
        ),
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data_dir", required=True, help="Thư mục chứa train/ và val/")
    parser.add_argument("--img_size", type=int, default=224)
    parser.add_argument("--batch", type=int, default=32)
    parser.add_argument("--arch", choices=["simple_cnn", "mobilenetv2", "efficientnetb0"], default="efficientnetb0")
    parser.add_argument("--stage1_epochs", type=int, default=8)
    parser.add_argument("--stage2_epochs", type=int, default=12)
    parser.add_argument("--lr1", type=float, default=1e-3)
    parser.add_argument("--lr2", type=float, default=1e-5)
    parser.add_argument("--fine_tune_layers", type=int, default=40)
    parser.add_argument("--out_dir", default="outputs")
    parser.add_argument("--no_class_weights", action="store_true")
    args = parser.parse_args()

    cfg = TrainConfig(
        img_size=args.img_size,
        batch_size=args.batch,
        architecture=args.arch,
        stage1_epochs=args.stage1_epochs,
        stage2_epochs=args.stage2_epochs,
        learning_rate_stage1=args.lr1,
        learning_rate_stage2=args.lr2,
        fine_tune_layers=args.fine_tune_layers,
        use_class_weights=not args.no_class_weights,
    )

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    train_ds, val_ds, info = load_datasets(
        args.data_dir,
        cfg.img_size,
        cfg.batch_size,
        seed=cfg.seed,
        crop_to_aspect_ratio=cfg.crop_to_aspect_ratio,
    )

    aug = build_leaf_augmentation()

    def augment(x, y):
        x = tf.cast(x, tf.float32)
        return aug(x, training=True), y

    train_ds_aug = train_ds.map(augment, num_parallel_calls=tf.data.AUTOTUNE).prefetch(tf.data.AUTOTUNE)

    model, base_model = build_model(
        architecture=cfg.architecture,
        img_size=cfg.img_size,
        num_classes=info.num_classes,
        dropout_rate=cfg.dropout_rate,
    )

    model.summary()
    print("Class names:", info.class_names)
    print("Train counts:", info.train_counts)
    print("Class weights:", info.class_weights)

    class_weight = info.class_weights if cfg.use_class_weights else None
    callbacks = build_callbacks(out_dir, cfg.early_stopping_patience, cfg.reduce_lr_patience)

    # Stage 1: chỉ train head
    compile_model(model, cfg.learning_rate_stage1)
    model.fit(
        train_ds_aug,
        validation_data=val_ds,
        epochs=cfg.stage1_epochs,
        callbacks=callbacks,
        class_weight=class_weight,
    )

    # Stage 2: fine-tune phần cuối backbone
    if base_model is not None and cfg.stage2_epochs > 0:
        print(f"\nFine-tuning {cfg.fine_tune_layers} layer cuối của backbone...\n")
        unfreeze_top_layers(base_model, cfg.fine_tune_layers)
        compile_model(model, cfg.learning_rate_stage2)
        model.fit(
            train_ds_aug,
            validation_data=val_ds,
            epochs=cfg.stage2_epochs,
            callbacks=callbacks,
            class_weight=class_weight,
        )

    model.save(out_dir / "model.keras")
    save_labels(info.class_names, out_dir / "labels.txt")
    save_metadata(cfg, info.class_names, out_dir)

    print("\nDone!")
    print(f"- Model: {out_dir / 'model.keras'}")
    print(f"- Labels: {out_dir / 'labels.txt'}")
    print(f"- Metadata: {out_dir / 'model_meta.json'}")


if __name__ == "__main__":
    main()
