<svg width="100%" viewBox="0 0 680 860" xmlns="http://www.w3.org/2000/svg" role="img" style="font-family: sans-serif; background: #fff;">
<title>WordPress HA on AWS — Architecture Diagram</title>
<desc>Full architecture for ganeshc.shop: Route 53, ALB, Auto Scaling Group with EC2 in private subnets, RDS MySQL, EFS, Secrets Manager, S3, and CloudFront DR for dr.ganeshc.shop</desc>

<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
  <path d="M2 1L8 5L2 9" fill="none" stroke="#444" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</marker>
<style>
  text { font-family: sans-serif; fill: #1a1a1a; }
  .th  { font-size: 13px; font-weight: 600; }
  .ts  { font-size: 11px; font-weight: 400; fill: #444; }
  .arr { stroke: #444; stroke-width: 1.5; fill: none; }
  .leader { stroke: #aaa; stroke-width: 0.5; stroke-dasharray: 3 3; fill: none; }
</style>
</defs>

<!-- INTERNET -->
<rect x="260" y="10" width="160" height="36" rx="8" fill="#F1EFE8" stroke="#5F5E5A" stroke-width="0.5"/>
<text class="th" x="340" y="33" text-anchor="middle">Internet / users</text>

<line x1="340" y1="46" x2="340" y2="68" class="arr" marker-end="url(#arrow)"/>

<!-- ROUTE 53 -->
<rect x="220" y="68" width="240" height="44" rx="8" fill="#EEEDFE" stroke="#534AB7" stroke-width="0.5"/>
<text class="th" x="340" y="85" text-anchor="middle" fill="#3C3489">Route 53</text>
<text class="ts" x="340" y="102" text-anchor="middle" fill="#534AB7">ganeshc.shop → ALB alias A record</text>

<line x1="340" y1="112" x2="340" y2="134" class="arr" marker-end="url(#arrow)"/>

<!-- ACM cert badge -->
<rect x="508" y="72" width="130" height="36" rx="8" fill="#E1F5EE" stroke="#0F6E56" stroke-width="0.5"/>
<text class="th" x="573" y="86" text-anchor="middle" fill="#085041">ACM cert</text>
<text class="ts" x="573" y="101" text-anchor="middle" fill="#0F6E56">ganeshc.shop</text>
<line x1="508" y1="90" x2="460" y2="156" class="arr" marker-end="url(#arrow)" stroke="#1D9E75"/>

<!-- VPC BOUNDARY -->
<rect x="18" y="130" width="644" height="530" rx="16" fill="none" stroke="#888780" stroke-width="0.5" stroke-dasharray="6 4"/>
<text class="ts" x="36" y="148" fill="#888780">VPC  10.0.0.0/16</text>

<!-- PUBLIC SUBNETS BAND -->
<rect x="30" y="155" width="620" height="100" rx="10" fill="none" stroke="#5DCAA5" stroke-width="0.5" stroke-dasharray="4 3"/>
<text class="ts" x="46" y="170" fill="#0F6E56">Public subnets — AZ-1 (10.0.1.0/24) · AZ-2 (10.0.2.0/24)</text>

<!-- ALB -->
<rect x="140" y="178" width="320" height="56" rx="8" fill="#E1F5EE" stroke="#0F6E56" stroke-width="0.5"/>
<text class="th" x="300" y="198" text-anchor="middle" fill="#085041">Application Load Balancer (internet-facing)</text>
<text class="ts" x="300" y="218" text-anchor="middle" fill="#0F6E56">HTTP :80 → redirect · HTTPS :443 → prod-tg · sg-alb</text>

<!-- IGW -->
<rect x="30" y="178" width="100" height="44" rx="8" fill="#F1EFE8" stroke="#5F5E5A" stroke-width="0.5"/>
<text class="th" x="80" y="196" text-anchor="middle" fill="#2C2C2A">IGW</text>
<text class="ts" x="80" y="212" text-anchor="middle">0.0.0.0/0</text>

<!-- NAT GW -->
<rect x="466" y="178" width="162" height="44" rx="8" fill="#F1EFE8" stroke="#5F5E5A" stroke-width="0.5"/>
<text class="th" x="547" y="196" text-anchor="middle" fill="#2C2C2A">NAT Gateway</text>
<text class="ts" x="547" y="212" text-anchor="middle">Elastic IP · Public subnet 1</text>
<line x1="547" y1="270" x2="547" y2="222" class="arr" marker-end="url(#arrow)" stroke="#888780" stroke-dasharray="4 3"/>
<text class="ts" x="562" y="252" fill="#888780">outbound</text>

<!-- PRIVATE SUBNETS BAND -->
<rect x="30" y="270" width="620" height="270" rx="10" fill="none" stroke="#7F77DD" stroke-width="0.5" stroke-dasharray="4 3"/>
<text class="ts" x="46" y="285" fill="#534AB7">Private subnets — AZ-1 (10.0.3.0/24) · AZ-2 (10.0.4.0/24)</text>

<line x1="300" y1="234" x2="300" y2="295" class="arr" marker-end="url(#arrow)"/>

<!-- ASG BAR -->
<rect x="48" y="295" width="584" height="22" rx="6" fill="none" stroke="#AFA9EC" stroke-width="0.5" stroke-dasharray="3 3"/>
<text class="ts" x="340" y="309" text-anchor="middle" fill="#534AB7">Auto Scaling Group — min 2 / desired 2 / max 3 · health check /healthy.html</text>

<!-- EC2 AZ-1 -->
<rect x="60" y="330" width="236" height="72" rx="8" fill="#EEEDFE" stroke="#534AB7" stroke-width="0.5"/>
<text class="th" x="178" y="350" text-anchor="middle" fill="#3C3489">EC2 — AZ-1 (private)</text>
<text class="ts" x="178" y="368" text-anchor="middle" fill="#534AB7">Amazon Linux 2023 · t3.micro</text>
<text class="ts" x="178" y="385" text-anchor="middle" fill="#534AB7">Apache · PHP · WordPress · sg-app</text>

<!-- EC2 AZ-2 -->
<rect x="384" y="330" width="236" height="72" rx="8" fill="#EEEDFE" stroke="#534AB7" stroke-width="0.5"/>
<text class="th" x="502" y="350" text-anchor="middle" fill="#3C3489">EC2 — AZ-2 (private)</text>
<text class="ts" x="502" y="368" text-anchor="middle" fill="#534AB7">Amazon Linux 2023 · t3.micro</text>
<text class="ts" x="502" y="385" text-anchor="middle" fill="#534AB7">Apache · PHP · WordPress · sg-app</text>

<!-- EFS -->
<rect x="302" y="330" width="76" height="72" rx="8" fill="#FAECE7" stroke="#993C1D" stroke-width="0.5"/>
<text class="th" x="340" y="355" text-anchor="middle" fill="#712B13">EFS</text>
<text class="ts" x="340" y="373" text-anchor="middle" fill="#993C1D">Shared</text>
<text class="ts" x="340" y="389" text-anchor="middle" fill="#993C1D">wp-content</text>

<!-- EFS mount lines -->
<line x1="296" y1="366" x2="302" y2="366" stroke="#D85A30" stroke-width="1.5" fill="none" marker-end="url(#arrow)"/>
<line x1="378" y1="366" x2="384" y2="366" stroke="#D85A30" stroke-width="1.5" fill="none"/>
<line x1="378" y1="366" x2="384" y2="366" marker-end="url(#arrow)" stroke="#D85A30" stroke-width="1.5" fill="none"/>

<!-- Arrows EC2 → RDS -->
<line x1="178" y1="402" x2="178" y2="440" class="arr" marker-end="url(#arrow)"/>
<line x1="502" y1="402" x2="502" y2="440" class="arr" marker-end="url(#arrow)"/>

<!-- RDS -->
<rect x="60" y="440" width="560" height="56" rx="8" fill="#E6F1FB" stroke="#185FA5" stroke-width="0.5"/>
<text class="th" x="340" y="462" text-anchor="middle" fill="#0C447C">RDS MySQL — Multi-AZ · private subnets · sg-db</text>
<text class="ts" x="340" y="482" text-anchor="middle" fill="#185FA5">DB: wordpress · User: prodadm · No public access</text>

<!-- SUPPORTING SERVICES -->
<text class="ts" x="36" y="580" fill="#888780">Supporting services</text>

<!-- Secrets Manager -->
<rect x="30" y="588" width="180" height="56" rx="8" fill="#FAEEDA" stroke="#854F0B" stroke-width="0.5"/>
<text class="th" x="120" y="608" text-anchor="middle" fill="#633806">Secrets Manager</text>
<text class="ts" x="120" y="626" text-anchor="middle" fill="#854F0B">wordpress-db-secret</text>
<path d="M120 507 L120 550 L90 550 L90 588" fill="none" stroke="#BA7517" stroke-width="1" stroke-dasharray="4 3" marker-end="url(#arrow)"/>

<!-- IAM Role -->
<rect x="226" y="588" width="160" height="56" rx="8" fill="#FAEEDA" stroke="#854F0B" stroke-width="0.5"/>
<text class="th" x="306" y="608" text-anchor="middle" fill="#633806">IAM Role</text>
<text class="ts" x="306" y="626" text-anchor="middle" fill="#854F0B">prod-ec2-role</text>

<!-- CloudWatch -->
<rect x="402" y="588" width="158" height="56" rx="8" fill="#EAF3DE" stroke="#3B6D11" stroke-width="0.5"/>
<text class="th" x="481" y="608" text-anchor="middle" fill="#27500A">CloudWatch</text>
<text class="ts" x="481" y="626" text-anchor="middle" fill="#3B6D11">Metrics · Logs · Alarms</text>

<!-- S3 Backup -->
<rect x="576" y="588" width="82" height="56" rx="8" fill="#EAF3DE" stroke="#3B6D11" stroke-width="0.5"/>
<text class="th" x="617" y="608" text-anchor="middle" fill="#27500A">S3</text>
<text class="ts" x="617" y="626" text-anchor="middle" fill="#3B6D11">Backups</text>
<path d="M500 507 L500 550 L617 550 L617 588" fill="none" stroke="#D85A30" stroke-width="1" stroke-dasharray="4 3" marker-end="url(#arrow)"/>
<text class="ts" x="568" y="545" fill="#993C1D">cron sync</text>

<!-- DR SECTION -->
<rect x="18" y="670" width="644" height="170" rx="14" fill="none" stroke="#D85A30" stroke-width="0.5" stroke-dasharray="5 4"/>
<text class="ts" x="36" y="686" fill="#993C1D">Disaster Recovery — dr.ganeshc.shop</text>

<!-- Route53 DR -->
<rect x="40" y="694" width="160" height="44" rx="8" fill="#EEEDFE" stroke="#534AB7" stroke-width="0.5"/>
<text class="th" x="120" y="710" text-anchor="middle" fill="#3C3489">Route 53</text>
<text class="ts" x="120" y="728" text-anchor="middle" fill="#534AB7">Alias A → CloudFront</text>

<line x1="200" y1="716" x2="246" y2="716" class="arr" marker-end="url(#arrow)" stroke="#7F77DD"/>

<!-- CloudFront DR -->
<rect x="246" y="694" width="168" height="44" rx="8" fill="#FAECE7" stroke="#993C1D" stroke-width="0.5"/>
<text class="th" x="330" y="710" text-anchor="middle" fill="#712B13">CloudFront</text>
<text class="ts" x="330" y="728" text-anchor="middle" fill="#993C1D">OAC · HTTPS · us-east-1 cert</text>

<line x1="414" y1="716" x2="460" y2="716" class="arr" marker-end="url(#arrow)" stroke="#D85A30"/>

<!-- S3 DR bucket -->
<rect x="460" y="694" width="180" height="44" rx="8" fill="#FAECE7" stroke="#993C1D" stroke-width="0.5"/>
<text class="th" x="550" y="710" text-anchor="middle" fill="#712B13">S3 bucket</text>
<text class="ts" x="550" y="728" text-anchor="middle" fill="#993C1D">ganeshc-dr-backup · versioned</text>

<!-- ACM DR -->
<rect x="40" y="760" width="200" height="36" rx="8" fill="#E1F5EE" stroke="#0F6E56" stroke-width="0.5"/>
<text class="th" x="140" y="772" text-anchor="middle" fill="#085041">ACM cert — us-east-1</text>
<text class="ts" x="140" y="788" text-anchor="middle" fill="#0F6E56">dr.ganeshc.shop</text>

<!-- S3 backup → DR sync arrow -->
<line x1="617" y1="644" x2="617" y2="690" class="arr" marker-end="url(#arrow)" stroke="#D85A30" stroke-dasharray="4 3"/>

<!-- LEGEND -->
<line x1="40" y1="828" x2="70" y2="828" stroke="#888780" stroke-width="1.5" stroke-dasharray="4 3"/>
<text class="ts" x="76" y="832" fill="#444">Outbound / async</text>
<line x1="200" y1="828" x2="230" y2="828" stroke="#444" stroke-width="1.5" fill="none" marker-end="url(#arrow)"/>
<text class="ts" x="236" y="832" fill="#444">Primary traffic</text>
<rect x="340" y="820" width="14" height="14" rx="3" fill="#E1F5EE" stroke="#0F6E56" stroke-width="0.5"/>
<text class="ts" x="360" y="832" fill="#444">Public tier</text>
<rect x="430" y="820" width="14" height="14" rx="3" fill="#EEEDFE" stroke="#534AB7" stroke-width="0.5"/>
<text class="ts" x="450" y="832" fill="#444">Private tier</text>
<rect x="514" y="820" width="14" height="14" rx="3" fill="#FAECE7" stroke="#993C1D" stroke-width="0.5"/>
<text class="ts" x="534" y="832" fill="#444">DR layer</text>
</svg>
