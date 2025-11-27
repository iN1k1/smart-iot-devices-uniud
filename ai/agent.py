#!/usr/bin/env python3
"""
HuggingFace SmolAgents with Temperature and Humidity Sensors + LED Control
This app uses the smolagents library to create an AI agent that can query
simulated temperature and humidity sensors, and control an LED using gpiozero.

Installation:
pip install smolagents python-dotenv gpiozero
"""

import os
import random
import time
from dataclasses import dataclass
from dotenv import load_dotenv

from smolagents import CodeAgent, tool, InferenceClientModel
from gpiozero import LED

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
HUGGINGFACE_TOKEN = os.getenv('HUGGINGFACE_TOKEN', 'your_huggingface_token_here')
HUGGINGFACE_MODEL = os.getenv('HUGGINGFACE_MODEL', 'meta-llama/Meta-Llama-3-8B-Instruct')
TEMPERATURE = float(os.getenv('TEMPERATURE', '0.7'))
MAX_TOKENS = int(os.getenv('MAX_TOKENS', '2048'))
LED_PIN = os.getenv('LED_PIN', 'BOARD11')

# Validate token before proceeding
if not HUGGINGFACE_TOKEN or HUGGINGFACE_TOKEN == 'your_huggingface_token_here':
    print("❌ Error: No valid HuggingFace token found.")
    print("\nPlease follow these steps:")
    print("1. Create a .env file in the ai directory")
    print("2. Add your HuggingFace token to the .env file like this:")
    print("   HUGGINGFACE_TOKEN=your_actual_token_here")
    print("3. Get a token from: https://huggingface.co/settings/tokens")
    print("\nExample .env file:")
    print("HUGGINGFACE_TOKEN=your_actual_token_here")
    print("HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct")
    print("TEMPERATURE=0.7")
    print("MAX_TOKENS=2048")
    exit(1)

# Set default seeds for deterministic sensor simulations
DEFAULT_TEMP_SEED = 42
DEFAULT_HUMIDITY_SEED = 24


@dataclass
class SensorReading:
    """Container for sensor readings with metadata"""
    value: float
    unit: str
    timestamp: float
    sensor_id: str


class PhysicalSensors:
    """Simulates temperature and humidity sensors"""

    def __init__(self):
        self.temp_seed = DEFAULT_TEMP_SEED
        self.humidity_seed = DEFAULT_HUMIDITY_SEED

    def read_temperature(self) -> SensorReading:
        """Simulates a temperature sensor (DHT22 or similar)"""
        temp = 20.0 + random.uniform(-2, 8)  # Simulate temperature between 18°C and 28°C
        return SensorReading(
            value=round(temp, 1),
            unit="°C",
            timestamp=time.time(),
            sensor_id="TEMP_001"
        )

    def read_humidity(self) -> SensorReading:
        """Simulates a humidity sensor"""
        humidity = 45.0 + random.uniform(0, 20)  # Simulate humidity between 45% and 65%
        return SensorReading(
            value=round(humidity, 1),
            unit="%",
            timestamp=time.time(),
            sensor_id="HUM_001"
        )


class LEDController:
    """Controls an LED using gpiozero"""

    def __init__(self, pin):
        try:
            self.led = LED(pin)
            self.pin = pin
            print(f"✓ LED initialized on GPIO pin {pin}")
        except Exception as e:
            print(f"❌ Failed to initialize LED on pin {pin}: {e}")
            raise

    def turn_on(self) -> str:
        """Turns the LED on"""
        try:
            self.led.on()
            return f"🟢 LED (GPIO {self.pin}) turned ON"
        except Exception as e:
            return f"❌ Error turning LED on: {e}"

    def turn_off(self) -> str:
        """Turns the LED off"""
        try:
            self.led.off()
            return f"⚫ LED (GPIO {self.pin}) turned OFF"
        except Exception as e:
            return f"❌ Error turning LED off: {e}"

    def get_status(self) -> str:
        """Gets the current LED status"""
        try:
            status = "ON" if self.led.is_lit else "OFF"
            indicator = "🟢" if self.led.is_lit else "⚫"
            return f"{indicator} LED (GPIO {self.pin}) is currently {status}"
        except Exception as e:
            return f"❌ Error getting LED status: {e}"

    def cleanup(self):
        """Cleanup GPIO resources"""
        try:
            self.led.close()
            print(f"✓ LED (GPIO {self.pin}) cleaned up")
        except Exception as e:
            print(f"Warning: Error during cleanup: {e}")


# Initialize global instances
sensors = PhysicalSensors()
led = LEDController(LED_PIN)


@tool
def read_temperature() -> str:
    """
    Reads the current temperature from the temperature sensor.
    Returns the temperature in Celsius with sensor ID and timestamp.
    """
    reading = sensors.read_temperature()
    return f"Temperature: {reading.value}{reading.unit} (Sensor: {reading.sensor_id}, Time: {reading.timestamp})"


@tool
def read_humidity() -> str:
    """
    Reads the current humidity from the humidity sensor.
    Returns the relative humidity percentage.
    """
    reading = sensors.read_humidity()
    return f"Humidity: {reading.value}{reading.unit} (Sensor: {reading.sensor_id}, Time: {reading.timestamp})"


