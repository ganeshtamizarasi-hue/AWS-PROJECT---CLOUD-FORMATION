# Deployment Guide

Step-by-step instructions for deploying the WordPress HA stack on AWS from scratch.

---

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- IAM user/role with permissions for: EC2, VPC, RDS, EFS, ALB, S3, CloudFront, ACM, Route53, Secrets Manager, CloudWatch
- Domain registered (ganeshc.shop) with DNS managed via Hostinger
- Git installed locally

---

## Step 1 — ACM Certificate

1. Open **AWS Certificate Manager** → `ap-south-1` region.
2. Click **Request a public certificate**.
3. Add both domain names:
   - `ganeshc.shop`
   - `*.ganeshc.shop` (wildcard covers `dr.ganeshc.shop`)
4. Choose **DNS validation**.
5. Copy the CNAME records provided by ACM.

> For the DR CloudFront certificate, repeat in `us-east-1` (CloudFront requires certificates in us-east-1).

---

## Step 2 — Route 53 Hosted Zone

1. Open **Route 53** → **Hosted Zones** → **Create hosted zone**.
2. Enter domain name: `ganeshc.shop`, type: **Public hosted zone**.
3. AWS creates 4 NS records and 1 SOA record automatically.
4. Copy the 4 NS values (e.g. `ns-xxx.awsdns-xx.com`).
5. Log into **Hostinger DNS Management** → Replace existing nameservers with the 4 Route 53 NS values.
6. Back in Route 53, create a **CNAME record** for each ACM DNS validation entry.
7. Wait for ACM status to change to **Issued** (typically 5–30 minutes after NS propagation).

---

## Step 3 — VPC & Security Groups (CloudFormation)

```bash
aws cloudformation deploy \
  --template-file cloudformation/vpc-security-groups.yaml \
  --stack-name prod-vpc-stack \
  --parameter-overrides EnvironmentName=prod \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-south-1
```

Verify outputs in the AWS Console → CloudFormation → `prod-vpc-stack` → **Outputs** tab.

---

## Step 4 — RDS MySQL

1. **RDS → Subnet Groups → Create DB Subnet Group**
   - Name: `prod-db-subnet-group`
   - VPC: `prod-vpc`
   - Add both **private subnets** (AZ-1 and AZ-2)

2. **RDS → Create Database**
   - Engine: MySQL 8.x
   - Template: Production (or Free tier for lab)
   - DB Instance Identifier: `prod-wordpress-db`
   - Master username: `prodadm`
   - Password: use a strong password (store in Secrets Manager — see Step 5)
   - Instance class: `db.t3.micro`
   - Multi-AZ: Enabled (recommended for production)
   - Storage: 20 GB gp2, auto scaling enabled
   - VPC: `prod-vpc`
   - Subnet group: `prod-db-subnet-group`
   - Public access: **No**
   - Security group: `prod-sg-db`
   - Initial database name: `wordpress`

3. After creation, copy the **RDS endpoint** — needed for Secrets Manager.

---

## Step 5 — Secrets Manager

```bash
aws secretsmanager create-secret \
  --name wordpress-db-secret \
  --region ap-south-1 \
  --secret-string '{
    "dbname":   "wordpress",
    "username": "prodadm",
    "password": "<your-strong-password>",
    "host":     "<rds-endpoint>.rds.amazonaws.com"
  }'
```

> Never commit real passwords to Git. Use this command in your terminal only.

---

## Step 6 — EFS File System

1. **EFS → Create file system**
   - VPC: `prod-vpc`
   - Availability and durability: Regional
   - Enable lifecycle management (e.g. transition to IA after 30 days)
2. **Manage → Network → Mount targets**
   - Add mount targets in both **private subnets**
   - Security group: `prod-sg-app`
3. Copy the **EFS File System ID** (e.g. `fs-0abc12345678`).
4. Update `EFS_ID` in `scripts/user-data.sh`.

---

## Step 7 — IAM Role for EC2

1. **IAM → Roles → Create role**
   - Trusted entity: **EC2**
   - Attach policies:
     - `AmazonSSMManagedInstanceCore`
     - `AmazonS3FullAccess`
     - `SecretsManagerReadWrite` (or a custom least-privilege policy)
   - Role name: `prod-ec2-role`

