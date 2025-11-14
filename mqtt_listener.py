import paho.mqtt.client as mqtt
import time

# --- CONFIGURATION ---
MQTT_SERVER = "localhost"
MQTT_PORT = 1883
SUBSCRIBE_TOPIC = "/sensor/data" # Listening on the topic the publisher sends to

# --- CALLBACKS ---

def on_connect(client, userdata, flags, rc):
    """Callback executed when the connection to the broker is established."""
    if rc == 0:
        print("Listener Connected successfully.")
        # Subscribing here ensures the subscription is renewed if the connection is lost
        client.subscribe(SUBSCRIBE_TOPIC)
        print(f"Listener subscribed to topic: {SUBSCRIBE_TOPIC}")
    else:
        print(f"Listener failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    """Callback executed when a PUBLISH message is received from the broker."""
    # Decode the payload from bytes to a string for printing
    payload_str = str(msg.payload.decode())
    print(f"\n--- MESSAGE RECEIVED ---")
    print(f"Topic: {msg.topic}")
    print(f"Payload: {payload_str}")
    print(f"Time: {time.strftime('%H:%M:%S')}")
    # Add your message handling logic here (e.g., saving to a database)

# --- MAIN EXECUTION ---

if __name__ == '__main__':
    # 1. Create and Configure Client
    listener_client = mqtt.Client()
    listener_client.on_connect = on_connect
    listener_client.on_message = on_message

    # 2. Connect to broker
    listener_client.connect(MQTT_SERVER, MQTT_PORT, 60)
    
    # 3. Start a blocking loop to continuously listen for incoming messages
    print("\n--- Starting MQTT Listener Loop (Press Ctrl+C to stop) ---")
    try:
        # loop_forever() is blocking and is best for clients that only listen
        listener_client.loop_forever() 
            
    except KeyboardInterrupt:
        print("\nListener stopped. Disconnecting...")
        listener_client.disconnect()
