#!/bin/bash

###############################################################################
# Certificate Generation Script for RabbitMQ Mutual TLS Authentication
# 
# This script generates:
# - CA (Certificate Authority) certificate
# - Server certificate (for RabbitMQ broker)
# - Client certificate (for client authentication)
###############################################################################

set -e

echo "=========================================="
echo "RabbitMQ Certificate Generation Script"
echo "=========================================="

# Configuration
CERTS_DIR="./certs"
CA_DIR="$CERTS_DIR/ca"
SERVER_DIR="$CERTS_DIR/server"
CLIENT_DIR="$CERTS_DIR/client"

# Certificate parameters
COUNTRY="US"
STATE="California"
CITY="San Francisco"
ORGANIZATION="MyOrganization"
COMMON_NAME_CA="RabbitMQ CA"
COMMON_NAME_SERVER="localhost"  # Change to your RabbitMQ server hostname
COMMON_NAME_CLIENT="client1"
VALIDITY_DAYS=365

# Create directory structure
echo "Creating certificate directories..."
mkdir -p "$CA_DIR" "$SERVER_DIR" "$CLIENT_DIR"

###############################################################################
# Step 1: Generate CA (Certificate Authority)
###############################################################################
echo ""
echo "Step 1: Generating Certificate Authority (CA)..."

# Generate CA private key
openssl genrsa -out "$CA_DIR/ca_key.pem" 4096

# Generate CA certificate
openssl req -new -x509 \
    -key "$CA_DIR/ca_key.pem" \
    -out "$CA_DIR/ca_cert.pem" \
    -days $VALIDITY_DAYS \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/CN=$COMMON_NAME_CA"

echo "✓ CA certificate generated: $CA_DIR/ca_cert.pem"

###############################################################################
# Step 2: Generate Server Certificate (for RabbitMQ broker)
###############################################################################
echo ""
echo "Step 2: Generating Server certificate..."

# Generate server private key
openssl genrsa -out "$SERVER_DIR/key.pem" 4096

# Generate server certificate signing request (CSR)
openssl req -new \
    -key "$SERVER_DIR/key.pem" \
    -out "$SERVER_DIR/csr.pem" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/CN=$COMMON_NAME_SERVER"

# Sign server certificate with CA
openssl x509 -req \
    -in "$SERVER_DIR/csr.pem" \
    -CA "$CA_DIR/ca_cert.pem" \
    -CAkey "$CA_DIR/ca_key.pem" \
    -CAcreateserial \
    -out "$SERVER_DIR/cert.pem" \
    -days $VALIDITY_DAYS

echo "✓ Server certificate generated: $SERVER_DIR/cert.pem"

###############################################################################
# Step 3: Generate Client Certificate
###############################################################################
echo ""
echo "Step 3: Generating Client certificate..."

# Generate client private key
openssl genrsa -out "$CLIENT_DIR/key.pem" 4096

# Generate client certificate signing request (CSR)
openssl req -new \
    -key "$CLIENT_DIR/key.pem" \
    -out "$CLIENT_DIR/csr.pem" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/CN=$COMMON_NAME_CLIENT"

# Sign client certificate with CA
openssl x509 -req \
    -in "$CLIENT_DIR/csr.pem" \
    -CA "$CA_DIR/ca_cert.pem" \
    -CAkey "$CA_DIR/ca_key.pem" \
    -CAcreateserial \
    -out "$CLIENT_DIR/cert.pem" \
    -days $VALIDITY_DAYS

echo "✓ Client certificate generated: $CLIENT_DIR/cert.pem"

###############################################################################
# Step 4: Set appropriate permissions
###############################################################################
echo ""
echo "Step 4: Setting file permissions..."

chmod 600 "$CA_DIR/ca_key.pem"
chmod 644 "$CA_DIR/ca_cert.pem"
chmod 600 "$SERVER_DIR/key.pem"
chmod 644 "$SERVER_DIR/cert.pem"
chmod 600 "$CLIENT_DIR/key.pem"
chmod 644 "$CLIENT_DIR/cert.pem"

echo "✓ Permissions set"

###############################################################################
# Step 5: Verify certificates
###############################################################################
echo ""
echo "Step 5: Verifying certificates..."

echo "Verifying server certificate..."
openssl verify -CAfile "$CA_DIR/ca_cert.pem" "$SERVER_DIR/cert.pem"

echo "Verifying client certificate..."
openssl verify -CAfile "$CA_DIR/ca_cert.pem" "$CLIENT_DIR/cert.pem"

###############################################################################
# Summary
###############################################################################
echo ""
echo "=========================================="
echo "Certificate Generation Complete!"
echo "=========================================="
echo ""
echo "Generated certificates:"
echo "  CA Certificate:     $CA_DIR/ca_cert.pem"
echo "  CA Key:             $CA_DIR/ca_key.pem"
echo "  Server Certificate: $SERVER_DIR/cert.pem"
echo "  Server Key:         $SERVER_DIR/key.pem"
echo "  Client Certificate: $CLIENT_DIR/cert.pem"
echo "  Client Key:         $CLIENT_DIR/key.pem"
echo ""
echo "Next steps:"
echo "1. Copy server certificate and key to RabbitMQ server"
echo "2. Configure RabbitMQ to use these certificates (see rabbitmq.conf)"
echo "3. Use client certificate and key in your application"
echo ""
echo "⚠ IMPORTANT: Keep private keys secure and never commit them to version control!"
echo "=========================================="
