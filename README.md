# 🔐 Bastion Host CI/CD Testing Pipeline

Automated infrastructure testing pipeline that provisions an AWS bastion host and private EC2 instance, validates connectivity, and tears down resources automatically using Terraform and GitHub Actions.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Setup](#local-setup)
- [GitHub Actions Setup](#github-actions-setup)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Cost Considerations](#cost-considerations)

## ✨ Features

- 🚀 Automated infrastructure provisioning with Terraform
- 🧪 Connectivity testing between bastion and private EC2
- 🔄 Complete setup and teardown in CI/CD pipeline
- 🛡️ Security best practices: private subnets, security groups, key management
- 📊 Infrastructure validation and health checks
- 💰 Zero standing costs - resources destroyed after tests

## 🏗️ Architecture

```
Internet Gateway
       |
   [Public Subnet]
       |
  Bastion Host (Public IP)
       |
   [Private Subnet]
       |
   Private EC2 Instance
```

The bastion host acts as a jump server to access the private EC2 instance that has no direct internet access.

## 📦 Prerequisites

### For Local Testing

- AWS Account with appropriate permissions
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- AWS CLI configured with credentials
- SSH client

### For GitHub Actions

- GitHub repository
- AWS credentials configured as GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (optional, defaults to us-east-1)

## 🚀 Local Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd bastion-cicd-test
   ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   ```

3. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

4. **Review and apply the infrastructure**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Run connectivity tests**
   ```bash
   cd ../scripts
   ./test-connectivity.sh
   ```

6. **Destroy infrastructure**
   ```bash
   cd ../terraform
   terraform destroy
   ```

## 🔧 GitHub Actions Setup

1. **Add AWS credentials to GitHub Secrets**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_REGION` (optional)

2. **Push to trigger the workflow**
   ```bash
   git push origin main
   ```

3. **Monitor the workflow**
   - Go to Actions tab in your GitHub repository
   - Watch the pipeline provision, test, and destroy infrastructure

## 📖 Usage

### Automatic (CI/CD)

The pipeline automatically runs on:
- Push to `main` branch
- Pull requests
- Manual workflow dispatch

### Manual Testing

```bash
# Provision infrastructure
cd terraform
terraform apply -auto-approve

# Test connectivity
cd ../scripts
./test-connectivity.sh

# Clean up
cd ../terraform
terraform destroy -auto-approve
```

## 📁 Project Structure

```
bastion-cicd-test/
├── .github/
│   └── workflows/
│       └── test-infrastructure.yml    # GitHub Actions workflow
├── terraform/
│   ├── main.tf                        # Main Terraform configuration
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output values
│   ├── vpc.tf                         # VPC and networking
│   ├── security-groups.tf             # Security group rules
│   ├── ec2.tf                         # EC2 instances
│   └── terraform.tfvars.example       # Example variables file
├── scripts/
│   ├── test-connectivity.sh           # Connectivity testing script
│   └── setup-ssh-keys.sh              # SSH key setup helper
└── README.md
```

## 💰 Cost Considerations

**Running costs during tests:**
- 2x t2.micro instances: ~$0.0116/hour each
- VPC, Internet Gateway, Subnets: Free
- **Total: ~$0.023/hour** (~$0.02 per test run)

**Pipeline runs:**
- Average test duration: 5-10 minutes
- Cost per test: < $0.01

Since resources are destroyed after each test, there are **no standing costs**.

## 🔒 Security Best Practices

- Bastion host in public subnet with restricted SSH access (configurable CIDR)
- Private EC2 instance with no direct internet access
- Security groups with minimal required permissions
- SSH keys managed securely (not committed to repo)
- Automated cleanup prevents orphaned resources

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License - feel free to use this project for learning and testing purposes.

## 🙏 Acknowledgments

Built for learning and testing bastion host patterns in AWS with infrastructure as code best practices.
