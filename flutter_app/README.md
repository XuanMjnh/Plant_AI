# Flutter App – Plant Disease AI (TFLite)

App Flutter cho phép:
- Chụp ảnh (camera) hoặc chọn ảnh từ thư viện
- Chạy nhận diện bằng **TensorFlow Lite**
- Hiển thị Top-K kết quả + gợi ý tư vấn (file JSON)

---

## 1) Chuẩn bị model

Sau khi bạn train + convert ở `ai_model/`, copy 2 file:

- `ai_model/outputs/model.tflite`  -> `flutter_app/assets/models/model.tflite`
- `ai_model/outputs/labels.txt`    -> `flutter_app/assets/models/labels.txt`

> Trong zip hiện tại, thư mục `assets/models/` có sẵn `labels.txt` mẫu.  
> `model.tflite` là **placeholder** (chưa có), nên app sẽ tự chuyển sang **chế độ mô phỏng** để bạn test UI.
> Khi bạn copy model thật vào, app sẽ tự chạy thật.

---

## 2) Chạy app

Ở máy bạn (đã cài Flutter SDK):

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 3) Quyền camera / gallery

- Android: `image_picker` thường tự thêm quyền cơ bản, nhưng tuỳ phiên bản bạn có thể cần chỉnh `AndroidManifest.xml`.
- iOS: cần thêm mô tả quyền trong `Info.plist` (camera/photo library).

Xem hướng dẫn trong docs `image_picker` nếu gặp lỗi permission.

---

## 4) Custom tư vấn

File: `assets/data/advice_vi.json`

Bạn có thể thêm tư vấn theo label.  
**Tên label phải khớp đúng** với dòng trong `labels.txt`.

---

## 5) Debug nhanh

Nếu app báo:
- “Không load được model.tflite” -> bạn chưa copy model hoặc sai đường dẫn assets.
- “Shape mismatch” -> model input size khác. Hãy sửa `ModelConfig` trong `lib/services/model_config.dart`
  hoặc đọc shape trực tiếp từ interpreter (đã có code).

