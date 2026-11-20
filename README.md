# Smart IoT Devices - University of Udine

Code examples for the **Smart IoT Devices** course at the University of Udine. They run on a
Raspberry Pi and cover GPIO basics, a sensor-to-dashboard weather station, a Telegram bot,
an Alexa-controlled LED, and AI on the edge (YOLO object detection and an LLM agent).

## Repository contents

| Folder | Files | What it shows |
|---|---|---|
| `basics/` | `led.py`, `button.py`, `button_callbacks.py` | Blink an LED, poll a button, react to button events with `gpiozero` |
| `weather-station/` | `sensor_read.py`, `mqtt_publisher.py`, `mqtt_listener.py`, `db.py`, `station.py` | Read a DHT11, publish over MQTT, store in InfluxDB, and the full pipeline in `station.py` |
| `chatbot/` | `telegrambot.py`, `sanity_check.py` | A minimal Telegram bot (`/start`, `/help`, echo) and a token check |
| `chatbot/escape_lab/` | `escape_lab_starter.py`, `escape_lab.py` | "Escape the Lab": a 60-minute Telegram bot lab with a starter and a solution ([guide](chatbot/escape_lab/README.md)) |
| `assistant/` | `lambda_function.py`, `bounded_alexa_controller.py` | An Alexa skill (AWS Lambda) sends "on"/"off" through AWS SQS to a Pi that switches an LED |
| `ai/` | `object_detection.py`, `agent.py` | YOLO object detection exported to NCNN, and a smolagents LLM agent with sensor and LED tools |
| `setup.sh` | | Sets up the Pi: virtual environment, Docker services and Python packages |
| `tests/` | `setup_test.sh` | Tests for `setup.sh` |

## Requirements

