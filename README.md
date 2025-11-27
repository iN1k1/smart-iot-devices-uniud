# Smart IoT Devices - University of Udine

A comprehensive IoT platform featuring AI-powered object detection, voice assistants, and sensor integration with support for both cloud and local LLM inference.

## 🌟 Features

- **AI-Powered Object Detection**: YOLOv11n for real-time object detection
- **Multi-Model Support**: 
  - Cloud-based: HuggingFace Hub models (e.g., Meta-Llama-3-8B-Instruct)
  - Local: OLLAMA integration for private, offline inference (e.g., qwen3:0.6b)
- **Voice Assistant**: Alexa-compatible voice control
- **Telegram Bot**: Remote monitoring and control interface
- **Sensor Integration**: DHT sensors for environmental monitoring
- **MQTT Messaging**: Real-time data transmission
- **Containerized Services**: Docker-based deployment

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- CUDA-capable GPU (recommended for AI features)
- (Optional) Raspberry Pi for sensor data collection

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart-iot-devices-uniud.git
   cd smart-iot-devices-uniud
   ```

2. **Run the setup script**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Set up environment variables**
   Create a `.env` file with your configuration:
   ```env
   # For cloud-based models (HuggingFace)
   HUGGINGFACE_TOKEN=your_hf_token
   HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct
   
   # For local OLLAMA models
   # HUGGINGFACE_MODEL=ollama_chat/qwen3:0.6b
   
   # MQTT Configuration
   MQTT_BROKER=localhost
   MQTT_PORT=1883
   
   # Telegram Bot
   TELEGRAM_BOT_TOKEN=your_telegram_token
   ```

4. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Start OLLAMA (for local models)**
   ```bash
   docker run -d -p 11434:11434 --name ollama ollama/ollama
   docker exec ollama ollama pull qwen:0.6b  # Example model
   ```

## 📁 Project Structure

```
smart-iot-devices-uniud/
├── ai/                      # AI and machine learning components
│   ├── agent.py             # Main AI agent with tool integration
│   └── object_detection.py  # YOLO-based object detection
│
├── assistant/               # Voice assistant components
│   ├── lambda_function.py   # AWS Lambda function
│   └── bounded_alexa_controller.py  # Alexa skill controller
│
├── chatbot/                 # Telegram bot implementation
│   └── telegrambot.py       # Bot handlers and commands
│
├── weather-station/         # Environmental monitoring
│   ├── mqtt_publisher.py    # Sensor data publisher
│   ├── mqtt_listener.py     # MQTT message processor
│   └── sensor_read.py       # Sensor interface
│
├── setup.sh                # Comprehensive setup script
└── README.md               # Project documentation
```

## 🤖 AI Configuration

The project supports multiple AI model backends:

### 1. Cloud-based Models (HuggingFace)
```python
# .env configuration
HUGGINGFACE_TOKEN=your_hf_token
HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct
```

### 2. Local Models (OLLAMA)
```python
# .env configuration
HUGGINGFACE_MODEL=ollama_chat/qwen3:0.6b
```

### Model Selection
Switch between models by updating the `HUGGINGFACE_MODEL` in your `.env` file and restarting the service.

## 🛠 Usage Examples

### Running the AI Agent
```bash
python ai/agent.py
```

### Object Detection
```python
from ultralytics import YOLO

# Load a YOLOv11n PyTorch model
model = YOLO("yolov11n.pt")

# Export the model to NCNN format for optimization
model.export(format="ncnn")  # creates 'yolov11n_ncnn_model'

# Load the exported NCNN model
ncnn_model = YOLO("yolov11n_ncnn_model", task='detect')

# Run inference on an image
results = ncnn_model("https://ultralytics.com/images/bus.jpg")

# Process results
for result in results:
    boxes = result.boxes  # Boxes object for bbox outputs
    print(boxes.xyxy)     # Box coordinates in xyxy format
    print(boxes.conf)     # Confidence scores
    print(boxes.cls)      # Class predictions
```

### Voice Assistant
```bash
# Start the voice assistant
python assistant/bounded_alexa_controller.py
```

### Telegram Bot
```bash
# Start the Telegram bot
python chatbot/telegrambot.py
```

## ⚙️ Configuration

### MQTT Settings
- **Broker**: `localhost:1883`
- **Topics**:
  - `/sensor/data` - Sensor readings
  - `/ai/commands` - AI command interface
  - `/device/control` - Device control messages

### Database
- **InfluxDB**:
  - URL: `http://localhost:8086`
  - Database: `siotd`
  - Username: `admin`
  - Password: `admin123`

### AI Settings
- **Model**: Set via `HUGGINGFACE_MODEL` in `.env`
- **Temperature**: Controls randomness (0.0-1.0)
- **Max Tokens**: Response length limit

### Security
- **OLLAMA**: Runs on `http://localhost:11434`
- **API Keys**: Stored in `.env` (never commit this file)

## 🛠 Usage

### Starting the MQTT Listener
```bash
python3 weather-station/mqtt_listener.py
```

### Publishing Test Data
```bash
python3 weather-station/mqtt_publisher.py
```

## 📊 Data Flow

1. **Data Collection**: Sensors read environmental data
2. **Publishing**: Data is published to MQTT broker
3. **Subscription**: Listener processes and stores data
4. **Storage**: Data is saved to InfluxDB
5. **Visualization**: Web interface displays real-time data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Eclipse Mosquitto](https://mosquitto.org/)
- [InfluxDB](https://www.influxdata.com/)
- [Adafruit CircuitPython](https://circuitpython.org/)
- [Paho MQTT](https://www.eclipse.org/paho/)