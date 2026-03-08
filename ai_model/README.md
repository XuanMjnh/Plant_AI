## Cài đặt môi trường

```
python -m venv .venv

.venv\Scripts\activate

pip install -r requirements.txt
```

## Train Model
```
python .\scripts\train.py --data_dir .\dataset --arch efficientnetb0 --img_size 224 --batch 32 --stage1_epochs 8 --stage2_epochs 12 --lr1 1e-3 --lr2 1e-5 --fine_tune_layers 40 --out_dir .\outputs
```

## Convert sang TFLite
```
python .\scripts\convert_tflite.py --keras_path .\outputs\model.keras --out_tflite .\outputs\model.tflite --quant float16
```

## Test Model

```
python .\scripts\test_tflite.py --tflite .\outputs\model.tflite --labels .\outputs\labels.txt --image .\test.jpg
```

