import paho.mqtt.client as mqtt

# This function is called when the client successfully connects to the broker
def on_connect(client, userdata, flags, rc):
    # 'rc' is the result code, indicating success (rc=0) or failure
    print("Connected with result code " + str(rc))

# --- Publishing Function ---
def publish_message(topic, message):
    
    # 1. Create a new MQTT Client instance
    client = mqtt.Client()
    
    # 2. Assign the connection callback function
    client.on_connect = on_connect

    # 3. Connect to the MQTT broker
    # "localhost" is the broker's address, 1883 is the default MQTT port, 
    # and 60 is the keep-alive interval in seconds.
    client.connect("localhost", 1883, 60)

    # Debug info
    print("Publishing to MQTT topic: " + topic)
    print('Message: {}'.format(message))

    # 4. Publish the message
    client.publish(topic, message)
