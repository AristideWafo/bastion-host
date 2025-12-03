# Quick Start Guide

This guide will help you get the bastion host testing infrastructure up and running in minutes.

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Git installed

## Quick Setup (5 minutes)

### Option 1: Using GitHub Actions (Recommended for CI/CD)

1. **Fork/Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd bastion-cicd-test
   ```

2. **Configure GitHub Secrets**
   
   Go to: Repository → Settings → Secrets and variables → Actions
   
   Add these secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: (optional) defaults to us-east-1

3. **Push to trigger the pipeline**
   ```bash
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

4. **Watch it work!**
   
   Go to the "Actions" tab in your GitHub repository and watch the pipeline:
   - Provision infrastructure
   - Run connectivity tests
   - Destroy everything automatically

### Option 2: Local Testing

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd bastion-cicd-test
   ```

2. **Generate SSH keys**
   ```bash
   ./scripts/setup-ssh-keys.sh
   ```

3. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

4. **Apply infrastructure**
   ```bash
   terraform apply -auto-approve
   ```
   
   This will take about 2-3 minutes.

5. **Run connectivity tests**
   ```bash
   cd ..
   ./scripts/test-connectivity.sh
   ```

6. **Clean up**
   ```bash
   cd terraform
   terraform destroy -auto-approve
   ```

## What Gets Created?

When you run the infrastructure, Terraform creates:

- **1 VPC** with public and private subnets
- **1 Internet Gateway** for public subnet connectivity
- **1 Bastion Host** (t2.micro) in the public subnet
- **1 Private EC2 Instance** (t2.micro) in the private subnet
- **2 Security Groups** with minimal required permissions
- **1 SSH Key Pair** (auto-generated if not provided)

## Testing Scenarios

The automated tests verify:

1. ✅ SSH connectivity to bastion host from internet
2. ✅ ICMP (ping) from bastion to private instance
3. ✅ SSH from bastion to private instance
4. ✅ Private instance has no public IP
5. ✅ Security group configurations are correct

## Cost Estimation

**Per test run (5-10 minutes):**
- 2x t2.micro instances: ~$0.0232/hour
- VPC, subnets, IGW: Free
- **Total cost per run: < $0.01**

Since resources are destroyed after tests, there are **no standing costs**.

## Troubleshooting

### "Access Denied" errors

Make sure your AWS credentials have these permissions:
- EC2 (full access or specific actions)
- VPC (full access or specific actions)

### "Connection timeout" during tests

This is usually due to:
- Instances not fully initialized (wait 60 seconds)
- Security group rules not applied yet
- AWS region issues

### Terraform state lock errors

If running locally, only one person can apply at a time. For teams, consider using:
- Terraform Cloud
- S3 backend with DynamoDB locking

## Next Steps

- Customize the infrastructure in `terraform/*.tf` files
- Modify security group rules in `terraform/security-groups.tf`
- Add more tests in `scripts/test-connectivity.sh`
- Integrate with your existing CI/CD pipeline

## Getting Help

- Check the main [README.md](README.md) for detailed documentation
- Review Terraform configuration files in `terraform/`
- Open an issue if you encounter problems

## Security Reminders

⚠️ **Important Security Notes:**

- The default configuration allows SSH from `0.0.0.0/0` - **restrict this in production!**
- SSH keys are auto-generated and stored locally - **never commit them to git**
- This is a testing/learning project - **add proper monitoring for production use**
- Always destroy resources after testing to avoid unnecessary costs

---

Happy testing! 🚀
