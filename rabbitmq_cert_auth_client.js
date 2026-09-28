/**
 * RabbitMQ Client with Certificate-based Authentication (Mutual TLS)
 * Node.js implementation using amqplib
 */

const amqp = require('amqplib');
const fs = require('fs');
const path = require('path');

class RabbitMQCertClient {
    /**
     * Initialize RabbitMQ client with certificate authentication
     * 
     * @param {Object} config - Configuration object
     * @param {string} config.host - RabbitMQ server hostname
     * @param {number} config.port - RabbitMQ SSL port (typically 5671)
     * @param {string} config.certPath - Path to client certificate file
     * @param {string} config.keyPath - Path to client private key file
     * @param {string} config.caCertPath - Path to CA certificate file
     * @param {string} config.vhost - RabbitMQ virtual host (default: '/')
     */
    constructor(config) {
        this.host = config.host;
        this.port = config.port || 5671;
        this.certPath = config.certPath;
        this.keyPath = config.keyPath;
        this.caCertPath = config.caCertPath;
        this.vhost = config.vhost || '/';
        this.connection = null;
        this.channel = null;
    }

    /**
     * Create SSL options for mutual TLS authentication
     * @returns {Object} SSL options
     */
    _createSslOptions() {
        return {
            cert: fs.readFileSync(this.certPath),
            key: fs.readFileSync(this.keyPath),
            ca: [fs.readFileSync(this.caCertPath)],
            rejectUnauthorized: true,
            // servername: this.host  // Uncomment if using proper hostname verification
        };
    }

    /**
     * Establish connection to RabbitMQ using certificate authentication
     * @returns {Promise<boolean>} Success status
     */
    async connect() {
        try {
            const sslOptions = this._createSslOptions();
            
            // Build connection URL (no username/password needed!)
            const connectionUrl = `amqps://${this.host}:${this.port}${this.vhost}`;
            
            // Connect with SSL options
            this.connection = await amqp.connect(connectionUrl, {
                ...sslOptions,
                heartbeat: 60
            });

            // Handle connection events
            this.connection.on('error', (err) => {
                console.error('✗ Connection error:', err.message);
            });

            this.connection.on('close', () => {
                console.log('✓ Connection closed');
            });

            // Create channel
            this.channel = await this.connection.createChannel();
            
            console.log(`✓ Successfully connected to RabbitMQ at ${this.host}:${this.port} using certificate authentication`);
            return true;

        } catch (error) {
            console.error(`✗ Failed to connect to RabbitMQ: ${error.message}`);
            return false;
        }
    }

    /**
     * Publish a message to RabbitMQ
     * 
     * @param {string} exchange - Exchange name
     * @param {string} routingKey - Routing key
     * @param {string|Buffer} message - Message content
     * @param {Object} options - Message options
     */
    async publishMessage(exchange, routingKey, message, options = {}) {
        if (!this.channel) {
            throw new Error('Not connected to RabbitMQ. Call connect() first.');
        }

        const defaultOptions = {
            persistent: true,
            ...options
        };

        const content = Buffer.isBuffer(message) ? message : Buffer.from(message);
        
        const result = this.channel.publish(
            exchange,
            routingKey,
            content,
            defaultOptions
        );

        if (result) {
            console.log(`✓ Message published to exchange '${exchange}' with routing key '${routingKey}'`);
        } else {
            console.warn('⚠ Message not published (channel buffer full)');
        }

        return result;
    }

    /**
     * Consume messages from a queue
     * 
     * @param {string} queueName - Queue name to consume from
     * @param {Function} callback - Callback function to process messages
     * @param {Object} options - Consumer options
     */
    async consumeMessages(queueName, callback, options = {}) {
        if (!this.channel) {
            throw new Error('Not connected to RabbitMQ. Call connect() first.');
        }

        // Assert queue exists
        await this.channel.assertQueue(queueName, {
            durable: true,
            ...options.queueOptions
        });

        // Set prefetch
        await this.channel.prefetch(options.prefetch || 1);

        // Start consuming
        await this.channel.consume(queueName, async (msg) => {
            if (msg) {
                try {
                    await callback(msg);
                    this.channel.ack(msg);
                } catch (error) {
                    console.error('✗ Error processing message:', error);
                    // Reject and requeue the message
                    this.channel.nack(msg, false, true);
                }
            }
        }, {
            noAck: false,
            ...options.consumerOptions
        });

        console.log(`✓ Waiting for messages from queue '${queueName}'. Press CTRL+C to exit.`);
    }

    /**
     * Close the connection to RabbitMQ
     */
    async close() {
        try {
            if (this.channel) {
                await this.channel.close();
            }
            if (this.connection) {
                await this.connection.close();
            }
            console.log('✓ Connection closed gracefully');
        } catch (error) {
            console.error('✗ Error closing connection:', error.message);
        }
    }
}

// Example usage
async function main() {
    // Configuration
    const config = {
        host: 'localhost',
        port: 5671,
        certPath: './certs/client/cert.pem',
        keyPath: './certs/client/key.pem',
        caCertPath: './certs/ca/ca_cert.pem',
        vhost: '/'
    };

    // Create client instance
    const client = new RabbitMQCertClient(config);

    try {
        // Connect to RabbitMQ
        if (await client.connect()) {
            // Example: Publish a message
            await client.publishMessage(
                '',  // default exchange
                'test_queue',
                'Hello from certificate-authenticated Node.js client!'
            );

            // Example: Consume messages (uncomment to test)
            /*
            await client.consumeMessages('test_queue', async (msg) => {
                console.log(`✓ Received message: ${msg.content.toString()}`);
            });
            */

            // Give some time for async operations
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            await client.close();
        }
    } catch (error) {
        console.error('✗ Error:', error);
        process.exit(1);
    }
}

// Run if executed directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = RabbitMQCertClient;