---

## Step 8 — Launch Template

1. **EC2 → Launch Templates → Create launch template**
   - Name: `prod-wordpress-lt`
   - AMI: Amazon Linux 2023 (latest)
   - Instance type: `t3.micro`
   - IAM instance profile: `prod-ec2-role`
   - Security group: `prod-sg-app`
   - **User data**: paste the full contents of `scripts/user-data.sh`
     (ensure `EFS_ID` is updated before pasting)

---

## Step 9 — Auto Scaling Group

1. **EC2 → Auto Scaling Groups → Create**
   - Launch template: `prod-wordpress-lt`
   - VPC: `prod-vpc`
   - Subnets: both **private subnets**
   - Attach to target group: `prod-tg` (create below in Step 10)
   - Desired: 2 | Min: 2 | Max: 3
   - Health check: **ELB**, grace period: **60 seconds**

---

## Step 10 — Application Load Balancer

1. **EC2 → Load Balancers → Create → Application Load Balancer**
   - Name: `prod-alb`
   - Scheme: **Internet-facing**
   - VPC: `prod-vpc`
   - Subnets: both **public subnets**
   - Security group: `prod-sg-alb`

2. **Target Group**
   - Name: `prod-tg`
   - Target type: Instances
   - Protocol: HTTP, Port: 80
   - Health check path: `/healthy.html`
   - Register EC2 instances (or let ASG do it)

3. **Listeners**
   - HTTP:80 → Action: **Redirect to HTTPS:443**
   - HTTPS:443 → Action: **Forward to prod-tg**
   - SSL Certificate: select `ganeshc.shop` from ACM

---

## Step 11 — Route 53 Domain Mapping

1. **Route 53 → Hosted Zone → ganeshc.shop → Create record**
   - Record name: (blank = apex domain)
   - Record type: **A**
   - Alias: **Yes** → Target: `prod-alb`
2. Open `https://ganeshc.shop` — WordPress setup wizard should appear.
3. Verify `https://ganeshc.shop/healthy.html` returns `healthy`.

---

## Step 12 — S3 Backup (Cron)

SSH into an EC2 instance (via SSM Session Manager):

```bash
# Copy backup script
sudo cp /tmp/s3-backup.sh /usr/local/bin/s3-backup.sh
sudo chmod +x /usr/local/bin/s3-backup.sh

# Add cron jobs
sudo crontab -e
```

Add these lines:

```cron
# Sync media uploads to S3 every hour
0 * * * * /usr/local/bin/s3-backup.sh

# Full code archive daily at 2 AM
0 2 * * * /usr/local/bin/s3-backup.sh
```

---

## Step 13 — Disaster Recovery (CloudFront + S3)

1. **S3 → Create bucket**: `ganeshc-dr-backup`
   - Region: `ap-south-1`
   - Block all public access: **Yes**
   - Enable versioning: **Yes**

2. **CloudFront → Create distribution**
   - Origin: `ganeshc-dr-backup` (S3)
   - Origin access: **OAC (Origin Access Control)** — attach generated policy to S3 bucket
   - Alternate domain name (CNAME): `dr.ganeshc.shop`
   - SSL certificate: ACM cert from `us-east-1`
   - Default root object: `index.html`

3. **Route 53 → Create record**
   - Name: `dr`
   - Type: **A (Alias)**
   - Target: CloudFront distribution

4. Access `https://dr.ganeshc.shop` to verify DR delivery.

---

## Verification Checklist

| Check | Expected Result |
|-------|----------------|
| `https://ganeshc.shop` | WordPress setup page or site |
| `https://ganeshc.shop/healthy.html` | Returns `healthy` (ALB target green) |
| `https://dr.ganeshc.shop` | DR content served via CloudFront |
| RDS connectivity | EC2 connects to MySQL via private endpoint |
| EFS mount | `/var/www/html/wp-content` shared across instances |
| Secrets Manager | No credentials in code or EC2 environment variables |
| CloudWatch | Alarms visible for CPU, 5xx, unhealthy targets |
