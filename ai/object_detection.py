from ultralytics import YOLO

# Load a YOLOv11n PyTorch (lightweight) model
model = YOLO("yolov11n.pt")

# Export the model to NCNN format for better inference on our devices
model.export(format="ncnn")  # creates 'yolov11n_ncnn_model'

# Load the exported NCNN model
ncnn_model = YOLO("yolov11n_ncnn_model", task="detect")

# Run inference on an example to get the results
results = ncnn_model("https://ultralytics.com/images/bus.jpg")

# Save the image with drawn bboxes
if results:
    result = results[0]
    annotated_frame = result.plot()
    # Save the annotated image
    import cv2
    cv2.imwrite("detection_result.jpg", annotated_frame)
    print("✓ Image saved as 'detection_result.jpg'")
