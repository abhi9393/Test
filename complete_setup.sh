#!/bin/bash

###############################################################################
# Complete Setup Script for RabbitMQ Certificate Authentication
# 
# This script automates the entire setup process:
# 1. Generate certificates
# 2. Start RabbitMQ with Docker
# 3. Wait for RabbitMQ to be ready
# 4. Configure users and permissions
# 5. Test the connection
###############################################################################

set -e

echo "=========================================="
echo "Complete RabbitMQ Certificate Auth Setup"
echo "=========================================="

# Step 1: Generate certificates
echo ""
echo "Step 1: Generating certificates..."
if [ ! -d "certs" ]; then
    ./generate_certificates.sh
else
    echo "⚠ Certificates already exist. Skipping generation."
    echo "To regenerate, delete the 'certs' directory and run this script again."
fi

# Step 2: Update rabbitmq.conf with correct paths
echo ""
echo "Step 2: Updating RabbitMQ configuration..."
sed -i.bak 's|/path/to/certs|/etc/rabbitmq/certs|g' rabbitmq.conf
echo "✓ Configuration updated"

# Step 3: Start RabbitMQ with Docker
echo ""
echo "Step 3: Starting RabbitMQ with Docker..."
docker-compose down 2>/dev/null || true
docker-compose up -d

# Step 4: Wait for RabbitMQ to be ready
echo ""
echo "Step 4: Waiting for RabbitMQ to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec rabbitmq-ssl rabbitmqctl status >/dev/null 2>&1; then
        echo "✓ RabbitMQ is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "✗ RabbitMQ failed to start within expected time"
    echo "Check logs with: docker logs rabbitmq-ssl"
    exit 1
fi

# Give it a few more seconds for plugins to initialize
sleep 5

# Step 5: Configure users and permissions
echo ""
echo "Step 5: Configuring users and permissions..."

CLIENT_CN="client1"

# Create user (matching certificate CN)
docker exec rabbitmq-ssl rabbitmqctl add_user "$CLIENT_CN" "" 2>/dev/null || \
    echo "User $CLIENT_CN already exists"

# Set permissions
docker exec rabbitmq-ssl rabbitmqctl set_permissions -p / "$CLIENT_CN" ".*" ".*" ".*"

# Set user tags
docker exec rabbitmq-ssl rabbitmqctl set_user_tags "$CLIENT_CN" monitoring

echo "✓ User configuration complete"

# Step 6: Display status
echo ""
echo "Step 6: Verifying setup..."
echo ""
echo "Users:"
docker exec rabbitmq-ssl rabbitmqctl list_users

echo ""
echo "Permissions:"
docker exec rabbitmq-ssl rabbitmqctl list_permissions -p /

echo ""
echo "Listeners:"
docker exec rabbitmq-ssl rabbitmq-diagnostics listeners

# Step 7: Test connection (if Python is available)
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "RabbitMQ is running with certificate authentication enabled"
echo ""
echo "Connection details:"
echo "  - AMQPS: amqps://localhost:5671"
echo "  - Management UI: http://localhost:15672 (admin/admin)"
echo "  - Management HTTPS: https://localhost:15671 (admin/admin)"
echo ""
echo "Client certificate:"
echo "  - Certificate: ./certs/client/cert.pem"
echo "  - Key: ./certs/client/key.pem"
echo "  - CA: ./certs/ca/ca_cert.pem"
echo "  - CN: $CLIENT_CN"
echo ""
echo "Next steps:"
echo "  1. Test Python client: python3 rabbitmq_cert_auth_client.py"
echo "  2. Test Node.js client: npm install && node rabbitmq_cert_auth_client.js"
echo ""
echo "To stop RabbitMQ:"
echo "  docker-compose down"
echo ""
echo "To view logs:"
echo "  docker logs -f rabbitmq-ssl"
echo "=========================================="
