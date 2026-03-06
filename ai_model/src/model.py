"""
model.py
--------
2 lựa chọn:
1) CNN đơn giản (dễ hiểu, baseline)
2) Transfer learning (MobileNetV2) -> chất lượng thường tốt hơn nhiều

Mặc định: CNN đơn giản để bạn hiểu nhanh.
Khi đã quen, bật use_transfer_learning=True trong TrainConfig hoặc tham số train.py.
"""

from __future__ import annotations

import tensorflow as tf


def build_simple_cnn(img_size: int, num_classes: int) -> tf.keras.Model:
    inputs = tf.keras.Input(shape=(img_size, img_size, 3), name="image")

    x = tf.keras.layers.Rescaling(1.0 / 255.0)(inputs)  # 0..255 -> 0..1

    # Conv block 1
    x = tf.keras.layers.Conv2D(32, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.MaxPool2D()(x)

    # Conv block 2
    x = tf.keras.layers.Conv2D(64, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.MaxPool2D()(x)

    # Conv block 3
    x = tf.keras.layers.Conv2D(128, 3, padding="same", activation="relu")(x)
    x = tf.keras.layers.MaxPool2D()(x)

    x = tf.keras.layers.Flatten()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(256, activation="relu")(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)

    return tf.keras.Model(inputs=inputs, outputs=outputs, name="simple_cnn")


def build_mobilenetv2_transfer(img_size: int, num_classes: int) -> tf.keras.Model:
    """
    Transfer learning: dùng backbone MobileNetV2.
    - Tốt cho mobile (nhẹ)
    - Cần internet lần đầu để tải weights (hoặc bạn tự tải trước)
    """
    inputs = tf.keras.Input(shape=(img_size, img_size, 3), name="image")

    # MobileNetV2 khuyến nghị preprocess_input riêng (đưa về -1..1)
    base = tf.keras.applications.MobileNetV2(
        input_shape=(img_size, img_size, 3),
        include_top=False,
        weights="imagenet",
    )
    base.trainable = False  # freeze để train nhanh

    x = tf.keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)

    return tf.keras.Model(inputs=inputs, outputs=outputs, name="mobilenetv2_transfer")
