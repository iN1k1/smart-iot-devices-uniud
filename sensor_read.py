# Import necessary libraries
import adafruit_dht
import time
import board

# Configuration: Define the sensor type and the GPIO pin it's connected to.
# NB: Be careful this is the GPIO number NOT the physical board numbering!!!
# Type of sensor, can be adafruit_dht.DHT11, adafruit_dht.DHT22, or adafruit_dht.AM2302.
dht_device = adafruit_dht.DHT11(board.D17)

# ---
# Function to Read humidity and temperature
# ---
def read():
    # Initialize variables
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
        # Catch other errors, exit the device, and re-raise the error
        dht_device.exit()
        print('DHT killed')
        raise error
    
    return humidity, temperature

# ---
# Main Execution Block
# ---
if __name__ == '__main__':
    # Infinite loop to continuously read data
    while True:
        
        # Read from sensor
        humidity, temperature = read()
        
        # Check if the readings were successful (not None)
        if humidity is not None and temperature is not None:
            # Print Temperature and Humidity on shell window
            # Formats the output to one decimal place
            print('Temp={0:0.1f}°C Humidity={1:0.1f}%'.format(temperature, humidity))
        
        # Wait 1 second and read again from the sensor
        time.sleep(1)
