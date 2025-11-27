import mqtt_publisher
import sensor_read
import db
import time
import paho.mqtt.client as mqtt

publisher_client = mqtt.Client()
publisher_client.on_connect = mqtt_publisher.on_connect
publisher_client.on_publish = mqtt_publisher.on_publish

# 2. Connect to broker
publisher_client.connect(mqtt_publisher.MQTT_SERVER,
                         mqtt_publisher.MQTT_PORT, 60)

# 3. Start a non-blocking loop to handle callbacks (like on_connect/on_publish)
publisher_client.loop_start()

database = db.DB()

# REPEAT..
while True:

    # LEGGO DAL SENSORE
    h, t = sensor_read.read()

    # SCRIVO SU DB
    database.write_sensor_data('lab', 'humidity',h)
    database.write_sensor_data('lab', 'temperature',t)

    # INVIO VIA MQTT
    mqtt_publisher.publish_message(publisher_client, '/m/t', f'valore temp {t}')
    mqtt_publisher.publish_message(publisher_client, '/m/h', f'valore hum {h}')

    time.sleep(1)