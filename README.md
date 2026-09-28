# RabbitMQ Certificate-Based Authentication

Complete implementation of RabbitMQ client authentication using SSL/TLS certificates instead of username/password credentials.

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

Run the complete setup script that handles everything:

```bash
./complete_setup.sh
```

This will:
1. Generate all required certificates
2. Start RabbitMQ with Docker
3. Configure users and permissions
4. Provide connection details

### Option 2: Manual Setup

```bash
# 1. Generate certificates
./generate_certificates.sh

# 2. Start RabbitMQ
docker-compose up -d

# 3. Configure server
./server_setup.sh

# 4. Test client
python3 rabbitmq_cert_auth_client.py
# or
npm install && node rabbitmq_cert_auth_client.js
```

## 📚 Documentation

- **[Complete Guide](README_CERTIFICATES.md)** - Comprehensive documentation including architecture, security practices, and troubleshooting
- **[Comparison Guide](COMPARISON.md)** - Certificate-based vs username/password authentication comparison
- **Client Implementations**:
  - [Python Client](rabbitmq_cert_auth_client.py)
  - [Node.js Client](rabbitmq_cert_auth_client.js)
- **Server Configuration**:
  - [RabbitMQ Config](rabbitmq.conf)
  - [Docker Compose](docker-compose.yml)

## 🔑 Key Features

✅ **No passwords needed** - Authentication via cryptographic certificates  
✅ **Mutual TLS** - Both client and server verify each other  
✅ **Production-ready** - Includes Docker setup and monitoring  
✅ **Multi-language** - Python and Node.js examples included  
✅ **Complete toolkit** - Certificate generation, server setup, and testing  
✅ **Security hardened** - TLS 1.2+, strong ciphers, proper permissions

## 📁 Project Structure

```
.
├── rabbitmq_cert_auth_client.py    # Python client implementation
├── rabbitmq_cert_auth_client.js    # Node.js client implementation
├── generate_certificates.sh         # Certificate generation script
├── server_setup.sh                  # Server configuration script
├── complete_setup.sh                # All-in-one setup script
├── rabbitmq.conf                    # RabbitMQ server configuration
├── docker-compose.yml               # Docker setup for RabbitMQ
├── enabled_plugins                  # Required RabbitMQ plugins
├── requirements.txt                 # Python dependencies
├── package.json                     # Node.js dependencies
├── README_CERTIFICATES.md           # Comprehensive guide
└── COMPARISON.md                    # Authentication methods comparison
```

## 🔧 Requirements

- Docker & Docker Compose (for easy setup)
- OR RabbitMQ 3.x+ installed locally
- OpenSSL (for certificate generation)
- Python 3.7+ (for Python client)
- Node.js 14+ (for Node.js client)

## 💻 Usage Examples

### Python Client

```python
from rabbitmq_cert_auth_client import RabbitMQCertClient

client = RabbitMQCertClient(
    host="localhost",
    port=5671,
    cert_path="./certs/client/cert.pem",
    key_path="./certs/client/key.pem",
    ca_cert_path="./certs/ca/ca_cert.pem"
)

if client.connect():
    client.publish_message('', 'test_queue', 'Hello!')
    client.close()
```

### Node.js Client

```javascript
const RabbitMQCertClient = require('./rabbitmq_cert_auth_client');

const client = new RabbitMQCertClient({
    host: 'localhost',
    port: 5671,
    certPath: './certs/client/cert.pem',
    keyPath: './certs/client/key.pem',
    caCertPath: './certs/ca/ca_cert.pem'
});

await client.connect();
await client.publishMessage('', 'test_queue', 'Hello!');
await client.close();
```

## 🔐 How It Works

Certificate-based authentication (mutual TLS) provides stronger security than passwords:

1. **Client connects** to RabbitMQ SSL port (5671)
2. **Server presents certificate** to prove its identity
3. **Client verifies** server certificate against CA
4. **Client presents certificate** to prove its identity
5. **Server verifies** client certificate against CA
6. **Server extracts username** from certificate CN (Common Name)
7. **Connection established** - no password needed!

## 🛡️ Security Benefits

- **No password transmission** - Eliminates credential theft risk
- **Cryptographic proof** - Both parties verified through certificates
- **Non-repudiation** - Certificate-based identity is verifiable
- **Compliance-ready** - Meets PCI-DSS, HIPAA, SOC 2 requirements
- **Perfect for automation** - Service-to-service auth without secrets

## 📖 Learn More

For detailed information, see:
- [README_CERTIFICATES.md](README_CERTIFICATES.md) - Complete guide with architecture, troubleshooting, and best practices
- [COMPARISON.md](COMPARISON.md) - When to use certificates vs passwords

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional language examples (Java, Go, C#, etc.)
- Kubernetes deployment examples
- Certificate automation (Vault, cert-manager)
- Monitoring and alerting examples

## 📄 License

MIT License - Use freely in your projects!
