from ultralytics import YOLO

# Load a YOLOv11n PyTorch model
model = YOLO("yolov11n.pt")

# Export the model to NCNN format
model.export(format="ncnn") # creates 'yolov11n_ncnn_model'

# Load the exported NCNN model
ncnn_model = YOLO("yolov11n_ncnn_model", task='detect')

# Run inference
results = ncnn_model("https://ultralytics.com/images/bus.jpg")