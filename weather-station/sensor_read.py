import adafruit_dht
import time
import board

# Type of sensor, can be adafruit_dht.DHT11, adafruit_dht.DHT22, or adafruit_dht.AM2302.
# NB: Be careful this is the GPIO number NOT the physical board numbering!!!
dht_device = adafruit_dht.DHT11(board.D17)

# Read humidity and temperature
def read():
    humidity = None
    temperature = None

    try:
        # Try reading from the sensor
        temperature = dht_device.temperature
        humidity = dht_device.humidity
    except RuntimeError as error:
        # Errors happen fairly often, DHT's are hard to read, just keep going
        print(error.args[0])
        time.sleep(1.0)
    except Exception as error:
        dht_device.exit()
        print('DHT killed!')
        raise error

    return humidity, temperature

if __name__ == '__main__':
    # Infinite loop
    while True:
        # Read from sensor
        humidity, temperature = read()

        if humidity is not None and temperature is not None:
            # Print Temperature and Humidity on shell window
            print('Temp={0:0.1f}°C Humidity={1:0.1f}%'.format(temperature, humidity))

        # Wait 5 seconds and read again from the sensor
        time.sleep(5)
