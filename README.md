# WordPress High Availability on AWS

> A production-grade, highly available WordPress deployment on AWS using Auto Scaling, RDS Multi-AZ, EFS shared storage, ALB, CloudFront CDR, and S3-based Disaster Recovery.

[![AWS](https://img.shields.io/badge/Cloud-AWS-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![WordPress](https://img.shields.io/badge/CMS-WordPress-blue?logo=wordpress)](https://wordpress.org/)
[![CloudFormation](https://img.shields.io/badge/IaC-CloudFormation-red)](https://aws.amazon.com/cloudformation/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Live URLs

| Environment | URL |
|-------------|-----|
| Production | https://ganeshc.shop |
| Disaster Recovery | https://dr.ganeshc.shop |

---

## Architecture Overview

```
Internet
   │
   ▼
Route 53 (ganeshc.shop)
   │
   ▼
Application Load Balancer  (Public Subnets - AZ1 & AZ2)
   │  HTTP 80 → redirect → HTTPS 443
   │  ACM Certificate (ganeshc.shop)
   ▼
Auto Scaling Group
   ├── EC2 (Private Subnet AZ1) ─┐
   └── EC2 (Private Subnet AZ2) ─┤──► EFS (Shared wp-content)
                                  │
                                  ▼
                             RDS MySQL (Multi-AZ)
                             Private Subnets

Disaster Recovery:
dr.ganeshc.shop → CloudFront → S3 (ganeshc-dr-backup)
```

---

## AWS Services Used

| Service | Purpose |
|---------|---------|
| **VPC** | Custom network with public/private subnets across 2 AZs |
| **EC2 + ASG** | Auto Scaling EC2 instances in private subnets |
| **ALB** | Internet-facing load balancer with HTTPS termination |
| **RDS MySQL** | Managed database in private subnets |
| **EFS** | Shared `wp-content` storage across all EC2 instances |
| **ACM** | SSL/TLS certificates for `ganeshc.shop` and `dr.ganeshc.shop` |
| **Route 53** | DNS management and domain routing |
| **CloudFront** | CDN for DR static site delivery |
| **S3** | Backups and static DR site hosting |
| **Secrets Manager** | Secure DB credential storage (no hardcoded passwords) |
| **IAM** | Least-privilege roles for EC2 access |
| **CloudWatch** | Monitoring, alerts, and log aggregation |
| **CloudFormation** | Infrastructure as Code for VPC + Security Groups |

---

## Repository Structure

```
AWS-PROJECT---CLOUD-FORMATION/
│
├── cloudformation/
│   └── vpc-security-groups.yaml     # VPC, Subnets, IGW, NAT, Route Tables, SGs
│
├── scripts/
│   ├── user-data.sh                 # EC2 Launch Template bootstrap script
│   └── s3-backup.sh                 # Cron-based S3 backup script
│
├── docs/
│   ├── architecture.md              # Detailed architecture decisions
│   ├── deployment-guide.md          # Step-by-step deployment instructions
│   └── disaster-recovery.md         # DR setup and runbook
│
├── monitoring/
│   └── cloudwatch-alarms.md         # CloudWatch metrics and alarm configuration
│
├── .github/
│   └── workflows/
│       └── cfn-lint.yml             # CloudFormation linting on pull requests
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## Quick Start

> **Prerequisites:** AWS CLI configured, sufficient IAM permissions, domain registered on Hostinger.

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/aws-wordpress-ha.git
cd aws-wordpress-ha
```

### 2. Deploy VPC & Security Groups (CloudFormation)

```bash
aws cloudformation deploy \
  --template-file cloudformation/vpc-security-groups.yaml \
  --stack-name prod-vpc-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1
```

### 3. Configure Secrets Manager

```bash
aws secretsmanager create-secret \
  --name wordpress-db-secret \
  --region ap-south-1 \
  --secret-string '{
    "dbname":   "wordpress",
    "username": "prodadm",
    "password": "<your-secure-password>",
    "host":     "<your-rds-endpoint>"
  }'
```

> ⚠️ Never commit real credentials. This is a template only.

### 4. Launch Template → ASG

Configure the Launch Template using the AMI `Amazon Linux 2023`, instance type `t3.micro`, and the bootstrap script at `scripts/user-data.sh`. Update the `EFS_ID` placeholder before use.
---

## Security Architecture

| Layer | Control |
|-------|---------|
| Credentials | AWS Secrets Manager — no hardcoded secrets |
| Network | Backend in private subnets — no direct internet access |
| DB Access | RDS only accepts traffic from `sg-app` (EC2 tier) |
| HTTPS | ACM certificate enforced; HTTP auto-redirected |
| IAM | EC2 role follows least-privilege principle |
| Secrets | `wp-config.php` permissions set to `640` (owner read/write only) |

---

## Infrastructure Details

### VPC Layout

| Subnet | CIDR | AZ | Purpose |
|--------|------|----|---------|
| Public Subnet 1 | `10.0.1.0/24` | AZ-1 | ALB + NAT Gateway |
| Public Subnet 2 | `10.0.2.0/24` | AZ-2 | ALB |
| Private Subnet 1 | `10.0.3.0/24` | AZ-1 | EC2 + RDS |
| Private Subnet 2 | `10.0.4.0/24` | AZ-2 | EC2 + RDS |

### Security Groups

| Group | Allows | Source |
|-------|--------|--------|
| `sg-alb` | TCP 80, 443 | `0.0.0.0/0` |
| `sg-app` | TCP 80 | `sg-alb` only |
| `sg-db` | TCP 3306 | `sg-app` only |

### Auto Scaling Group

| Setting | Value |
|---------|-------|
| Min | 2 |
| Desired | 2 |
| Max | 3 |
| Health Check | ALB (`/healthy.html`) |
| Grace Period | 60 seconds |

---

## Disaster Recovery

The DR environment at `dr.ganeshc.shop` serves static WordPress content from an S3 bucket via CloudFront.

```
dr.ganeshc.shop
       │
       ▼
  CloudFront (OAC)
       │
       ▼
  S3: ganeshc-dr-backup
  (versioning enabled, private bucket)
```

RTO target: < 15 minutes | RPO target: < 1 hour (based on backup cron frequency)

---

## Monitoring

CloudWatch alarms are configured for:

- EC2 CPU utilization > 70%
- ALB unhealthy target count > 0
- ALB HTTP 5xx error rate spike
- RDS CPU and free storage
---

## Author

**Ganesh C**
Cloud & DevOps Engineer
- Domain: [ganeshc.shop](https://ganeshc.shop)
- GitHub: [@ganeshc](https://github.com/ganeshc)

---
