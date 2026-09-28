"""
RabbitMQ Client with Certificate-based Authentication (Mutual TLS)

This client connects to RabbitMQ using SSL/TLS certificates instead of username/password.
"""

import pika
import ssl
import sys
from pathlib import Path


class RabbitMQCertClient:
    """RabbitMQ client that authenticates using SSL certificates"""
    
    def __init__(self, host, port, cert_path, key_path, ca_cert_path, virtual_host='/'):
        """
        Initialize RabbitMQ client with certificate authentication.
        
        Args:
            host (str): RabbitMQ server hostname
            port (int): RabbitMQ SSL port (typically 5671)
            cert_path (str): Path to client certificate file
            key_path (str): Path to client private key file
            ca_cert_path (str): Path to CA certificate file
            virtual_host (str): RabbitMQ virtual host (default: '/')
        """
        self.host = host
        self.port = port
        self.cert_path = cert_path
        self.key_path = key_path
        self.ca_cert_path = ca_cert_path
        self.virtual_host = virtual_host
        self.connection = None
        self.channel = None
        
    def _create_ssl_context(self):
        """Create and configure SSL context for mutual TLS authentication"""
        context = ssl.create_default_context(cafile=self.ca_cert_path)
        
        # Load client certificate and private key
        context.load_cert_chain(
            certfile=self.cert_path,
            keyfile=self.key_path
        )
        
        # Require certificate verification
        context.check_hostname = False  # Set to True if using proper hostnames
        context.verify_mode = ssl.CERT_REQUIRED
        
        return context
    
    def connect(self):
        """Establish connection to RabbitMQ using certificate authentication"""
        try:
            ssl_context = self._create_ssl_context()
            
            # SSL connection parameters
            ssl_options = pika.SSLOptions(ssl_context, self.host)
            
            # Connection parameters (no username/password needed!)
            credentials = pika.credentials.ExternalCredentials()
            
            parameters = pika.ConnectionParameters(
                host=self.host,
                port=self.port,
                virtual_host=self.virtual_host,
                credentials=credentials,
                ssl_options=ssl_options,
                heartbeat=600,
                blocked_connection_timeout=300
            )
            
            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            
            print(f"✓ Successfully connected to RabbitMQ at {self.host}:{self.port} using certificate authentication")
            return True
            
        except Exception as e:
            print(f"✗ Failed to connect to RabbitMQ: {e}")
            return False
    
    def publish_message(self, exchange, routing_key, message, properties=None):
        """
        Publish a message to RabbitMQ
        
        Args:
            exchange (str): Exchange name
            routing_key (str): Routing key
            message (str): Message content
            properties: Message properties (optional)
        """
        if not self.channel:
            raise RuntimeError("Not connected to RabbitMQ. Call connect() first.")
        
        if properties is None:
            properties = pika.BasicProperties(
                delivery_mode=2,  # Make message persistent
            )
        
        self.channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=message,
            properties=properties
        )
        print(f"✓ Message published to exchange '{exchange}' with routing key '{routing_key}'")
    
    def consume_messages(self, queue_name, callback):
        """
        Consume messages from a queue
        
        Args:
            queue_name (str): Queue name to consume from
            callback (function): Callback function to process messages
        """
        if not self.channel:
            raise RuntimeError("Not connected to RabbitMQ. Call connect() first.")
        
        # Declare queue (idempotent operation)
        self.channel.queue_declare(queue=queue_name, durable=True)
        
        # Set QoS
        self.channel.basic_qos(prefetch_count=1)
        
        # Start consuming
        self.channel.basic_consume(
            queue=queue_name,
            on_message_callback=callback
        )
        
        print(f"✓ Waiting for messages from queue '{queue_name}'. Press CTRL+C to exit.")
        self.channel.start_consuming()
    
    def close(self):
        """Close the connection to RabbitMQ"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            print("✓ Connection closed")


def example_callback(ch, method, properties, body):
    """Example callback function for consuming messages"""
    print(f"✓ Received message: {body.decode()}")
    ch.basic_ack(delivery_tag=method.delivery_tag)


def main():
    """Example usage of RabbitMQ certificate-based client"""
    
    # Configuration
    RABBITMQ_HOST = "localhost"
    RABBITMQ_SSL_PORT = 5671
    CLIENT_CERT = "./certs/client/cert.pem"
    CLIENT_KEY = "./certs/client/key.pem"
    CA_CERT = "./certs/ca/ca_cert.pem"
    
    # Create client instance
    client = RabbitMQCertClient(
        host=RABBITMQ_HOST,
        port=RABBITMQ_SSL_PORT,
        cert_path=CLIENT_CERT,
        key_path=CLIENT_KEY,
        ca_cert_path=CA_CERT
    )
    
    # Connect to RabbitMQ
    if client.connect():
        try:
            # Example: Publish a message
            client.publish_message(
                exchange='',
                routing_key='test_queue',
                message='Hello from certificate-authenticated client!'
            )
            
            # Example: Consume messages (uncomment to test)
            # client.consume_messages('test_queue', example_callback)
            
        except KeyboardInterrupt:
            print("\nInterrupted by user")
        finally:
            client.close()
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
