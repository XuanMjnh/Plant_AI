from dataclasses import dataclass


@dataclass
class TrainConfig:
    # Dữ liệu
    img_size: int = 224
    batch_size: int = 32
    seed: int = 42
    crop_to_aspect_ratio: bool = True

    # Kiến trúc
    architecture: str = "efficientnetb0"  # simple_cnn | mobilenetv2 | efficientnetb0
    dropout_rate: float = 0.30

    # Train 2 giai đoạn
    stage1_epochs: int = 8
    stage2_epochs: int = 12
    learning_rate_stage1: float = 1e-3
    learning_rate_stage2: float = 1e-5
    fine_tune_layers: int = 40  # mở train N layer cuối của backbone

    # Ổn định train
    use_class_weights: bool = True
    early_stopping_patience: int = 5
    reduce_lr_patience: int = 2

    # Inference / export
    top_k: int = 5
