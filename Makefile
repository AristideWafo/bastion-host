.PHONY: help init validate plan apply test destroy clean setup-keys

# Default target
help:
	@echo "Bastion Host CI/CD Test - Available Commands"
	@echo "=============================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup-keys    - Generate SSH keys for testing"
	@echo "  make init          - Initialize Terraform"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  make validate      - Validate Terraform configuration"
	@echo "  make plan          - Show Terraform execution plan"
	@echo "  make apply         - Deploy infrastructure"
	@echo "  make test          - Run connectivity tests"
	@echo "  make destroy       - Destroy infrastructure"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean         - Clean up local files"
	@echo "  make outputs       - Show Terraform outputs"
	@echo "  make ssh-bastion   - SSH into bastion host"
	@echo ""
	@echo "Quick Commands:"
	@echo "  make all           - Run complete workflow (init → apply → test)"
	@echo "  make quick-test    - Quick test without full deployment"
	@echo ""

# Setup SSH keys
setup-keys:
	@echo "Setting up SSH keys..."
	./scripts/setup-ssh-keys.sh

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	cd terraform && terraform validate

# Show Terraform plan
plan:
	@echo "Generating Terraform plan..."
	cd terraform && terraform plan

# Apply Terraform configuration
apply:
	@echo "Applying Terraform configuration..."
	@echo "This will create AWS resources and may incur costs."
	cd terraform && terraform apply
	@echo ""
	@echo "✅ Infrastructure deployed! Wait 60 seconds before testing."
	@echo "Run 'make test' to verify connectivity."

# Run connectivity tests
test:
	@echo "Running connectivity tests..."
	./scripts/test-connectivity.sh

# Destroy infrastructure
destroy:
	@echo "Destroying infrastructure..."
	cd terraform && terraform destroy

# Show outputs
outputs:
	@echo "Terraform outputs:"
	cd terraform && terraform output

# SSH to bastion
ssh-bastion:
	@echo "Connecting to bastion host..."
	@BASTION_IP=$$(cd terraform && terraform output -raw bastion_public_ip 2>/dev/null); \
	KEY_PATH=$$(cd terraform && terraform output -raw ssh_private_key_path 2>/dev/null); \
	if [ -z "$$BASTION_IP" ]; then \
		echo "Error: No infrastructure deployed. Run 'make apply' first."; \
		exit 1; \
	fi; \
	ssh -i $$KEY_PATH ec2-user@$$BASTION_IP

# Clean up local files
clean:
	@echo "Cleaning up local files..."
	cd terraform && rm -rf .terraform terraform.tfstate* .terraform.lock.hcl
	rm -f outputs.txt
	@echo "✅ Cleanup complete"

# Complete workflow
all: init validate apply
	@echo ""
	@echo "Waiting 60 seconds for instances to initialize..."
	@sleep 60
	@$(MAKE) test

# Quick test (assumes infrastructure exists)
quick-test:
	@echo "Running quick connectivity test..."
	@if [ ! -f terraform/terraform.tfstate ]; then \
		echo "Error: No infrastructure found. Run 'make apply' first."; \
		exit 1; \
	fi
	@$(MAKE) test
