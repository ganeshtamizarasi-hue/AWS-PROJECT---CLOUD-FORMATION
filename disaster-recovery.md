# Disaster Recovery Runbook

DR environment for `ganeshc.shop` — hosted at `https://dr.ganeshc.shop`.

---

## Architecture

```
dr.ganeshc.shop
      │
      ▼
 Route 53 (Alias A record)
      │
      ▼
 CloudFront Distribution
 (CNAME: dr.ganeshc.shop, ACM cert: us-east-1)
      │
      ▼
 S3: ganeshc-dr-backup  (private, versioning on)
 (OAC — Origin Access Control)
```

---

## S3 Bucket Setup

```bash
# Create the DR bucket
aws s3api create-bucket \
  --bucket ganeshc-dr-backup \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ganeshc-dr-backup \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket ganeshc-dr-backup \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

---

## CloudFront Setup

1. **Create distribution**
   - Origin domain: `ganeshc-dr-backup.s3.ap-south-1.amazonaws.com`
   - Origin access: Create new **OAC** → copy generated S3 bucket policy → apply to S3 bucket
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
   - Alternate domain names: `dr.ganeshc.shop`
   - Custom SSL certificate: select ACM cert for `*.ganeshc.shop` (must be in `us-east-1`)
   - Default root object: `index.html`

2. Apply the OAC-generated bucket policy to S3:
   ```bash
   aws s3api put-bucket-policy \
     --bucket ganeshc-dr-backup \
     --policy file://cloudfront-oac-policy.json
   ```

---

## Syncing Content to DR

The S3 backup script (`scripts/s3-backup.sh`) syncs `wp-content/uploads` automatically. For a full DR sync including the WordPress code:

```bash
# Sync entire web root to DR bucket
aws s3 sync /var/www/html/ s3://ganeshc-dr-backup/ \
  --region ap-south-1 \
  --delete \
  --sse AES256
```

Add to crontab on EC2 for automated DR sync:

```cron
# DR sync — daily at 3 AM
0 3 * * * aws s3 sync /var/www/html/ s3://ganeshc-dr-backup/ --region ap-south-1 --delete --sse AES256
```

---

## DR Activation Procedure

If the primary production site (`ganeshc.shop`) goes down:

1. **Confirm outage** — check ALB target group health, EC2 status, RDS status in CloudWatch.
2. **Verify DR content is current** — check last sync timestamp in `/var/log/s3-backup.log` or S3 last-modified dates.
3. **Update Route 53** (if needed) — the `dr.ganeshc.shop` subdomain is always live via CloudFront. No failover action needed for DR URL.
4. **Communicate** — notify users to use `https://dr.ganeshc.shop` during the outage.
5. **Investigate and restore** primary environment.
6. **Sync any new uploads** from DR back to primary after restoration.

---

## Recovery Targets

| Metric | Target |
|--------|--------|
| RTO (Recovery Time Objective) | < 15 minutes |
| RPO (Recovery Point Objective) | < 1 hour (based on cron frequency) |

---

## Restore from S3 Backup

To restore WordPress code from a backup archive:

```bash
# List available backups
aws s3 ls s3://ganeshc-wp-code-backup/backups/ --region ap-south-1

# Download a specific backup
aws s3 cp s3://ganeshc-wp-code-backup/backups/wordpress-code-2025-01-15_02-00-00.tar.gz /tmp/

# Extract to web root
tar -xzf /tmp/wordpress-code-2025-01-15_02-00-00.tar.gz -C /var/www/
chown -R apache:apache /var/www/html
```
