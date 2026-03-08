from __future__ import annotations

import tensorflow as tf


def build_simple_cnn(img_size: int, num_classes: int, dropout_rate: float = 0.30):
    inputs = tf.keras.Input(shape=(img_size, img_size, 3), name="image")
    x = tf.keras.layers.Rescaling(1.0 / 255.0)(inputs)

    for filters in [32, 64, 128, 192]:
        x = tf.keras.layers.SeparableConv2D(filters, 3, padding="same", use_bias=False)(x)
        x = tf.keras.layers.BatchNormalization()(x)
        x = tf.keras.layers.ReLU()(x)
        x = tf.keras.layers.MaxPool2D()(x)

    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(dropout_rate)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)
    model = tf.keras.Model(inputs, outputs, name="simple_cnn_leaf")
    return model, None


def build_mobilenetv2_transfer(img_size: int, num_classes: int, dropout_rate: float = 0.30):
    inputs = tf.keras.Input(shape=(img_size, img_size, 3), name="image")
    base = tf.keras.applications.MobileNetV2(
        input_shape=(img_size, img_size, 3),
        include_top=False,
        weights="imagenet",
    )
    base._name = "backbone"
    base.trainable = False

    x = tf.keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(dropout_rate)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)
    model = tf.keras.Model(inputs, outputs, name="mobilenetv2_leaf")
    return model, base


def build_efficientnetb0_transfer(img_size: int, num_classes: int, dropout_rate: float = 0.30):
    inputs = tf.keras.Input(shape=(img_size, img_size, 3), name="image")
    base = tf.keras.applications.EfficientNetB0(
        input_shape=(img_size, img_size, 3),
        include_top=False,
        weights="imagenet",
    )
    base._name = "backbone"
    base.trainable = False

    # EfficientNet đã có preprocessing ngay trong model.
    x = base(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(dropout_rate)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation="softmax", name="probs")(x)
    model = tf.keras.Model(inputs, outputs, name="efficientnetb0_leaf")
    return model, base


def build_model(architecture: str, img_size: int, num_classes: int, dropout_rate: float = 0.30):
    architecture = architecture.lower()

    if architecture == "simple_cnn":
        return build_simple_cnn(img_size, num_classes, dropout_rate)
    if architecture == "mobilenetv2":
        return build_mobilenetv2_transfer(img_size, num_classes, dropout_rate)
    if architecture == "efficientnetb0":
        return build_efficientnetb0_transfer(img_size, num_classes, dropout_rate)

    raise ValueError(f"Architecture không hỗ trợ: {architecture}")


def unfreeze_top_layers(base_model: tf.keras.Model | None, fine_tune_layers: int) -> None:
    if base_model is None:
        return

    base_model.trainable = True

    if fine_tune_layers <= 0:
        fine_tune_layers = len(base_model.layers)

    split_index = max(0, len(base_model.layers) - fine_tune_layers)

    for i, layer in enumerate(base_model.layers):
        should_train = i >= split_index
        # BatchNorm nên giữ inference mode khi fine-tune.
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
        else:
            layer.trainable = should_train
