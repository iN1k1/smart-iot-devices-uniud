from influxdb import InfluxDBClient

# --- Configuration Variables ---
# Replace these with your actual InfluxDB connection details
INFLUXDB_ADDRESS = 'localhost'
INFLUXDB_USER = 'user'
INFLUXDB_PASSWORD = 'userpass'
INFLUXDB_DATABASE = 'defaultdb'
INFLUXDB_PORT = 8086

# --- Database Class ---
class DB(object):
    # Constructor: Initializes the connection to InfluxDB
    def __init__(self):
        super(DB, self).__init__()
        # Creates an InfluxDB client object using the configuration
        self.influxdb_client = InfluxDBClient(host=INFLUXDB_ADDRESS, port=INFLUXDB_PORT,
                                              username=INFLUXDB_USER, password=INFLUXDB_PASSWORD, database=INFLUXDB_DATABASE)

    # Method to write a single sensor data point to the database
    def write_sensor_data(self, location, measurement, value):
        # Constructs the data point in the InfluxDB Line Protocol JSON format
        json_body = [
            {
                # 'measurement' is the name of the time series (e.g., 'temperature')
                'measurement': measurement,
                # 'tags' are indexed key-value pairs (e.g., 'location' = 'living_room')
                'tags': {
                    'location': location
                },
                # 'fields' are the actual data values (e.g., 'value' = 25.5)
                'fields': {
                    'value': value
                }
            }
        ]
        
        # Writes the prepared data to the database
        self.influxdb_client.write_points(json_body)
