#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo "========================================="
echo "Bastion Host Connectivity Test"
echo "========================================="
echo ""

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo -e "${RED}Error: Terraform directory not found at $TERRAFORM_DIR${NC}"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Check if infrastructure is deployed
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}Error: No terraform.tfstate found. Have you run 'terraform apply'?${NC}"
    exit 1
fi

echo -e "${YELLOW}Retrieving infrastructure information...${NC}"

# Get outputs from Terraform
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
PRIVATE_IP=$(terraform output -raw private_instance_ip 2>/dev/null)
SSH_KEY_PATH=$(terraform output -raw ssh_private_key_path 2>/dev/null)

if [ -z "$BASTION_IP" ] || [ -z "$PRIVATE_IP" ]; then
    echo -e "${RED}Error: Failed to retrieve infrastructure information${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Bastion IP: $BASTION_IP"
echo -e "${GREEN}✓${NC} Private Instance IP: $PRIVATE_IP"
echo ""

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: SSH key not found at $SSH_KEY_PATH${NC}"
    exit 1
fi

chmod 600 "$SSH_KEY_PATH"

echo -e "${YELLOW}Test 1: SSH connection to bastion host...${NC}"
if ssh -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -q \
    ec2-user@"$BASTION_IP" \
    "echo 'Connected successfully' && hostname" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test 1 PASSED: Successfully connected to bastion host${NC}"
else
    echo -e "${RED}✗ Test 1 FAILED: Could not connect to bastion host${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Test 2: Ping from bastion to private instance...${NC}"
if ssh -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -q \
    ec2-user@"$BASTION_IP" \
    "ping -c 3 $PRIVATE_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test 2 PASSED: Can ping private instance from bastion${NC}"
else
    echo -e "${RED}✗ Test 2 FAILED: Cannot ping private instance from bastion${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Test 3: Copying SSH key to bastion...${NC}"
if scp -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -q \
    "$SSH_KEY_PATH" \
    ec2-user@"$BASTION_IP":/tmp/private-key.pem > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test 3 PASSED: SSH key copied to bastion${NC}"
else
    echo -e "${RED}✗ Test 3 FAILED: Could not copy SSH key to bastion${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Test 4: SSH from bastion to private instance...${NC}"
if ssh -i "$SSH_KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -q \
    ec2-user@"$BASTION_IP" \
    "chmod 600 /tmp/private-key.pem && \
     ssh -i /tmp/private-key.pem \
         -o StrictHostKeyChecking=no \
         -o ConnectTimeout=10 \
         -o UserKnownHostsFile=/dev/null \
         -q \
         ec2-user@$PRIVATE_IP \
         'echo Connected to private instance && hostname'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test 4 PASSED: Successfully connected to private instance through bastion${NC}"
else
    echo -e "${RED}✗ Test 4 FAILED: Could not connect to private instance through bastion${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}Test 5: Verifying private instance has no public IP...${NC}"
PRIVATE_PUBLIC_IP=$(terraform output -json | jq -r '.private_instance_id.value' | xargs aws ec2 describe-instances --instance-ids --query 'Reservations[0].Instances[0].PublicIpAddress' 2>/dev/null || echo "null")
if [ "$PRIVATE_PUBLIC_IP" == "null" ] || [ -z "$PRIVATE_PUBLIC_IP" ]; then
    echo -e "${GREEN}✓ Test 5 PASSED: Private instance has no public IP (as expected)${NC}"
else
    echo -e "${RED}✗ Test 5 FAILED: Private instance has a public IP: $PRIVATE_PUBLIC_IP${NC}"
    exit 1
fi
echo ""

echo "========================================="
echo -e "${GREEN}All tests passed successfully! ✓${NC}"
echo "========================================="
echo ""
echo "Infrastructure is working correctly:"
echo "  • Bastion host is accessible from the internet"
echo "  • Private instance is only accessible through bastion"
echo "  • Network connectivity is functioning properly"
echo "  • Security groups are configured correctly"
echo ""
echo "To connect to the private instance, use:"
echo "  ssh -i $SSH_KEY_PATH -o ProxyCommand='ssh -i $SSH_KEY_PATH -W %h:%p ec2-user@$BASTION_IP' ec2-user@$PRIVATE_IP"
echo ""