- A Raspberry Pi 4 or 5 with **64-bit Raspberry Pi OS (Bookworm)**. YOLO and Ollama don't support the 32-bit OS.
- Internet access and `sudo` rights. `setup.sh` installs Docker and everything else it needs.
- For the hardware examples: an LED, a push button and a DHT11 sensor (see [Wiring](#wiring)).

## Setup

```bash
git clone https://github.com/iN1k1/smart-iot-devices-uniud.git
cd smart-iot-devices-uniud
./setup.sh
```

With no options, `setup.sh` runs every step. To run only some, pass their flags:

| Flag | What it does |
|---|---|
| `--env-setup` | Creates `~/Desktop/SIoTD-Projects` and its `siotd.conf`, creates the virtual environment `~/siotdenv` (activated from `~/.bashrc`), installs Docker, and installs pip, setuptools, wheel and boto3 |
| `--recreate-venv` | Deletes and re-creates `~/siotdenv`. Alone it runs every step; with other flags it runs only those (e.g. `./setup.sh --recreate-venv --telegram`) |
| `--mosquitto` | Installs `paho-mqtt` and starts the Mosquitto MQTT broker in Docker |
| `--influxdb` | Installs the `influxdb` client and starts InfluxDB 1.8 in Docker |
| `--grafana` | Starts Grafana in Docker |
| `--adafruit` | Installs the DHT sensor library (`adafruit-circuitpython-dht`) |
| `--telegram` | Installs `python-telegram-bot` and checks the bot token in `siotd.conf` |
| `--ai` | Installs `smolagents[litellm]`, `ultralytics` (with PyTorch), `opencv-python` and `ncnn`; installs Ollama and pulls the `qwen3:0.6b` model; creates `~/Desktop/SIoTD-Projects/ai/.env` |
| `--all` | Runs every step |

Run `--env-setup` once before using the other flags on their own, because they install into
the virtual environment it creates. The `--ai` step downloads PyTorch and an LLM, so it
takes a while and needs a few GB of free space.

### Services started by setup

| Service | Address | Credentials |
|---|---|---|
| Mosquitto (MQTT) | `localhost:1883` (WebSockets on `9001`) | Anonymous access allowed |
| InfluxDB 1.8 | `http://localhost:8086` | Database `defaultdb`; user `user` / `userpass`; admin `admin` / `adminpass` |
| Grafana | `http://<pi-address>:3000` | `admin` / `admin` (Grafana asks you to change it at first login) |
| Ollama | `http://localhost:11434` | None; runs as the `ollama` systemd service |

These are default lab credentials. Change them on any Pi reachable from outside the lab network.

### Configuration files

- **`~/Desktop/SIoTD-Projects/siotd.conf`**: written by `--env-setup`, and overwritten every
  time that step runs. It holds the project paths and `TELEGRAM_BOT_TOKEN`, which the
  Telegram examples read. Put your own token from [@BotFather](https://t.me/BotFather) there.
- **`.env` for the AI agent**: `ai/agent.py` loads a `.env` file with `HUGGINGFACE_TOKEN`,
  `HUGGINGFACE_MODEL`, `TEMPERATURE`, `MAX_TOKENS` and `LED_PIN`. `--ai` creates a template
  at `~/Desktop/SIoTD-Projects/ai/.env`. The agent looks for `.env` in the folder of the
  script and its parent folders, so keep the file next to the `agent.py` you run.

## Wiring

| Example | Component | Pin |
|---|---|---|
| `basics/led.py`, `assistant/bounded_alexa_controller.py`, `ai/agent.py` | LED (with a resistor) | Physical pin 11 (`BOARD11`, GPIO17) |
| `basics/button.py`, `basics/button_callbacks.py` | Button between the pin and 3.3 V (`pull_up=False`) | Physical pin 11 (`BOARD11`, GPIO17) |
| `weather-station/sensor_read.py` | DHT11 data pin | GPIO17 (`board.D17`), physical pin 11 |

All examples use pin 11, so wire one component at a time or change the pin in the code.

## Running the examples

Activate the virtual environment first. New terminals do it automatically through `~/.bashrc`.

```bash
source ~/siotdenv/bin/activate
```

### Basics

```bash
python basics/led.py               # blink the LED every second
python basics/button.py            # print while the button is held
python basics/button_callbacks.py  # print on press and release events
```

### Weather station

Needs `--mosquitto`, `--influxdb` and `--adafruit`, plus `--grafana` for dashboards.

```bash
python weather-station/sensor_read.py     # print temperature and humidity every 5 s
python weather-station/mqtt_listener.py   # subscribe to /sensor/data and print messages
python weather-station/mqtt_publisher.py  # publish a test message to /sensor/data every 5 s
python weather-station/station.py         # every second: read the DHT11, write to InfluxDB, publish on /m/t and /m/h
```

`station.py` writes the `temperature` and `humidity` measurements, tagged with location
`lab`, to the `defaultdb` database. In Grafana, add InfluxDB as a data source with URL
`http://localhost:8086`, database `defaultdb`, user `user` and password `userpass`.

### Telegram bot

Needs `--telegram` and your bot token in `siotd.conf`.

```bash
python chatbot/sanity_check.py  # prints the bot's details if the token is valid
python chatbot/telegrambot.py   # /start, /help, and echoes any text
```

For the "Escape the Lab" exercise, see [chatbot/escape_lab/README.md](chatbot/escape_lab/README.md).

### Alexa-controlled LED

1. Create an Alexa skill with an `ExampleIntent` intent and a `status` slot ("on"/"off").
2. Deploy `assistant/lambda_function.py` as its AWS Lambda backend. It sends the slot value to an AWS SQS queue.
3. Fill in the same `queue_url`, AWS keys and region in both `lambda_function.py` and `bounded_alexa_controller.py`.
4. On the Pi, run the controller, which polls the queue and switches the LED:
   ```bash
   python assistant/bounded_alexa_controller.py
   ```

### AI on the edge

Needs `--ai`.

**Object detection:** loads a YOLO11 nano model, exports it to NCNN (the fastest format on
the Pi), detects objects in a sample image and saves `detection_result.jpg`.

```bash
python ai/object_detection.py
```

**LLM agent:** a smolagents `CodeAgent` with tools to read simulated temperature and
humidity, check comfort, and open or close a "door" (the LED). It answers a sample
question, then lets you chat with it.

```bash
python ai/agent.py
```

Choose the model in the agent's `.env`:

```env
# Hosted model (HuggingFace, needs a token and internet)
HUGGINGFACE_TOKEN=hf_...
HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct

# Local model served by Ollama (installed by --ai)
HUGGINGFACE_MODEL=ollama_chat/qwen3:0.6b
```

To pull a different Ollama model during setup, run `OLLAMA_MODEL=qwen3:1.7b ./setup.sh --ai`,
or later `ollama pull <model>`. Check the server with `systemctl status ollama` and the
downloaded models with `ollama list`.

## Tests

```bash
bash tests/setup_test.sh
```

The tests replace `pip`, `sudo` and other system commands with stubs, so they don't change
the system. They need bash 4 or newer: Raspberry Pi OS has it, macOS ships bash 3.2.
