```bash
cd ai_model

python -m venv .venv

.venv\Scripts\activate

pip install -r requirements.txt
```

---

```bash
python .\scripts\train.py --data_dir .\dataset --arch efficientnetb0 --img_size 224 --batch 32 --stage1_epochs 8 --stage2_epochs 12 --lr1 1e-3 --lr2 1e-5 --fine_tune_layers 40 --out_dir .\outputs
```

- `outputs/model.keras` (mô hình Keras)
- `outputs/labels.txt` (danh sách nhãn theo đúng thứ tự output)

---

Convert sang TFLite

```bash
python .\scripts\convert_tflite.py --keras_path .\outputs\model.keras --out_tflite .\outputs\model.tflite --quant float16
```

- `outputs/model.tflite` -> `flutter_app/assets/models/model.tflite`
- `outputs/labels.txt` -> `flutter_app/assets/models/labels.txt`

---

## 5) Test nhanh model TFLite (trên PC)

```bash
python .\scripts\test_tflite.py --tflite .\outputs\model.tflite --labels .\outputs\labels.txt --image .\test.jpg
```

---

## 6) Gợi ý nâng chất lượng (rất quan trọng)
- Dùng transfer learning (MobileNetV2/EfficientNet) thay vì CNN “tự viết”
- Augmentation (xoay, lật, brightness) + early stopping
- Chọn input 224x224 và quantization (int8) để chạy mượt trên mobile

Trong `src/model.py` mình để sẵn 2 lựa chọn: CNN đơn giản và transfer learning (bạn bật lên khi đã cài đủ TF + có internet để tải weights, hoặc bạn tự tải weights trước).

