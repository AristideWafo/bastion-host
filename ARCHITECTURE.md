# Architecture Documentation

## Overview

This document describes the infrastructure architecture for the bastion host testing setup.

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                     │   │
│  │                                                           │   │
│  │  ┌────────────────────────┐  ┌────────────────────────┐ │   │
│  │  │   Public Subnet        │  │   Private Subnet       │ │   │
│  │  │   (10.0.1.0/24)        │  │   (10.0.2.0/24)        │ │   │
│  │  │                        │  │                        │ │   │
│  │  │  ┌──────────────────┐ │  │  ┌──────────────────┐ │ │   │
│  │  │  │  Bastion Host    │ │  │  │ Private Instance │ │ │   │
│  │  │  │  (EC2 t2.micro)  │─┼──┼─▶│  (EC2 t2.micro)  │ │ │   │
│  │  │  │  - Public IP     │ │  │  │  - No Public IP  │ │ │   │
│  │  │  │  - SSH Port 22   │ │  │  │  - SSH via SG    │ │ │   │
│  │  │  └──────────────────┘ │  │  └──────────────────┘ │ │   │
│  │  │           │            │  │                        │ │   │
│  │  └───────────┼────────────┘  └────────────────────────┘ │   │
│  │              │                                           │   │
│  │      ┌───────▼────────┐                                 │   │
│  │      │ Internet       │                                 │   │
│  │      │ Gateway        │                                 │   │
│  │      └───────┬────────┘                                 │   │
│  └──────────────┼──────────────────────────────────────────┘   │
│                 │                                                │
└─────────────────┼────────────────────────────────────────────────┘
                  │
                  │
        ┌─────────▼──────────┐
        │     Internet       │
        │   (Your Computer)  │
        └────────────────────┘
```

## Component Details

### VPC (Virtual Private Cloud)
- **CIDR:** 10.0.0.0/16
- **Purpose:** Isolated network environment for all resources
- **DNS:** Enabled for hostname resolution

### Public Subnet
- **CIDR:** 10.0.1.0/24
- **Route Table:** Routes to Internet Gateway
- **Purpose:** Hosts bastion host with public internet access

### Private Subnet
- **CIDR:** 10.0.2.0/24
- **Route Table:** No internet route
- **Purpose:** Hosts private instances with no direct internet access

### Internet Gateway
- **Purpose:** Provides internet connectivity for public subnet
- **Attached to:** VPC

### Bastion Host (Jump Server)
- **Instance Type:** t2.micro
- **AMI:** Amazon Linux 2
- **Network:** Public subnet with public IP
- **Purpose:** Secure gateway to access private instances
- **Access:** SSH from configurable CIDR blocks

### Private EC2 Instance
- **Instance Type:** t2.micro
- **AMI:** Amazon Linux 2
- **Network:** Private subnet (no public IP)
- **Purpose:** Simulates internal application server
- **Access:** Only via bastion host

## Security Groups

### Bastion Security Group
```
Ingress:
  - Port 22 (SSH) from 0.0.0.0/0 (configurable)

Egress:
  - All traffic to 0.0.0.0/0
```

### Private Instance Security Group
```
Ingress:
  - Port 22 (SSH) from Bastion Security Group only
  - ICMP (ping) from Bastion Security Group only

Egress:
  - All traffic to 0.0.0.0/0
```

## Data Flow

### SSH Connection to Private Instance

1. **User → Bastion Host**
   ```
   ssh -i key.pem ec2-user@<bastion-public-ip>
   ```
   - Connection through Internet Gateway
   - Bastion SG allows SSH from user's IP
   
2. **Bastion Host → Private Instance**
   ```
   ssh -i key.pem ec2-user@<private-ip>
   ```
   - Connection through VPC internal routing
   - Private SG allows SSH from Bastion SG only

### Using SSH ProxyCommand (Direct)

Users can connect directly to the private instance using:
```bash
ssh -i key.pem \
    -o ProxyCommand='ssh -i key.pem -W %h:%p ec2-user@<bastion-ip>' \
    ec2-user@<private-ip>
```

This creates a tunnel through the bastion host automatically.

## Security Features

### Defense in Depth

1. **Network Layer**
   - Private subnet with no internet gateway route
   - Security groups with minimal permissions

2. **Access Layer**
   - Single point of entry (bastion)
   - SSH key authentication only

3. **Audit Layer**
   - All access through bastion (potential for logging)
   - CloudWatch monitoring available (not configured in base setup)

### Best Practices Implemented

- ✅ Least privilege security groups
- ✅ No direct internet access to private resources
- ✅ Encrypted SSH connections only
- ✅ Temporary resources (destroyed after testing)
- ✅ Infrastructure as Code (repeatable, reviewable)

## Scaling Considerations

### For Production Use, Consider:

1. **High Availability**
   - Multiple bastion hosts across AZs
   - Auto Scaling Group for bastions
   - Application Load Balancer (if needed)

2. **Enhanced Security**
   - Restrict bastion SSH to specific IPs/VPN
   - Multi-factor authentication
   - Session Manager instead of SSH
   - Centralized logging (CloudWatch, ELK)

3. **Monitoring**
   - CloudWatch metrics and alarms
   - VPC Flow Logs
   - SSH session logging

4. **Network**
   - NAT Gateway for private subnet updates
   - VPC Endpoints for AWS services
   - Multiple private subnets across AZs

## Cost Breakdown

### Hourly Costs (us-east-1)
- t2.micro instances: $0.0116/hour each × 2 = $0.0232/hour
- VPC, Subnets, IGW: $0 (free)
- Data transfer: Negligible for testing

### Monthly Estimate (if left running)
- 2 t2.micro instances: ~$17/month
- **But this project destroys resources after testing = $0 standing cost**

## Alternative Architectures

### Option 1: AWS Systems Manager Session Manager
Replace bastion with Session Manager:
- No bastion host needed
- Access through AWS Console/CLI
- Centralized audit logging
- No public IPs required

### Option 2: VPN Connection
Replace bastion with VPN:
- AWS Client VPN or Site-to-Site VPN
- Direct network access to VPC
- Better for teams, more expensive

### Option 3: Container-Based
Replace EC2 with containers:
- ECS Fargate in private subnets
- Bastion as ECS task
- More cloud-native approach

## Testing Flow

```
1. terraform apply
   └─> Creates VPC, subnets, IGW, SGs, EC2 instances

2. Wait for instances to initialize (~60 seconds)

3. Test connectivity
   ├─> SSH to bastion (test internet access)
   ├─> Ping from bastion to private (test ICMP)
   ├─> SSH from bastion to private (test security groups)
   └─> Verify no public IP on private instance

4. terraform destroy
   └─> Cleans up all resources
```

## Further Reading

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Bastion Host Best Practices](https://aws.amazon.com/quickstart/architecture/linux-bastion/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
