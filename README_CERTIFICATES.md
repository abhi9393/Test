# RabbitMQ Certificate-based Authentication

This project demonstrates how to implement **mutual TLS (mTLS)** authentication for RabbitMQ, where clients authenticate using SSL/TLS certificates instead of username/password credentials.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Client Implementation](#client-implementation)
- [Server Configuration](#server-configuration)
- [Certificate Management](#certificate-management)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

## 🔍 Overview

### What is Certificate-based Authentication?

Certificate-based authentication (also known as mutual TLS or mTLS) is a security mechanism where:

1. **Server authenticates to client**: The RabbitMQ server presents its certificate to prove its identity
2. **Client authenticates to server**: The client presents its certificate to prove its identity
3. **No passwords needed**: Authentication is based on cryptographic certificates signed by a trusted Certificate Authority (CA)

### Benefits

- ✅ **Stronger security**: No password transmission over the network
- ✅ **Non-repudiation**: Certificate-based identity is cryptographically verifiable
- ✅ **Automated systems**: Perfect for service-to-service communication
- ✅ **Centralized management**: CA-based certificate lifecycle management
- ✅ **Compliance**: Meets strict security requirements for regulated industries

## 🏗️ Architecture

```
┌─────────────────┐                    ┌──────────────────┐
│                 │   1. TLS Handshake │                  │
│   RabbitMQ      │◄──────────────────►│   Client         │
│   Server        │   2. Verify Certs  │   Application    │
│                 │   3. Authenticate  │                  │
└────────┬────────┘   4. Exchange Data └────────┬─────────┘
         │                                       │
         │                                       │
    ┌────▼─────────────────────────────────────▼────┐
    │                                                │
    │         Certificate Authority (CA)             │
    │  (Signs both server and client certificates)   │
    │                                                │
    └────────────────────────────────────────────────┘
```

### Authentication Flow

1. **Client initiates connection** to RabbitMQ SSL port (5671)
2. **Server presents certificate** signed by CA
3. **Client verifies server certificate** against CA cert
4. **Client presents certificate** to server
5. **Server verifies client certificate** against CA cert
6. **Server extracts identity** from client cert (Common Name or DN)
7. **Server checks permissions** for the extracted identity
8. **Connection established** - no password needed!

## 🚀 Quick Start

### 1. Generate Certificates

```bash
chmod +x generate_certificates.sh
./generate_certificates.sh
```

This creates:
- `certs/ca/` - Certificate Authority files
- `certs/server/` - Server certificate and key
- `certs/client/` - Client certificate and key

### 2. Start RabbitMQ Server

Using Docker:

```bash
# Update paths in rabbitmq.conf to absolute paths
sed -i 's|/path/to/certs|/etc/rabbitmq/certs|g' rabbitmq.conf

# Start RabbitMQ with SSL configuration
docker-compose up -d
```

Or manual installation:

```bash
# Copy certificates to RabbitMQ config directory
sudo cp -r certs /etc/rabbitmq/
sudo cp rabbitmq.conf /etc/rabbitmq/
sudo cp enabled_plugins /etc/rabbitmq/

# Restart RabbitMQ
sudo systemctl restart rabbitmq-server
```

### 3. Configure Server

```bash
chmod +x server_setup.sh
./server_setup.sh
```

### 4. Run Client

Python:

```bash
pip install -r requirements.txt
python3 rabbitmq_cert_auth_client.py
```

Node.js:

```bash
npm install
node rabbitmq_cert_auth_client.js
```

## 💻 Client Implementation

### Python Client

Key features of the Python implementation:

```python
# Create SSL context
context = ssl.create_default_context(cafile=ca_cert_path)
context.load_cert_chain(certfile=cert_path, keyfile=key_path)

# Use ExternalCredentials (no username/password!)
credentials = pika.credentials.ExternalCredentials()

# SSL options
ssl_options = pika.SSLOptions(context, host)

# Connect
parameters = pika.ConnectionParameters(
    host=host,
    port=5671,
    credentials=credentials,
    ssl_options=ssl_options
)
```

### Node.js Client

Key features of the Node.js implementation:

```javascript
// SSL options
const sslOptions = {
    cert: fs.readFileSync(certPath),
    key: fs.readFileSync(keyPath),
    ca: [fs.readFileSync(caCertPath)],
    rejectUnauthorized: true
};

// Connect (no username/password in URL!)
const connection = await amqp.connect(
    `amqps://${host}:5671`,
    sslOptions
);
```

### Other Languages

The same principle applies to any language:

1. **Load certificates**: CA cert, client cert, client key
2. **Create SSL/TLS context** with mutual authentication
3. **Connect to AMQPS port** (5671)
4. **Use EXTERNAL authentication** mechanism
5. **No username/password** required!

Examples for other languages:

**Java (Spring AMQP)**:
```java
ConnectionFactory factory = new ConnectionFactory();
factory.useSslProtocol(sslContext);
factory.setHost("localhost");
factory.setPort(5671);
// Certificate CN is used as username automatically
```

**Go**:
```go
cert, _ := tls.LoadX509KeyPair("client/cert.pem", "client/key.pem")
tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{cert},
    RootCAs:      caCertPool,
}
conn, _ := amqp.DialTLS("amqps://localhost:5671/", tlsConfig)
```

**C# (.NET)**:
```csharp
var factory = new ConnectionFactory() {
    HostName = "localhost",
    Port = 5671,
    Ssl = new SslOption {
        Enabled = true,
        ServerName = "localhost",
        CertPath = "client/cert.pfx",
        CertPassphrase = ""
    }
};
```

## 🔧 Server Configuration

### Required RabbitMQ Plugins

```bash
rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl
rabbitmq-plugins enable rabbitmq_management
```

### Key Configuration Options

**rabbitmq.conf**:

```ini
# Enable SSL listener
listeners.ssl.default = 5671

# Server certificates
ssl_options.certfile = /path/to/server/cert.pem
ssl_options.keyfile  = /path/to/server/key.pem
ssl_options.cacertfile = /path/to/ca/ca_cert.pem

# Require client certificates
ssl_options.verify = verify_peer
ssl_options.fail_if_no_peer_cert = true

# Use EXTERNAL authentication mechanism
auth_mechanisms.1 = EXTERNAL

# Extract username from certificate CN
ssl_cert_login_from = common_name
```

### User Setup

The username in RabbitMQ must match the certificate CN:

```bash
# Certificate CN = "client1"
# Create RabbitMQ user "client1"
rabbitmqctl add_user client1 ""

# Grant permissions
rabbitmqctl set_permissions -p / client1 ".*" ".*" ".*"
```

### Identity Extraction Options

RabbitMQ can extract identity from different certificate fields:

| Option | Example | Use Case |
|--------|---------|----------|
| `common_name` | `client1` | Simple, human-readable names |
| `distinguished_name` | `CN=client1,O=Org,C=US` | Full DN for complex hierarchies |
| `subject_alternative_name` | `email@example.com` | Email-based identification |

## 🔐 Certificate Management

### Certificate Structure

```
certs/
├── ca/
│   ├── ca_cert.pem      # CA certificate (distribute to all)
│   └── ca_key.pem       # CA private key (KEEP SECURE!)
├── server/
│   ├── cert.pem         # Server certificate
│   ├── key.pem          # Server private key
│   └── csr.pem          # Certificate signing request
└── client/
    ├── cert.pem         # Client certificate
    ├── key.pem          # Client private key
    └── csr.pem          # Certificate signing request
```

### Certificate Attributes

When generating certificates, key attributes are:

- **CN (Common Name)**: Used as RabbitMQ username
  - Server: Should be hostname/FQDN
  - Client: Should be service/user identifier
- **O (Organization)**: Your organization name
- **OU (Organizational Unit)**: Department/team (optional)
- **C (Country)**: Two-letter country code
- **Validity**: Typically 1-2 years for production

### Certificate Rotation

1. **Generate new certificates** with the same CN
2. **Deploy new certificate** to client
3. **Update client configuration** to use new cert
4. **Restart client** application
5. **Revoke old certificate** if using CRL/OCSP

### Production Considerations

For production environments:

1. **Use a proper CA**: Consider using HashiCorp Vault, AWS ACM, or your organization's PKI
2. **Implement certificate rotation**: Automate renewal before expiry
3. **Use CRL or OCSP**: Enable certificate revocation checking
4. **Monitor certificate expiry**: Set up alerts for expiring certificates
5. **Secure private keys**: Use HSM or key management service
6. **Separate CAs**: Use different CAs for different environments

## 🛡️ Security Best Practices

### 1. Certificate Security

- ✅ **Never commit private keys** to version control
- ✅ **Use strong key sizes**: Minimum 2048-bit RSA or 256-bit ECC
- ✅ **Limit certificate validity**: 1-2 years maximum
- ✅ **Implement certificate rotation**: Before expiry
- ✅ **Use file permissions**: 600 for private keys, 644 for certificates

### 2. TLS Configuration

- ✅ **Use TLS 1.2 or higher**: Disable older protocols
- ✅ **Strong cipher suites only**: Avoid weak ciphers
- ✅ **Enable hostname verification**: In production
- ✅ **Verify certificate chain**: Always verify against CA

### 3. Access Control

- ✅ **Principle of least privilege**: Grant minimum required permissions
- ✅ **Use virtual hosts**: Separate environments
- ✅ **Audit access**: Log certificate-based connections
- ✅ **Regular review**: Audit user permissions periodically

### 4. Monitoring

- ✅ **Track certificate expiry**: Automated alerts
- ✅ **Monitor failed authentications**: Detect attacks
- ✅ **Log certificate usage**: Audit trail
- ✅ **Health checks**: Verify SSL listener status

## 🔍 Troubleshooting

### Common Issues

#### 1. Connection Refused

```
Error: Connection refused on port 5671
```

**Solutions**:
- Verify RabbitMQ is running: `sudo systemctl status rabbitmq-server`
- Check SSL listener is enabled: `sudo rabbitmq-diagnostics listeners`
- Verify port is not blocked: `telnet localhost 5671`

#### 2. Certificate Verification Failed

```
Error: certificate verify failed
```

**Solutions**:
- Ensure CA certificate matches the one that signed server/client certs
- Check certificate expiry: `openssl x509 -in cert.pem -noout -dates`
- Verify certificate chain: `openssl verify -CAfile ca_cert.pem cert.pem`

#### 3. Authentication Failed

```
Error: ACCESS_REFUSED - Login was refused
```

**Solutions**:
- Check user exists with correct CN: `rabbitmqctl list_users`
- Verify permissions: `rabbitmqctl list_permissions -p /`
- Check `ssl_cert_login_from` setting matches certificate field
- Ensure `rabbitmq_auth_mechanism_ssl` plugin is enabled

#### 4. No Peer Certificate

```
Error: no peer certificate available
```

**Solutions**:
- Verify `ssl_options.fail_if_no_peer_cert = true` in config
- Check client is sending certificate
- Ensure client certificate is signed by trusted CA

### Debug Commands

```bash
# Check RabbitMQ status
sudo rabbitmqctl status

# List enabled plugins
sudo rabbitmq-plugins list

# Check listeners
sudo rabbitmq-diagnostics listeners

# View certificate details
openssl x509 -in cert.pem -text -noout

# Test SSL connection
openssl s_client -connect localhost:5671 \
  -cert client/cert.pem \
  -key client/key.pem \
  -CAfile ca/ca_cert.pem

# View RabbitMQ logs
sudo tail -f /var/log/rabbitmq/rabbit@*.log
```

### Enable Debug Logging

Add to `rabbitmq.conf`:

```ini
log.connection.level = debug
log.channel.level = debug
```

## 📚 Additional Resources

### Official Documentation

- [RabbitMQ SSL Documentation](https://www.rabbitmq.com/ssl.html)
- [RabbitMQ Authentication Mechanisms](https://www.rabbitmq.com/authentication.html)
- [RabbitMQ Access Control](https://www.rabbitmq.com/access-control.html)

### Standards

- [RFC 5246 - TLS 1.2](https://tools.ietf.org/html/rfc5246)
- [RFC 8446 - TLS 1.3](https://tools.ietf.org/html/rfc8446)
- [RFC 5280 - X.509 Certificates](https://tools.ietf.org/html/rfc5280)

## 🤝 Contributing

Improvements and suggestions are welcome! Consider:

- Additional language examples
- Production deployment guides
- Certificate management automation
- Monitoring and alerting examples

## 📄 License

MIT License - feel free to use in your projects!

---

**Note**: This is a reference implementation for learning and development. For production use, consult with your security team and adapt to your organization's specific requirements.
