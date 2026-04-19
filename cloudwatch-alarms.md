# CloudWatch Monitoring & Alarms

Monitoring configuration for the WordPress HA stack on `ganeshc.shop`.

---

## Alarms

### 1. EC2 High CPU Utilization

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-ec2-high-cpu" \
  --alarm-description "EC2 CPU utilization above 70% for 5 minutes" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions <sns-topic-arn> \
  --region ap-south-1
```

### 2. ALB Unhealthy Target Count

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-alb-unhealthy-targets" \
  --alarm-description "ALB has unhealthy targets" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --dimensions Name=TargetGroup,Value=<tg-arn> Name=LoadBalancer,Value=<alb-arn> \
  --statistic Average \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions <sns-topic-arn> \
  --region ap-south-1
```

### 3. ALB HTTP 5xx Error Rate

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-alb-5xx-errors" \
  --alarm-description "ALB HTTP 5xx errors spike detected" \
  --metric-name HTTPCode_ELB_5XX_Count \
  --namespace AWS/ApplicationELB \
  --dimensions Name=LoadBalancer,Value=<alb-arn> \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions <sns-topic-arn> \
  --region ap-south-1
```

### 4. RDS CPU Utilization

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-rds-high-cpu" \
  --alarm-description "RDS CPU utilization above 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --dimensions Name=DBInstanceIdentifier,Value=prod-wordpress-db \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions <sns-topic-arn> \
  --region ap-south-1
```

### 5. RDS Low Free Storage

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "prod-rds-low-storage" \
  --alarm-description "RDS free storage below 2 GB" \
  --metric-name FreeStorageSpace \
  --namespace AWS/RDS \
  --dimensions Name=DBInstanceIdentifier,Value=prod-wordpress-db \
  --statistic Average \
  --period 300 \
  --threshold 2000000000 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions <sns-topic-arn> \
  --region ap-south-1
```

---

## CloudWatch Logs

### Enable EC2 System Logs (via CloudWatch Agent)

Install and configure the CloudWatch agent on EC2 via user data or SSM:

```bash
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/prod/wordpress/apache-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/prod/wordpress/apache-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/prod/wordpress/user-data",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/s3-backup.log",
            "log_group_name": "/prod/wordpress/s3-backup",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

---

## SNS Topic for Alert Emails

```bash
# Create SNS topic
aws sns create-topic --name prod-wordpress-alerts --region ap-south-1

# Subscribe your email
aws sns subscribe \
  --topic-arn <topic-arn> \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region ap-south-1
```

Confirm the subscription via the email you receive, then use the topic ARN in the alarm commands above.

---

## Key Metrics Summary

| Alarm | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| EC2 CPU | `CPUUtilization` | > 70% for 10 min | SNS alert |
| ALB unhealthy targets | `UnHealthyHostCount` | ≥ 1 | SNS alert |
| ALB 5xx errors | `HTTPCode_ELB_5XX_Count` | > 10/min | SNS alert |
| RDS CPU | `CPUUtilization` | > 80% for 10 min | SNS alert |
| RDS storage | `FreeStorageSpace` | < 2 GB | SNS alert |