@tool
def read_environment() -> str:
    """
    Reads both temperature and humidity sensors and returns a combined report.
    """
    temp = sensors.read_temperature()
    humidity = sensors.read_humidity()

    report = [
        "=== Environment Status ===",
        f"• Temperature: {temp.value}{temp.unit}",
        f"• Humidity: {humidity.value}{humidity.unit}",
        f"\nLast updated: {time.ctime()}"
    ]

    return "\n".join(report)


@tool
def check_comfort_level() -> str:
    """
    Analyzes temperature and humidity to determine if the environment is comfortable.
    Comfortable ranges: Temperature 18-24°C, Humidity 40-60%.
    """
    temp = sensors.read_temperature()
    humidity = sensors.read_humidity()

    comfort_issues = []

    # Check temperature
    if temp.value < 18:
        comfort_issues.append(f"too cold ({temp.value}°C)")
    elif temp.value > 24:
        comfort_issues.append(f"too warm ({temp.value}°C)")

    # Check humidity
    if humidity.value < 40:
        comfort_issues.append(f"low humidity ({humidity.value}%)")
    elif humidity.value > 60:
        comfort_issues.append(f"high humidity ({humidity.value}%)")

    if not comfort_issues:
        return "The environment is comfortable. Temperature and humidity are within ideal ranges."
    else:
        return f"The environment is {' and '.join(comfort_issues)}. Consider adjusting the conditions."


@tool
def open_door() -> str:
    """
    Opens the door and turns the LED on.
    This simulates turning on an LED indicator when the door is opened.
    """
    return led.turn_on()


@tool
def close_door() -> str:
    """
    Closes the door and turns the LED off.
    This simulates turning off an LED indicator when the door is closed.
    """
    return led.turn_off()


@tool
def get_led_status() -> str:
    """
    Gets the current LED status.
    """
    return led.get_status()


def create_sensor_agent(model_id: str = None, token: str = None):
    """
    Creates a SmolAgent with temperature, humidity, and LED control tools.
    """
    model_id = model_id or HUGGINGFACE_MODEL
    token = token or HUGGINGFACE_TOKEN

    if not token or token == 'your_huggingface_token_here':
        print("⚠️  Warning: No valid HuggingFace token provided. Some features may not work without it.")

    # Define available tools
    sensor_tools = [
        read_temperature,
        read_humidity,
        read_environment,
        check_comfort_level,
        open_door,
        close_door,
        get_led_status
    ]

    # Initialize the model
    model = InferenceClientModel(model_id=model_id, token=token)

    # Create agent with tools
    agent = CodeAgent(
        tools=sensor_tools,
        model=model,
        max_steps=10,
        # stream_outputs=True
    )

    return agent


def run_examples(agent):
    """Run example queries to demonstrate the agent's capabilities"""
    print("\n=== Example Queries ===")
    examples = [
        "What's the current temperature?",
        # "How humid is it right now?",
        # "Is the environment comfortable?",
        # "Give me an environment status report",
        # "Open the door",
        # "What's the LED status?",
        # "Close the door"
    ]

    for i, query in enumerate(examples, 1):
        print(f"\nExample {i}: {query}")
        try:
            response = agent.run(query)
            print(f"Response: {response}")
            time.sleep(1)  # Add a small delay between examples
        except Exception as e:
            print(f"Error: {e}")


def run_interactive(agent):
    """Run an interactive session with the agent"""
    print("\n=== Interactive Mode ===")
    print("Type 'exit' or 'quit' to end the session\n")

    while True:
        try:
            user_input = input("You: ").strip()
            if user_input.lower() in ['exit', 'quit']:
                break

            if not user_input:
                continue

            print("\nProcessing...\n")
            response = agent.run(user_input)
            print(f"\n{response}\n")

        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}\n")


if __name__ == "__main__":
    print("🌡️  HuggingFace SmolAgents with Temperature, Humidity & LED Control\n")

    print("Configuration:")
    print(f"- Model: {HUGGINGFACE_MODEL}")
    print(
        f"- Token: {'*' * 8 + HUGGINGFACE_TOKEN[-4:] if HUGGINGFACE_TOKEN and HUGGINGFACE_TOKEN != 'your_huggingface_token_here' else 'Not provided'}")
    print(f"- Temperature: {TEMPERATURE}")
    print(f"- Max tokens: {MAX_TOKENS}")
    print(f"- LED GPIO Pin: {LED_PIN}")
    print("\nSensor simulation seeds:")
    print(f"  - Temperature: {DEFAULT_TEMP_SEED}")
    print(f"  - Humidity: {DEFAULT_HUMIDITY_SEED}")

    print("\nInitializing sensor agent...")
    print("Note: Using HuggingFace API (requires internet connection)")
    print("You can also use local models or other providers.\n")

    try:
        # Create and run the agent
        agent = create_sensor_agent()
        run_examples(agent)
        run_interactive(agent)

    except Exception as e:
        print(f"❌ Failed to initialize agent: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure you have installed the required packages:")
        print("   pip install smolagents python-dotenv gpiozero")
        print("2. Make sure you have a valid HuggingFace token")
        print("3. Check your .env file")
        print("   It should contain these variables:")
        print("   HUGGINGFACE_TOKEN=your_token_here")
        print("   HUGGINGFACE_MODEL=meta-llama/Meta-Llama-3-8B-Instruct")
        print("   TEMPERATURE=0.7")
        print("   MAX_TOKENS=2048")
        print("   LED_PIN=17")
        print("4. Check your internet connection for API access")
    finally:
        # Cleanup GPIO resources
        try:
            led.cleanup()
        except:
            pass