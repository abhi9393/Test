#!/bin/bash

###############################################################################
# RabbitMQ Server Setup Script for Certificate-based Authentication
# 
# This script:
# 1. Enables required plugins
# 2. Creates users based on certificate CN
# 3. Sets appropriate permissions
###############################################################################

set -e

echo "=========================================="
echo "RabbitMQ Server Setup for Certificate Auth"
echo "=========================================="

# Configuration
RABBITMQ_HOST="localhost"
CLIENT_CN="client1"  # Must match the CN in client certificate

echo ""
echo "Step 1: Enabling required plugins..."
rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl
rabbitmq-plugins enable rabbitmq_management

echo ""
echo "Step 2: Creating user based on certificate CN..."
# Create user with name matching certificate CN
# Password is empty string - not used for cert auth
rabbitmqctl add_user "$CLIENT_CN" "" || echo "User already exists"

echo ""
echo "Step 3: Setting permissions for user..."
# Grant full permissions on default vhost
rabbitmqctl set_permissions -p / "$CLIENT_CN" ".*" ".*" ".*"

echo ""
echo "Step 4: Setting user tags..."
# Optional: Add tags for management UI access
rabbitmqctl set_user_tags "$CLIENT_CN" monitoring

echo ""
echo "Step 5: Listing users..."
rabbitmqctl list_users

echo ""
echo "Step 6: Listing permissions..."
rabbitmqctl list_permissions -p /

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "User '$CLIENT_CN' has been configured for certificate-based authentication"
echo ""
echo "You can now:"
echo "1. Test connection with: python3 rabbitmq_cert_auth_client.py"
echo "2. Or with Node.js: node rabbitmq_cert_auth_client.js"
echo ""
echo "Management UI: https://localhost:15671"
echo "AMQPS Endpoint: amqps://localhost:5671"
echo "=========================================="
