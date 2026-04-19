# Architecture Decisions

Design rationale for the WordPress HA deployment on AWS.

---

## High Availability

**Why 2 AZs?**
Deploying across two Availability Zones means a single data center failure does not take the application offline. The ASG maintains the desired instance count across both AZs, and RDS Multi-AZ provides automatic failover within ~60 seconds.

**Why ALB over a single EC2 with Elastic IP?**
The ALB distributes traffic across all healthy instances in the target group and performs continuous health checks. If an instance fails, it is removed from rotation automatically. A single EC2 is a single point of failure.

---

## Networking

**Why private subnets for EC2 and RDS?**
Backend resources should never be directly reachable from the internet. Private subnets have no route to the Internet Gateway. Outbound internet traffic (e.g. WordPress updates, package downloads) is routed through the NAT Gateway in the public subnet.

**Why a NAT Gateway rather than a NAT instance?**
NAT Gateway is AWS-managed, highly available within an AZ, and requires no patching or scaling configuration. NAT instances are cheaper but require operational overhead.

**Why one NAT Gateway?**
For this project, cost is a consideration. A single NAT Gateway in AZ-1 serves both private subnets. In a strict production environment, deploy one NAT Gateway per AZ to eliminate cross-AZ NAT traffic costs and AZ-level dependency.

---

## Database

**Why RDS over a self-managed MySQL on EC2?**
RDS provides automated backups, point-in-time recovery, automated minor version patching, Multi-AZ failover, and performance monitoring out of the box. Managing MySQL on EC2 requires manual setup of all of these.

**Why Secrets Manager over environment variables or wp-config.php hardcoding?**
Secrets Manager stores credentials encrypted at rest (AWS KMS). Credentials are fetched at runtime via IAM role — no static secrets in code, AMIs, or environment variables. Rotation can be automated.

---

## Storage

**Why EFS for wp-content?**
In a multi-instance ASG setup, each EC2 would have its own local `wp-content`. If a user uploads a media file to instance A, instance B would not have it. EFS is a shared network file system that all instances mount simultaneously, solving this consistency problem.

**Why S3 for backups?**
S3 provides 11 nines of durability, versioning, lifecycle policies, and cross-region replication. It is the natural choice for durable, low-cost backup storage.

---

## Security

**Security group chain (sg-alb → sg-app → sg-db)**
This enforces strict traffic flow:
- Only the ALB can talk to EC2 (not direct internet access)
- Only EC2 can talk to RDS (not the ALB or internet)
- This limits blast radius if any single tier is compromised

**IAM least privilege**
The EC2 IAM role has only the permissions it needs: read from Secrets Manager, write to S3 (for backups), and optionally SSM for remote access. No `AdministratorAccess`.

---

## Disaster Recovery

**Architecture: CloudFront + S3**
The DR site is entirely static — served from an S3 bucket via CloudFront. This means zero compute cost at rest, global CDN delivery, and no single point of failure. S3 versioning protects against accidental overwrites.

**OAC over OAI**
Origin Access Control (OAC) is the current AWS recommendation over the legacy Origin Access Identity (OAI). OAC supports all S3 operations, additional AWS regions, and server-side encryption with customer-managed keys.

---

## Cost Considerations

| Resource | Monthly Estimate (ap-south-1) |
|----------|-------------------------------|
| 2x t3.micro EC2 (on-demand) | ~$15 |
| RDS db.t3.micro Single-AZ | ~$15 |
| NAT Gateway (1x) | ~$35 + data transfer |
| EFS (Regional, 5 GB) | ~$1.50 |
| ALB | ~$18 base + LCU |
| S3 (10 GB) | ~$0.23 |
| CloudFront (1 GB) | ~$0.09 |

> Estimates only. Actual costs depend on traffic, data transfer, and reserved pricing.
