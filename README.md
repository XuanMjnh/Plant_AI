# AI chuẩn đoán bệnh trên cây trồng

## Cấu trúc thư mục

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