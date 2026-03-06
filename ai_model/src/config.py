"""
config.py
---------
Các cấu hình cơ bản cho bài toán phân loại bệnh cây trồng.
Mục tiêu: code dễ hiểu cho người mới.

Bạn có thể chỉnh:
- img_size: kích thước ảnh đầu vào (vd 224)
- num_classes: số lớp bệnh
- learning_rate: tốc độ học
"""

from dataclasses import dataclass


@dataclass
class TrainConfig:
    img_size: int = 224
    batch_size: int = 32
    epochs: int = 15
    learning_rate: float = 1e-3
    # Nếu bật transfer learning, model sẽ là MobileNetV2 (nhẹ, hợp mobile)
    use_transfer_learning: bool = False
    # Chuẩn hoá ảnh: (x - mean) / std. Với TensorFlow thường dùng 0..1.
    mean: float = 0.0
    std: float = 255.0  # chia 255 => đưa về 0..1
