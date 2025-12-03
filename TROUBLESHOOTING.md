# Troubleshooting Guide

Common issues and their solutions when working with the bastion host testing infrastructure.

## Table of Contents
- [Terraform Issues](#terraform-issues)
- [AWS Credentials Issues](#aws-credentials-issues)
- [SSH Connection Issues](#ssh-connection-issues)
- [GitHub Actions Issues](#github-actions-issues)
- [Network Connectivity Issues](#network-connectivity-issues)
- [Cost and Cleanup Issues](#cost-and-cleanup-issues)

---

## Terraform Issues

### Error: "No valid credential sources found"

**Problem:** Terraform can't find AWS credentials.

**Solution:**
```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Error: "Resource already exists"

**Problem:** Previous resources weren't fully destroyed.

**Solution:**
```bash
# Import existing resources or destroy manually
cd terraform
terraform state list  # See what Terraform thinks exists
terraform destroy -auto-approve  # Force destroy

# If that fails, clean up manually in AWS Console
```

### Error: "Invalid SSH public key format"

**Problem:** SSH key format is incorrect.

**Solution:**
```bash
# Generate a new key pair
./scripts/setup-ssh-keys.sh

# Or use an existing key
cat ~/.ssh/id_rsa.pub  # Copy this into terraform.tfvars
```

### Error: "State lock acquisition failed"

**Problem:** Another process is using the state, or a previous run crashed.

**Solution:**
```bash
# Wait 5 minutes and try again, or force unlock
terraform force-unlock <lock-id>

# Get lock-id from error message
```

### Warning: "Resource ... has an empty state"

**Problem:** Usually harmless, occurs during creation.

**Solution:** No action needed, this is informational.

---

## AWS Credentials Issues

### Error: "AccessDenied" or "UnauthorizedOperation"

**Problem:** IAM user/role lacks necessary permissions.

**Required Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Solution:** Add these permissions to your IAM user/role in AWS Console.

### Error: "InvalidClientTokenId"

**Problem:** Invalid or expired AWS credentials.

**Solution:**
```bash
# Check current credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

---

## SSH Connection Issues

### Error: "Connection timed out"

**Problem:** Instance not ready, security group issue, or wrong IP.

**Solution:**
```bash
# Wait 60-90 seconds after terraform apply
sleep 60

# Verify instance is running
aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-*" \
  --query 'Reservations[].Instances[].State.Name'

# Check security group allows your IP
curl -s https://checkip.amazonaws.com  # Your current IP
# Compare with allowed_ssh_cidr in variables
```

### Error: "Permission denied (publickey)"

**Problem:** Wrong SSH key or permissions issue.

**Solution:**
```bash
# Check key permissions
chmod 600 .ssh/bastion-test-key.pem

# Verify you're using the correct key
terraform output ssh_private_key_path

# Try with verbose SSH
ssh -vvv -i <key-path> ec2-user@<bastion-ip>
```

### Error: "Host key verification failed"

**Problem:** Known_hosts conflict.

**Solution:**
```bash
# Remove old entry
ssh-keygen -R <bastion-ip>

# Or connect with option
ssh -o StrictHostKeyChecking=no -i <key> ec2-user@<bastion-ip>
```

### Can't connect to private instance from bastion

**Problem:** Key not on bastion or security group issue.

**Solution:**
```bash
# Copy key to bastion (if needed manually)
scp -i <key> <key> ec2-user@<bastion-ip>:/tmp/key.pem

# SSH to bastion
ssh -i <key> ec2-user@<bastion-ip>

# From bastion, fix permissions and try
chmod 600 /tmp/key.pem
ssh -i /tmp/key.pem ec2-user@<private-ip>

# Check security groups allow bastion → private
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*private-instance-sg"
```

---

## GitHub Actions Issues

### Error: "AWS credentials not configured"

**Problem:** GitHub Secrets not set correctly.

**Solution:**
1. Go to: Repository → Settings → Secrets and variables → Actions
2. Add/update:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (optional)
3. Re-run workflow

### Error: "terraform command not found"

**Problem:** GitHub Actions cache issue.

**Solution:**
```yaml
# Make sure workflow has:
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: 1.6.0
```

### Workflow runs but tests fail

**Problem:** Network timing or propagation issue.

**Solution:**
```yaml
# Increase wait time in workflow
- name: Wait for Instances
  run: sleep 90  # Increase from 60 to 90 seconds
```

### Error: "Resource ... still exists"

**Problem:** Terraform destroy failed in previous run.

**Solution:**
1. Go to AWS Console
2. Manually delete resources with tag `Project=bastion-cicd-test`
3. Re-run workflow

---

## Network Connectivity Issues

### Can ping but can't SSH to private instance

**Problem:** SSH service not ready or security group issue.

**Solution:**
```bash
# From bastion, check if SSH is listening
ssh -i /tmp/key.pem ec2-user@<private-ip> -v

# Check security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*private-instance-sg" \
  --query 'SecurityGroups[].IpPermissions'
```

### Private instance can't reach internet

**Problem:** No NAT Gateway (by design for security).

**Solution:**
If you need internet access for updates:

```hcl
# Add to terraform/vpc.tf
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Update private route table
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
```

**Note:** NAT Gateway costs ~$0.045/hour + data transfer.

### VPC peering not working

**Problem:** This setup doesn't include VPC peering.

**Solution:** See alternative architectures in ARCHITECTURE.md.

---

## Cost and Cleanup Issues

### Getting unexpected AWS charges

**Problem:** Resources not destroyed after testing.

**Check:**
```bash
# List all EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=bastion-*" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags]'

# List all VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=bastion-*"
```

**Solution:**
```bash
# Destroy with Terraform
cd terraform
terraform destroy -auto-approve

# Or manually in AWS Console:
# EC2 → Instances → Terminate
# VPC → Your VPCs → Delete VPC
```

### Terraform destroy fails with "DependencyViolation"

**Problem:** Resources have dependencies that must be destroyed in order.

**Solution:**
```bash
# Try targeted destroy
terraform destroy -target=aws_instance.bastion
terraform destroy -target=aws_instance.private
terraform destroy  # Now destroy everything else

# If still failing, delete manually:
# 1. EC2 instances
# 2. Security groups
# 3. Subnets
# 4. Route tables
# 5. Internet gateway
# 6. VPC
```

---

## General Debugging Tips

### Enable Terraform Debug Logging

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

### Test Network Connectivity Manually

```bash
# From your machine to bastion
nc -zv <bastion-ip> 22

# From bastion to private instance
# (after SSHing to bastion)
nc -zv <private-ip> 22
ping -c 3 <private-ip>
```

### Check AWS Service Health

Visit: https://status.aws.amazon.com/

Sometimes issues are on AWS's side (rare but possible).

### Verify Region Consistency

```bash
# Check your configured region
aws configure get region

# Check Terraform region
cd terraform
grep region *.tf

# They should match!
```

---

## Still Having Issues?

1. **Check the logs:**
   - GitHub Actions: Full workflow logs in Actions tab
   - Local: Run with `terraform apply` (shows errors)
   - AWS: CloudTrail for API call history

2. **Verify the basics:**
   - AWS credentials valid?
   - Terraform version correct? (`terraform version`)
   - All prerequisites installed?

3. **Ask for help:**
   - Open an issue with:
     - What you tried
     - Full error message
     - Terraform version
     - AWS region
     - Steps to reproduce

4. **Clean slate approach:**
   ```bash
   # Destroy everything
   terraform destroy -auto-approve
   
   # Remove state
   rm -rf .terraform terraform.tfstate*
   
   # Start fresh
   terraform init
   terraform apply
   ```

---

## Quick Reference Commands

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check what Terraform will do
terraform plan

# Apply with auto-approve
terraform apply -auto-approve

# Destroy everything
terraform destroy -auto-approve

# Get outputs
terraform output

# SSH to bastion
ssh -i .ssh/<key>.pem ec2-user@$(terraform output -raw bastion_public_ip)

# Test connectivity
./scripts/test-connectivity.sh
```

---

**Pro Tip:** Most issues are related to timing (instances not ready), permissions (AWS IAM), or networking (security groups). Start troubleshooting there!
