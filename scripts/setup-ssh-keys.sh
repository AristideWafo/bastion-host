#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "SSH Key Setup Helper"
echo "========================================="
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSH_DIR="$PROJECT_ROOT/.ssh"

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

KEY_NAME="bastion-test-key"
KEY_PATH="$SSH_DIR/$KEY_NAME"

if [ -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}SSH key already exists at $KEY_PATH${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing key."
        exit 0
    fi
fi

echo "Generating new SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "bastion-test@local"

# Set proper permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

echo ""
echo -e "${GREEN}✓ SSH key pair generated successfully!${NC}"
echo ""
echo "Private key: $KEY_PATH"
echo "Public key:  $KEY_PATH.pub"
echo ""
echo "To use this key with Terraform, either:"
echo ""
echo "1. Set it in terraform.tfvars:"
echo "   ssh_public_key = \"$(cat "$KEY_PATH.pub")\""
echo ""
echo "2. Or pass it as a variable:"
echo "   terraform apply -var=\"ssh_public_key=\$(cat $KEY_PATH.pub)\""
echo ""
echo "The key is stored in the .ssh/ directory which is git-ignored for security."
echo ""
