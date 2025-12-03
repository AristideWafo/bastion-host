# Deployment Checklist

Use this checklist to ensure smooth deployment of the bastion host testing infrastructure.

## Pre-Deployment Checklist

### AWS Prerequisites
- [ ] AWS account created and active
- [ ] IAM user created with programmatic access
- [ ] IAM permissions configured (EC2, VPC full access)
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws configure`)
- [ ] Default region set (e.g., us-east-1)
- [ ] Test credentials: `aws sts get-caller-identity`

### Local Development Prerequisites
- [ ] Git installed (`git --version`)
- [ ] Terraform installed >= 1.0 (`terraform version`)
- [ ] SSH client available (`ssh -V`)
- [ ] Bash shell available (Linux/macOS/WSL)

### Repository Setup
- [ ] Repository cloned locally
- [ ] `.gitignore` in place (prevents committing secrets)
- [ ] SSH keys directory created (`.ssh/`)
- [ ] Scripts have execute permissions (`chmod +x scripts/*.sh`)

## Local Deployment Checklist

### Setup Phase
- [ ] Navigate to project directory
- [ ] Generate SSH keys: `./scripts/setup-ssh-keys.sh`
- [ ] Review `terraform/terraform.tfvars.example`
- [ ] Create `terraform/terraform.tfvars` if customizing
- [ ] Review security settings (especially `allowed_ssh_cidr`)

### Terraform Initialization
- [ ] Navigate to terraform directory: `cd terraform`
- [ ] Initialize Terraform: `terraform init`
- [ ] Validate configuration: `terraform validate`
- [ ] Review planned changes: `terraform plan`
- [ ] No errors in plan output

### Infrastructure Deployment
- [ ] Apply infrastructure: `terraform apply`
- [ ] Review resource creation plan
- [ ] Confirm with 'yes'
- [ ] Wait for completion (2-3 minutes)
- [ ] Note output values (bastion IP, private IP, SSH commands)
- [ ] Save outputs: `terraform output > ../outputs.txt`

### Testing Phase
- [ ] Wait 60 seconds for instances to initialize
- [ ] Run connectivity tests: `cd .. && ./scripts/test-connectivity.sh`
- [ ] Verify all 5 tests pass:
  - [ ] SSH to bastion
  - [ ] Ping from bastion to private
  - [ ] Copy SSH key to bastion
  - [ ] SSH from bastion to private
  - [ ] Verify private instance has no public IP

### Manual Verification (Optional)
- [ ] SSH to bastion: Use command from terraform output
- [ ] From bastion, SSH to private instance
- [ ] Verify private instance cannot access internet directly
- [ ] Check AWS Console for created resources

### Cleanup Phase
- [ ] Navigate to terraform directory: `cd terraform`
- [ ] Destroy infrastructure: `terraform destroy`
- [ ] Confirm with 'yes'
- [ ] Verify all resources deleted in AWS Console
- [ ] Check for any lingering resources:
  ```bash
  aws ec2 describe-instances --filters "Name=tag:Project,Values=bastion-*"
  ```

## GitHub Actions Deployment Checklist

### Repository Setup
- [ ] Create new GitHub repository
- [ ] Push code to GitHub: `git push origin main`
- [ ] Repository visibility set appropriately

### GitHub Secrets Configuration
- [ ] Navigate to: Settings → Secrets and variables → Actions
- [ ] Add secret: `AWS_ACCESS_KEY_ID`
- [ ] Add secret: `AWS_SECRET_ACCESS_KEY`
- [ ] Add secret (optional): `AWS_REGION`
- [ ] Verify secrets are marked as "Set" (not visible)

### Workflow Configuration
- [ ] Review `.github/workflows/test-infrastructure.yml`
- [ ] Verify workflow triggers (push, PR, manual)
- [ ] Check AWS region configuration
- [ ] Confirm Terraform version matches local

### Workflow Execution
- [ ] Push to trigger workflow or use manual dispatch
- [ ] Go to Actions tab in GitHub
- [ ] Monitor workflow execution
- [ ] Verify each step completes:
  - [ ] Checkout code
  - [ ] Configure AWS credentials
  - [ ] Setup Terraform
  - [ ] Generate SSH key
  - [ ] Terraform init
  - [ ] Terraform validate
  - [ ] Terraform plan
  - [ ] Terraform apply
  - [ ] Wait for instances
  - [ ] Test SSH to bastion
  - [ ] Test connectivity to private instance
  - [ ] Test ping connectivity
  - [ ] Verify security groups
  - [ ] Terraform destroy

### Post-Deployment Verification
- [ ] All workflow steps show green checkmarks
- [ ] Review workflow logs for any warnings
- [ ] Verify AWS resources were destroyed
- [ ] No unexpected AWS charges
- [ ] Download workflow artifacts (if any)

## Security Checklist

### Before Production Use
- [ ] Review and restrict `allowed_ssh_cidr` from `0.0.0.0/0`
- [ ] Implement MFA for AWS accounts
- [ ] Enable CloudTrail logging
- [ ] Enable VPC Flow Logs
- [ ] Review IAM permissions (principle of least privilege)
- [ ] Implement AWS Systems Manager Session Manager (alternative to SSH)
- [ ] Add CloudWatch monitoring and alarms
- [ ] Implement automated security scanning
- [ ] Document incident response procedures

### SSH Key Management
- [ ] SSH keys never committed to git (check `.gitignore`)
- [ ] Private keys have 0600 permissions
- [ ] Key rotation policy defined
- [ ] Keys stored securely (not in plain text)
- [ ] Separate keys for different environments

### Cost Management
- [ ] Understand pricing for resources used
- [ ] Set up AWS Budgets and alerts
- [ ] Verify resources destroyed after testing
- [ ] Review AWS Cost Explorer regularly
- [ ] Tag all resources appropriately

## Troubleshooting Checklist

If something goes wrong, check:
- [ ] AWS credentials are valid and not expired
- [ ] IAM permissions are sufficient
- [ ] AWS region is consistent across configuration
- [ ] Terraform version matches requirements
- [ ] No resource naming conflicts
- [ ] Security groups allow necessary traffic
- [ ] Instances have had time to initialize (60-90 seconds)
- [ ] SSH key permissions are correct (0600)
- [ ] No state file locks from previous runs
- [ ] AWS service health status is operational

## Documentation Checklist

Before sharing or using in production:
- [ ] README.md reviewed and updated
- [ ] QUICKSTART.md tested by fresh user
- [ ] ARCHITECTURE.md reflects actual setup
- [ ] TROUBLESHOOTING.md includes known issues
- [ ] CONTRIBUTING.md guidelines clear
- [ ] Code comments added where helpful
- [ ] Terraform outputs documented
- [ ] Example values provided

## Success Criteria

You've successfully deployed when:
- ✅ Infrastructure provisions without errors
- ✅ All connectivity tests pass
- ✅ SSH works through bastion to private instance
- ✅ Private instance has no public IP
- ✅ Resources destroy cleanly
- ✅ No AWS resources remain after cleanup
- ✅ No unexpected costs on AWS bill

## Common Mistakes to Avoid

- ❌ Not waiting for instances to initialize before testing
- ❌ Forgetting to destroy resources after testing
- ❌ Committing SSH private keys to git
- ❌ Using 0.0.0.0/0 for SSH access in production
- ❌ Not setting correct IAM permissions
- ❌ Mixing up AWS regions
- ❌ Not checking AWS costs regularly
- ❌ Skipping the validation step before apply

## Next Steps After Successful Deployment

- [ ] Understand the architecture (read ARCHITECTURE.md)
- [ ] Experiment with modifications
- [ ] Try alternative configurations
- [ ] Integrate with your CI/CD pipeline
- [ ] Explore AWS Systems Manager Session Manager
- [ ] Learn about VPC peering and transit gateways
- [ ] Consider multi-AZ deployments
- [ ] Implement monitoring and alerting

---

**Remember:** This is a testing/learning project. Always destroy resources when done to avoid charges!

Good luck! 🚀
