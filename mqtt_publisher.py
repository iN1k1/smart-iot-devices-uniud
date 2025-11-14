import paho.mqtt.client as mqtt
import time

# --- CONFIGURATION ---
MQTT_SERVER = "localhost"
MQTT_PORT = 1883
PUBLISH_TOPIC = "/sensor/data"

# --- CALLBACKS (Minimal for publishing) ---

def on_connect(client, userdata, flags, rc):
    """Callback executed when the connection to the broker is established."""
    if rc == 0:
        print("Publisher Connected successfully.")
    else:
        print(f"Publisher failed to connect, return code {rc}")

def on_publish(client, userdata, mid):
    """Callback executed when a message has been successfully published."""
    print(f"Message ID {mid} published successfully.")
    
# --- PUBLISHING FUNCTION ---

def publish_message(client, topic, message):
    """Publishes a message using the provided MQTT client object."""
    print(f"Attempting to publish to topic: {topic}")
    client.publish(topic, message)

# --- MAIN EXECUTION ---

if __name__ == '__main__':
    # 1. Create and Configure Client
    publisher_client = mqtt.Client()
    publisher_client.on_connect = on_connect
    publisher_client.on_publish = on_publish

    # 2. Connect to broker
    publisher_client.connect(MQTT_SERVER, MQTT_PORT, 60)
    
    # 3. Start a non-blocking loop to handle callbacks (like on_connect/on_publish)
    publisher_client.loop_start() 

    print("\n--- Starting Publisher Loop ---")
    counter = 1
    try:
        while True:
            # Example data to send
            example_data = f"Temperature Reading {counter} @ {time.strftime('%H:%M:%S')}"
            
            # Use the defined publish function
            publish_message(publisher_client, PUBLISH_TOPIC, example_data)
            
            counter += 1
            # Wait 5 seconds before publishing again
            time.sleep(5) 
            
    except KeyboardInterrupt:
        print("\nPublisher loop stopped. Disconnecting...")
        publisher_client.loop_stop()
        publisher_client.disconnect()
