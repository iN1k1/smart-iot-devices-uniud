import boto3
import time
from gpiozero import LED

# Initialize LED
led = LED("BOARD11")

# AWS SQS Configuration
access_key = ''
access_secret = ''
region = 'eu-central-1'
queue_url = ''
client = boto3.client('sqs', 
                     aws_access_key_id=access_key, 
                     aws_secret_access_key=access_secret, 
                     region_name=region)

def pop_sqs_message():
    """Retrieve and delete a message from the SQS queue."""
    responses = client.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=10,
        WaitTimeSeconds=20  # Enable long polling
    )
    
    if 'Messages' in responses:
        message = responses['Messages'][0]
        print(f"Received message: {message['Body']}")
        client.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
        return message['Body']
    return None

def turn_led_on():
    print("Turning LED on")
    led.on()

def turn_led_off():
    print("Turning LED off")
    led.off()

def cleanup():
    led.close()

# Register cleanup to be called on script exit
import atexit
atexit.register(cleanup)

if __name__ == '__main__':
    try:
        while True:
            status = pop_sqs_message()
            if status is not None:
                if status.lower() == 'on':
                    turn_led_on()
                elif status.lower() == 'off':
                    turn_led_off()
                else:
                    print(f'Received unknown status: {status}')
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting...")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cleanup()