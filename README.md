# Plant Disease AI + Flutter (CNN + TensorFlow Lite) – Full Project (Starter)

Dự án mẫu **đầy đủ cấu trúc + code** để bạn:
- Huấn luyện mô hình CNN (TensorFlow/Keras) trên ảnh lá/quả cây trồng (dataset bạn tự chuẩn bị)
- Convert sang **TensorFlow Lite (.tflite)**
- Tích hợp vào **Flutter** để chụp ảnh / chọn ảnh, chạy suy luận offline, hiển thị **kết quả + tư vấn chăm sóc**

> Lưu ý quan trọng: Trong môi trường tạo file zip này mình **không cài TensorFlow**, nên không thể đóng gói sẵn model thật.  
> Nhưng dự án đã có **toàn bộ code train + convert + app Flutter**. Bạn chỉ cần chạy train/convert trên máy bạn để tạo `model.tflite` rồi copy vào Flutter.

---

## 1) Cấu trúc thư mục

```
plant_ai_flutter_full_project/
  ai_model/                 # Phần AI (train -> export -> tflite)
    src/
    scripts/
    requirements.txt
    README.md
  flutter_app/              # Phần Flutter (mobile)
    lib/
    assets/
      models/               # đặt model.tflite + labels.txt ở đây
      data/                 # mapping tư vấn
    pubspec.yaml
    README.md
```

---

## 2) Luồng hoạt động (end-to-end)

1. Bạn chuẩn bị dataset theo cấu trúc thư mục (ảnh theo từng lớp bệnh):
   ```
   dataset/
     train/
       Healthy/
       DiseaseA/
       DiseaseB/
     val/
       Healthy/
       DiseaseA/
       DiseaseB/
   ```
2. Chạy train tạo `SavedModel`/`.keras`.
3. Chạy convert tạo `model.tflite`.
4. Copy `model.tflite` + `labels.txt` vào: `flutter_app/assets/models/`
5. Chạy Flutter app -> chụp ảnh -> app resize/normalize -> tflite -> top-k -> hiển thị tư vấn.

---

## 3) Bắt đầu nhanh

### AI (Python)
Xem chi tiết ở `ai_model/README.md`

### Flutter
Xem chi tiết ở `flutter_app/README.md`

---

## 4) Bạn muốn mở rộng gì tiếp?
- Thêm nhiều lớp bệnh + tăng độ chính xác (transfer learning MobileNet/EfficientNet)
- Thêm “tư vấn” theo cây trồng, thời tiết, vùng miền (rule-based / LLM)
- Đẩy mô hình lên server (nếu muốn online) hoặc đồng bộ model qua OTA

Chúc bạn làm demo ngon! 🙂
