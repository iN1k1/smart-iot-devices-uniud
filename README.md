# Smart IoT Devices - University of Udine

A comprehensive IoT project demonstrating sensor data collection, MQTT messaging, and data visualization using modern technologies.

## 🌟 Features

- **Sensor Data Collection**: Read environmental data using DHT sensors
- **MQTT Messaging**: Real-time data transmission using MQTT protocol
- **Data Storage**: Store time-series data in InfluxDB
- **Visualization**: Web-based dashboard for data monitoring
- **Containerized Services**: Easy deployment using Docker

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- Raspberry Pi (for sensor data collection)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart-iot-devices-uniud.git
   cd smart-iot-devices-uniud
   ```

2. **Set up the environment**
   ```bash
   cd setup-scripts
   ./env_setup.sh
   ```

3. **Start the services**
   ```bash
   ./mosquitto_setup.sh
   ./influx_db_setup.sh
   ```

4. **Install sensor dependencies** (on Raspberry Pi)
   ```bash
   ./adafruit_setup.sh
   ```

## 📁 Project Structure

```
smart-iot-devices-uniud/
├── setup-scripts/       # Setup and configuration scripts
│   ├── env_setup.sh     # Environment setup
│   ├── mosquitto_setup.sh  # MQTT broker setup
│   ├── influx_db_setup.sh  # Database setup
│   └── adafruit_setup.sh   # Sensor dependencies
├── weather-station/     # Sensor and data collection
│   ├── mqtt_publisher.py  # MQTT publisher for sensor data
│   ├── mqtt_listener.py   # MQTT subscriber for data processing
│   └── sensor_read.py     # Sensor data collection
└── README.md           # This file
```

## 🔧 Configuration

### MQTT Configuration
- **Broker**: `localhost:1883`
- **Default Topic**: `/sensor/data`

### InfluxDB Configuration
- **URL**: `http://localhost:8086`
- **Database**: `defaultdb`
- **Username**: `admin`
- **Password**: `adminpass`

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