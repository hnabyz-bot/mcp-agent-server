# Forms Subdomain Deployment Guide
## forms.abyz-lab.work - Cloudflare Configuration

**Project:** MCP Agent Server
**Domain:** abyz-lab.work
**Subdomain:** forms.abyz-lab.work
**Last Updated:** 2026-01-26
**Status:** Configuration Ready

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Infrastructure Overview](#infrastructure-overview)
3. [Deployment Options Analysis](#deployment-options-analysis)
4. [Recommended Solution](#recommended-solution)
5. [Step-by-Step Configuration](#step-by-step-configuration)
6. [Security Configuration](#security-configuration)
7. [Caching Strategy](#caching-strategy)
8. [Testing Procedures](#testing-procedures)
9. [Rollback Procedures](#rollback-procedures)
10. [Monitoring & Maintenance](#monitoring--maintenance)
11. [Troubleshooting](#troubleshooting)

---

## Executive Summary

This guide provides comprehensive configuration for adding `forms.abyz-lab.work` subdomain to the existing Cloudflare-managed infrastructure. The solution extends the current Cloudflare Tunnel setup that powers `api.abyz-lab.work` (n8n) to include the new forms subdomain.

**Key Decisions:**
- **Approach:** Extend existing Cloudflare Tunnel (single tunnel, multiple services)
- **Service Type:** Static HTML form with n8n webhook backend
- **Security:** Full (strict) SSL/TLS, WAF enabled
- **Caching:** Static assets cached, form POST bypassed
- **Platform:** Raspberry Pi 5 with nginx web server

**Benefits:**
- Unified tunnel management (simplified operations)
- Zero additional Cloudflare costs
- Low latency (edge routing)
- Automatic SSL certificate management
- Built-in DDoS protection

---

## Infrastructure Overview

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Cloudflare Edge                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  DNS: abyz-lab.work                               │    │
│  │  - api.abyz-lab.work → Tunnel (existing)          │    │
│  │  - forms.abyz-lab.work → Tunnel (new)             │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                    Cloudflare Tunnel
                            │
┌─────────────────────────────────────────────────────────────┐
│              Raspberry Pi 5 (Home Network)                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │  cloudflared (Tunnel Agent)                        │    │
│  │  - Port 5678 → n8n (api.abyz-lab.work)            │    │
│  │  - Port 8080 → nginx (forms.abyz-lab.work)        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  Services:                                                  │
│  - n8n (existing)                                          │
│  - nginx + static HTML (new)                               │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Infrastructure:**
- **DNS:** Cloudflare DNS
- **Tunnel:** Cloudflare Tunnel (cloudflared)
- **SSL/TLS:** Cloudflare Full (Strict)
- **Firewall:** Cloudflare WAF
- **CDN:** Cloudflare CDN

**Application:**
- **Web Server:** nginx (port 8080)
- **Form Handler:** n8n webhook (port 5678)
- **Backend:** n8n workflow processing
- **Static Files:** HTML, CSS, JavaScript

---

## Deployment Options Analysis

### Option 1: Static Files from Raspberry Pi 5 (nginx) ⭐ **RECOMMENDED**

**Architecture:** Serve static HTML form from Raspberry Pi 5 via nginx, proxy form submissions to n8n webhook.

**Pros:**
- ✅ Unified tunnel management with existing api.abyz-lab.work
- ✅ Zero additional hosting costs
- ✅ Full control over form behavior and styling
- ✅ Low latency (local network)
- ✅ Easy integration with existing n8n workflows
- ✅ Simple backup and version control

**Cons:**
- ⚠️ Requires Raspberry Pi 5 maintenance
- ⚠️ Limited scalability (single point of failure)
- ⚠️ Requires nginx configuration

**Cost:** $0/month (no additional costs)
**Complexity:** Low
**Performance:** High (local)

**Use Case:** Production deployment with moderate traffic (< 1000 submissions/day)

---

### Option 2: Cloudflare Pages (Static Form)

**Architecture:** Deploy static HTML form to Cloudflare Pages, use Cloudflare Workers for form processing.

**Pros:**
- ✅ Global CDN (automatic geographic distribution)
- ✅ 99.99% uptime SLA
- ✅ Automatic SSL certificates
- ✅ Git-based deployment workflow
- ✅ Preview deployments
- ✅ Serverless Workers for form processing

**Cons:**
- ❌ Requires Cloudflare Workers for POST handling
- ❌ Additional complexity (Workers integration)
- ❌ n8n webhook requires CORS configuration
- ❌ Separate infrastructure from api.abyz-lab.work

**Cost:** $0/month (free tier) or $20/month (Workers paid)
**Complexity:** Medium
**Performance:** Very High (global edge)

**Use Case:** High-traffic forms requiring global distribution

---

### Option 3: n8n Form Node + Cloudflare Tunnel

**Architecture:** Use n8n's built-in form functionality directly through Cloudflare Tunnel.

**Pros:**
- ✅ No additional web server needed
- ✅ Native n8n integration
- ✅ Simple setup
- ✅ Unified workflow management

**Cons:**
- ❌ Limited form customization
- ❌ n8n UI exposed (security concern)
- ❌ Performance impact on n8n instance
- ❌ No static asset optimization

**Cost:** $0/month
**Complexity:** Very Low
**Performance:** Medium

**Use Case:** Internal forms, rapid prototyping, admin interfaces

---

### Option 4: Cloudflare Workers (Serverless Function)

**Architecture:** Pure serverless solution - Workers handle both form display and submission.

**Pros:**
- ✅ True serverless (no server maintenance)
- ✅ Global edge network
- ✅ Auto-scaling
- ✅ Cold starts under 50ms
- ✅ Durable Objects for state (if needed)

**Cons:**
- ❌ Requires Workers programming (JavaScript/TypeScript)
- ❌ Separate deployment pipeline
- ❌ n8n integration requires HTTP requests
- ❌ Learning curve for team

**Cost:** $5/month (Workers paid) - free tier available
**Complexity:** High
**Performance:** Very High (edge)

**Use Case:** Developers comfortable with Workers, custom form logic

---

## Recommended Solution

### **Option 1: Static Files from Raspberry Pi 5 (nginx)**

**Rationale:**
1. **Cost-Effective:** Zero additional hosting costs
2. **Simplicity:** Leverages existing tunnel and infrastructure
3. **Flexibility:** Full control over form design and behavior
4. **Integration:** Seamless n8n webhook integration
5. **Maintenance:** Single point of maintenance (Raspberry Pi 5)

**Architecture:**
```
User → Cloudflare Edge → Cloudflare Tunnel → Raspberry Pi 5
                                                ↓
                                    nginx (port 8080)
                                                ↓
                                    ┌─────────────────────┐
                                    │ Static HTML/CSS/JS  │
                                    │ (/index.html)       │
                                    └─────────────────────┘
                                                ↓
                                    Form POST /submit
                                                ↓
                                    Proxy to n8n webhook
                                    (localhost:5678)
```

---

## Step-by-Step Configuration

### Phase 1: DNS Configuration (Cloudflare Dashboard)

**Step 1.1: Access Cloudflare Dashboard**
1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select domain: `abyz-lab.work`
3. Navigate to **DNS** → **Records**

**Step 1.2: Add DNS Record**

| Field | Value |
|-------|-------|
| Type | **CNAME** |
| Name | **forms** |
| Target | **[TUNNEL_ID].cfargotunnel.com** |
| Proxy Status | **Proxied** (Orange cloud) ☁️ |
| TTL | **Auto** |

**Example:**
```
Type: CNAME
Name: forms
Content: abcd1234-5678-90ef-ghij-klmnopqrstuv.cfargotunnel.com
Proxy status: Proxied ☁️
TTL: Auto
```

**Verification:**
```bash
# DNS propagation check
dig forms.abyz-lab.work

# Should return:
# forms.abyz-lab.work. 300 IN CNAME [TUNNEL_ID].cfargotunnel.com.
```

**References:**
- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/manage-dns-records/how-to/create-subdomain/)
- [Manage Subdomains Guide](https://developers.cloudflare.com/fundamentals/manage-domains/manage-subdomains/)

---

### Phase 2: Cloudflare Tunnel Configuration

**Step 2.1: Extend Existing Tunnel Configuration**

On Raspberry Pi 5, edit the cloudflared configuration:

```bash
# SSH into Raspberry Pi 5
ssh pi@raspberry-pi-5

# Backup existing configuration
sudo cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.backup

# Edit configuration
sudo nano ~/.cloudflared/config.yml
```

**Updated config.yml:**

See `config/cloudflare-tunnel-config.yaml` for complete configuration.

**Key additions:**
```yaml
ingress:
  # NEW: Forms subdomain routing
  - hostname: forms.abyz-lab.work
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true

  # EXISTING: API subdomain routing
  - hostname: api.abyz-lab.work
    service: http://localhost:5678
    originRequest:
      noTLSVerify: true

  # Catch-all 404
  - service: http_status:404
```

**Step 2.2: Restart cloudflared Service**

```bash
# Restart cloudflared to apply changes
sudo systemctl restart cloudflared

# Check service status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

**References:**
- [Many Services, One Cloudflared](https://blog.cloudflare.com/many-services-one-cloudflared/)
- [Tunnel Configuration File](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/configuration-file/)

---

### Phase 3: Web Server Configuration (nginx)

**Step 3.1: Install nginx on Raspberry Pi 5**

```bash
# Update package list
sudo apt update

# Install nginx
sudo apt install nginx -y

# Enable nginx to start on boot
sudo systemctl enable nginx

# Start nginx service
sudo systemctl start nginx

# Verify nginx is running
sudo systemctl status nginx
```

**Step 3.2: Configure nginx for forms subdomain**

```bash
# Copy nginx configuration
sudo cp config/nginx-forms.conf /etc/nginx/sites-available/forms.abyz-lab.work

# Create symbolic link to enable site
sudo ln -s /etc/nginx/sites-available/forms.abyz-lab.work /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx to apply configuration
sudo systemctl reload nginx
```

**Step 3.3: Create web root directory**

```bash
# Create directory structure
sudo mkdir -p /var/www/forms.abyz-lab.work

# Set permissions
sudo chown -R www-data:www-data /var/www/forms.abyz-lab.work
sudo chmod -R 755 /var/www/forms.abyz-lab.work

# Create test HTML page
sudo nano /var/www/forms.abyz-lab.work/index.html
```

**Test index.html:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forms - Abyz Lab</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            line-height: 1.6;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background-color: #0056b3;
        }
        .success {
            color: green;
            margin-top: 15px;
        }
        .error {
            color: red;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <h1>Contact Form</h1>
    <form id="contactForm">
        <div class="form-group">
            <label for="name">Name:</label>
            <input type="text" id="name" name="name" required>
        </div>

        <div class="form-group">
            <label for="email">Email:</label>
            <input type="email" id="email" name="email" required>
        </div>

        <div class="form-group">
            <label for="message">Message:</label>
            <textarea id="message" name="message" rows="5" required></textarea>
        </div>

        <button type="submit">Submit</button>

        <div id="result"></div>
    </form>

    <script>
        document.getElementById('contactForm').addEventListener('submit', async function(e) {
            e.preventDefault();

            const formData = {
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                message: document.getElementById('message').value,
                timestamp: new Date().toISOString()
            };

            const resultDiv = document.getElementById('result');

            try {
                const response = await fetch('/submit', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(formData)
                });

                if (response.ok) {
                    resultDiv.className = 'success';
                    resultDiv.textContent = 'Thank you! Your form has been submitted successfully.';
                    document.getElementById('contactForm').reset();
                } else {
                    throw new Error('Form submission failed');
                }
            } catch (error) {
                resultDiv.className = 'error';
                resultDiv.textContent = 'An error occurred. Please try again later.';
                console.error('Error:', error);
            }
        });
    </script>
</body>
</html>
```

---

### Phase 4: n8n Webhook Configuration

**Step 4.1: Create n8n Workflow for Form Submission**

1. Access n8n at `https://api.abyz-lab.work`
2. Create new workflow: "Form Submission Handler"
3. Add **Webhook** node as trigger:
   - Path: `/webhook/form-submit`
   - HTTP Method: `POST`
   - Response: `{"success": true}`

4. Add form processing nodes (example):
   - **Set** node: Extract form fields
   - **Send Email** node: Notify admin
   - **Google Sheets** node: Log submission
   - **Slack** node: Send notification

**Step 4.2: Test Webhook**

```bash
# Test webhook directly (on Raspberry Pi 5)
curl -X POST http://localhost:5678/webhook/form-submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","message":"Test message"}'

# Test through Cloudflare Tunnel
curl -X POST https://api.abyz-lab.work/webhook/form-submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","message":"Test message"}'
```

---

### Phase 5: SSL/TLS Configuration

**Step 5.1: Configure Cloudflare SSL/TLS**

1. In Cloudflare Dashboard, go to **SSL/TLS**
2. Set encryption mode to **Full (strict)**

**Encryption Mode Comparison:**

| Mode | Description | Use Case |
|------|-------------|----------|
| **Flexible** | Cloudflare → Origin (HTTP) | Testing only |
| **Full** | Cloudflare → Origin (HTTPS, any cert) | Self-signed certs OK |
| **Full (Strict)** ⭐ | Cloudflare → Origin (HTTPS, valid cert) | Production |

**Step 5.2: Install SSL Certificate on nginx (Option A: Let's Encrypt)**

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d forms.abyz-lab.work

# Test auto-renewal
sudo certbot renew --dry-run
```

**Step 5.3: Use Cloudflare Origin Certificate (Option B: Recommended)**

1. In Cloudflare Dashboard, go to **SSL/TLS** → **Origin Server**
2. Click **Create Certificate**
3. Choose hostname: `forms.abyz-lab.work`
4. Copy certificate and private key

```bash
# On Raspberry Pi 5, create certificate directory
sudo mkdir -p /etc/cloudflare

# Save certificate (from Cloudflare Dashboard)
sudo nano /etc/cloudflare/origin.pem
# [Paste certificate content]

# Save private key (from Cloudflare Dashboard)
sudo nano /etc/cloudflare/key.pem
# [Paste private key content]

# Set permissions
sudo chmod 600 /etc/cloudflare/*
sudo chown root:root /etc/cloudflare/*

# Update nginx configuration to use Cloudflare certificate
# Edit /etc/nginx/sites-available/forms.abyz-lab.work
# Uncomment lines under "Option 2: Cloudflare Origin Certificate"

# Reload nginx
sudo systemctl reload nginx
```

---

## Security Configuration

### Firewall Rules (Cloudflare WAF)

**Recommended WAF Rules:**

1. **Rate Limiting Rule:**
   - Field: **URI Path**
   - Operator: **equals**
   - Value: `/submit`
   - Action: **Rate Limit**
   - Rate: 10 requests per minute
   - Period: 1 minute

2. **Country Blocking (Optional):**
   - Action: **Block**
   - Expression: `(ip.geoip.country eq "CN" or ip.geoip.country eq "RU")`

3. **SQL Injection Protection:**
   - Managed Rule: **Cloudflare Managed Ruleset**
   - Enable: **SQL Injection** rule group

4. **Hotlink Protection:**
   - Field: **URI Path**
   - Operator: **matches regex**
   - Value: `.*\.(jpg|jpeg|png|gif|css|js)$`
   - Condition: **Referer** does not contain `forms.abyz-lab.work`
   - Action: **Block**

### Bot Protection

**Recommended Settings:**

- **Bot Fight Mode:** Enable (free)
- **Bot Management:** Enable if available (paid)

**Configuration:**
1. Go to **Security** → **Bots**
2. Toggle **Bot Fight Mode** to **ON**
3. Configure **Super Bot Fight Mode** if needed

### Access Rules (Optional)

**IP Whitelist for Admin Access:**

1. Go to **Security** → **WAF** → **Custom Rules**
2. Create rule:
   - Field: **IP Address**
   - Operator: **equals**
   - Value: `YOUR_ADMIN_IP`
   - Action: **Allow**
   - URI Path: `/admin/*`

### Cloudflare Access (Zero Trust) - Optional

For additional security, implement Cloudflare Access:

1. Go to **Zero Trust** → **Access** → **Applications**
2. Add new application:
   - Session Duration: `24h`
   - Authentication: **Google** or **Email OTP**
3. Protect `/admin` endpoints

---

## Caching Strategy

### Cache Rules Configuration

**Rule 1: Static Assets (Aggressive Caching)**

Create Page Rule:
- URL: `forms.abyz-lab.work/*/*.css` OR `forms.abyz-lab.work/*/*.js` OR `forms.abyz-lab.work/*/*.png`
- Settings:
  - Cache Level: **Cache Everything**
  - Edge Cache TTL: **1 month**
  - Browser Cache TTL: **1 year**

**Rule 2: HTML Files (Moderate Caching)**

- URL: `forms.abyz-lab.work/*.html`
- Settings:
  - Cache Level: **Standard**
  - Edge Cache TTL: **2 hours**
  - Browser Cache TTL: **2 hours**

**Rule 3: Form POST (Bypass Cache)**

- URL: `forms.abyz-lab.work/submit`
- Settings:
  - Cache Level: **Bypass**

### Cache Purge Strategy

**Manual Purge (Cloudflare Dashboard):**
1. Go to **Caching** → **Configuration**
2. Click **Purge Individual Files**
3. Enter URLs to purge

**API Purge (Automated):**
```bash
# Purge cache using Cloudflare API
curl -X POST "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer {API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"files":["https://forms.abyz-lab.work/index.html"]}'
```

**Auto-Purge on Deploy:**
Add to deployment script:
```bash
# After updating static files, purge Cloudflare cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

---

## Testing Procedures

### Pre-Deployment Checklist

- [ ] DNS record created and propagated
- [ ] Cloudflare Tunnel configuration updated
- [ ] nginx installed and configured
- [ ] SSL certificate installed
- [ ] n8n webhook created and tested
- [ ] Security rules configured
- [ ] Cache rules configured

### Smoke Tests

**Test 1: DNS Resolution**
```bash
# Run from local machine
dig forms.abyz-lab.work

# Expected: CNAME pointing to tunnel
```

**Test 2: HTTP/HTTPS Access**
```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://forms.abyz-lab.work

# Expected: 301 Redirect to HTTPS

# Test HTTPS
curl -I https://forms.abyz-lab.work

# Expected: 200 OK
```

**Test 3: SSL Certificate**
```bash
# Check SSL certificate
openssl s_client -connect forms.abyz-lab.work:443 -servername forms.abyz-lab.work

# Expected: Valid certificate chain
```

**Test 4: Form Submission**
```bash
# Submit test form data
curl -X POST https://forms.abyz-lab.work/submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Smoke Test","email":"test@example.com","message":"Test message"}'

# Expected: 200 OK with success response
```

**Test 5: Cache Behavior**
```bash
# Test cache hit for static assets
curl -I https://forms.abyz-lab.work/style.css

# Expected: CF-Cache-Status: HIT

# Test cache bypass for form POST
curl -I -X POST https://forms.abyz-lab.work/submit

# Expected: CF-Cache-Status: BYPASS
```

### Integration Testing

**Test 6: End-to-End Form Flow**
1. Open browser: `https://forms.abyz-lab.work`
2. Fill out form fields
3. Click Submit button
4. Verify success message
5. Check n8n workflow execution log
6. Verify email/Slack notification received

### Performance Testing

**Test 7: Load Testing (Optional)**
```bash
# Install Apache Bench
sudo apt install apache2-utils -y

# Run load test (100 requests, 10 concurrent)
ab -n 100 -c 10 -T "application/json" -p form-data.json https://forms.abyz-lab.work/submit

# Expected: 0 failed requests, < 1s average response time
```

### Security Testing

**Test 8: Security Headers**
```bash
# Check security headers
curl -I https://forms.abyz-lab.work

# Verify headers present:
# - Strict-Transport-Security
# - X-Frame-Options
# - X-Content-Type-Options
# - X-XSS-Protection
```

**Test 9: SQL Injection Protection**
```bash
# Test WAF rule
curl -X POST https://forms.abyz-lab.work/submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Test\' OR \'1\'=\'1","email":"test@example.com","message":"Test"}'

# Expected: 403 Forbidden (blocked by WAF)
```

---

## Rollback Procedures

### Immediate Rollback (DNS)

**Step 1: Disable DNS Record**
1. Go to Cloudflare Dashboard → DNS
2. Find `forms.abyz-lab.work` record
3. Click **Edit**
4. Toggle **Proxy status** to **DNS only** (grey cloud)
5. Or click **Delete** to remove record

**Step 2: Verify Rollback**
```bash
dig forms.abyz-lab.work
# Should return NXDOMAIN or grey cloud
```

### Service Rollback (Tunnel)

**Step 1: Restore Previous Tunnel Configuration**
```bash
# SSH into Raspberry Pi 5
ssh pi@raspberry-pi-5

# Restore backup configuration
sudo cp ~/.cloudflared/config.yml.backup ~/.cloudflared/config.yml

# Restart cloudflared
sudo systemctl restart cloudflared

# Verify service status
sudo systemctl status cloudflared
```

### Service Rollback (nginx)

**Step 1: Disable nginx Site**
```bash
# Disable nginx site
sudo rm /etc/nginx/sites-enabled/forms.abyz-lab.work

# Reload nginx
sudo systemctl reload nginx

# Verify
sudo nginx -t
```

**Step 2: Stop nginx Service (if needed)**
```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### Complete Rollback

**Full Rollback Sequence:**
1. Delete DNS record (Cloudflare Dashboard)
2. Remove tunnel ingress rule (config.yml)
3. Disable nginx site
4. Purge Cloudflare cache
5. Verify forms subdomain is inaccessible

**Verification:**
```bash
# Should fail or return NXDOMAIN
curl https://forms.abyz-lab.work
```

---

## Monitoring & Maintenance

### Cloudflare Analytics

**Key Metrics to Monitor:**

1. **Traffic Analysis:**
   - Dashboard: **Analytics** → **Traffic**
   - Monitor: Request count, bandwidth, unique visitors

2. **Performance Metrics:**
   - Dashboard: **Analytics** → **Performance**
   - Monitor: Response time, origin latency, error rate

3. **Security Events:**
   - Dashboard: **Security** → **Overview**
   - Monitor: Threatened traffic, blocked requests

4. **WAF Analytics:**
   - Dashboard: **Security** → **WAF** → **Analytics**
   - Monitor: Triggered rules, matched requests

### Server Monitoring (Raspberry Pi 5)

**System Resource Monitoring:**
```bash
# CPU and memory usage
htop

# Disk usage
df -h

# nginx logs
sudo tail -f /var/log/nginx/forms.abyz-lab.work-access.log
sudo tail -f /var/log/nginx/forms.abyz-lab.work-error.log

# cloudflared logs
sudo journalctl -u cloudflared -f
```

### Automated Monitoring (Optional)

**Setup Uptime Monitoring:**
1. Use Cloudflare **Uptime Checks** (available in Speed Analytics)
2. Configure external monitoring (e.g., UptimeRobot, Pingdom)
3. Alert on: downtime, SSL expiration, high error rates

**Example Cloudflare Uptime Check:**
- URL: `https://forms.abyz-lab.work/health`
- Frequency: Every 1 minute
- Regions: Global
- Alert: Email on failure

### Log Aggregation (Optional)

**Centralized Logging with Loki (Optional):**
```bash
# Install promtail on Raspberry Pi 5
sudo apt install promtail -y

# Configure promtail to send logs to Grafana Loki
# Monitor: nginx access logs, nginx error logs, cloudflared logs
```

### Maintenance Tasks

**Weekly:**
- Review Cloudflare analytics for anomalies
- Check nginx error logs for issues
- Verify SSL certificate expiration

**Monthly:**
- Review and update WAF rules
- Check cache hit ratios
- Audit form submissions for spam patterns
- Update Raspberry Pi 5 OS and packages:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

**Quarterly:**
- Review security configuration
- Performance optimization review
- Backup verification and testing
- Documentation updates

---

## Troubleshooting

### Issue 1: DNS Not Propagating

**Symptoms:**
- `dig forms.abyz-lab.work` returns NXDOMAIN
- Browser shows "This site can't be reached"

**Solutions:**
1. Verify DNS record exists in Cloudflare Dashboard
2. Check DNS record is proxied (orange cloud)
3. Wait for DNS propagation (up to 24 hours)
4. Clear local DNS cache:
   ```bash
   # Windows
   ipconfig /flushdns

   # macOS
   sudo dscacheutil -flushcache

   # Linux
   sudo systemd-resolve --flush-caches
   ```

### Issue 2: 502 Bad Gateway

**Symptoms:**
- Browser shows "502 Bad Gateway"
- Cloudflare error page

**Solutions:**
1. Check nginx is running:
   ```bash
   sudo systemctl status nginx
   ```

2. Verify nginx configuration:
   ```bash
   sudo nginx -t
   ```

3. Check nginx is listening on port 8080:
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

4. Check cloudflared tunnel is running:
   ```bash
   sudo systemctl status cloudflared
   ```

5. Review tunnel ingress rules in config.yml

### Issue 3: SSL Certificate Errors

**Symptoms:**
- Browser shows "Your connection is not private"
- SSL handshake errors

**Solutions:**
1. Verify SSL/TLS mode in Cloudflare:
   - Set to **Full (strict)**
   - Or use **Full** for testing

2. Check certificate on nginx:
   ```bash
   # For Let's Encrypt
   sudo certbot certificates

   # For Cloudflare Origin Certificate
   sudo ls -l /etc/cloudflare/
   ```

3. Restart nginx after certificate changes:
   ```bash
   sudo systemctl reload nginx
   ```

### Issue 4: Form Submission Fails

**Symptoms:**
- Form shows error message
- n8n workflow not triggered

**Solutions:**
1. Test n8n webhook directly:
   ```bash
   curl -X POST http://localhost:5678/webhook/form-submit \
     -H "Content-Type: application/json" \
     -d '{"name":"Test","email":"test@example.com","message":"Test"}'
   ```

2. Check nginx proxy configuration:
   ```bash
   # Verify /submit location block
   sudo cat /etc/nginx/sites-available/forms.abyz-lab.work
   ```

3. Check n8n workflow is active:
   - Access n8n dashboard
   - Verify workflow status is **Active**
   - Check webhook URL is correct

4. Review nginx error logs:
   ```bash
   sudo tail -50 /var/log/nginx/forms.abyz-lab.work-error.log
   ```

### Issue 5: High Latency

**Symptoms:**
- Form page loads slowly
- Form submission takes > 5 seconds

**Solutions:**
1. Check Cloudflare cache hit ratio:
   - Dashboard: **Caching** → **Analytics**
   - Aim for > 80% cache hit rate

2. Optimize static assets:
   - Minify CSS and JavaScript
   - Compress images
   - Use HTTP/2

3. Enable Cloudflare **Rocket Loader**:
   - Dashboard: **Speed** → **Optimization**
   - Toggle **Rocket Loader** to **ON**

4. Check Raspberry Pi 5 resources:
   ```bash
   htop
   # Check CPU and memory usage
   ```

5. Optimize nginx configuration:
   ```nginx
   # Enable gzip compression
   gzip on;
   gzip_types text/css application/javascript image/svg+xml;
   gzip_min_length 1000;
   ```

### Issue 6: WAF Blocking Legitimate Traffic

**Symptoms:**
- Legitimate users blocked
- Form submissions return 403

**Solutions:**
1. Review WAF logs:
   - Dashboard: **Security** → **WAF** → **Logs**
   - Identify triggered rules

2. Adjust WAF rules:
   - Reduce rate limit threshold
   - Disable overly aggressive rules
   - Add IP whitelist for legitimate users

3. Test form submission:
   ```bash
   # Test with WAF bypass (using curl)
   curl -X POST https://forms.abyz-lab.work/submit \
     -H "Content-Type: application/json" \
     -d '{"name":"Test","email":"test@example.com","message":"Test"}'
   ```

### Emergency Contacts

**Cloudflare Support:**
- Documentation: https://developers.cloudflare.com
- Community: https://community.cloudflare.com
- Twitter: @CloudflareSys

**Emergency Rollback:**
If critical issues occur, execute immediate rollback:
1. Delete DNS record
2. Stop nginx service
3. Remove tunnel ingress rule

---

## Appendix

### A. Configuration Files Reference

**Files Location:**
```
mcp-agent-server/
├── config/
│   ├── cloudflare-dns-config.json       # DNS record templates
│   ├── cloudflare-tunnel-config.yaml    # Tunnel ingress rules
│   └── nginx-forms.conf                 # nginx web server config
└── deployment/
    └── forms-subdomain-setup.md         # This document
```

**Raspberry Pi 5 Locations:**
```
~/.cloudflared/
├── config.yml                           # Tunnel configuration
├── [TUNNEL_ID].json                     # Tunnel credentials
└── [TUNNEL_ID].pem                      # Origin certificate

/etc/nginx/
├── sites-available/
│   └── forms.abyz-lab.work             # Site configuration
└── sites-enabled/
    └── forms.abyz-lab.work             # Symlink to sites-available

/var/www/forms.abyz-lab.work/
└── index.html                           # Form HTML
```

### B. Useful Commands

**Cloudflare CLI (deprecated but still useful):**
```bash
# List tunnels
cloudflared tunnel list

# Tunnel info
cloudflared tunnel info [TUNNEL_ID]

# Tunnel logs
cloudflared tunnel log [TUNNEL_ID]
```

**nginx Commands:**
```bash
# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# View error log
sudo tail -f /var/log/nginx/error.log
```

**Systemd Commands:**
```bash
# Check service status
sudo systemctl status cloudflared
sudo systemctl status nginx

# Restart service
sudo systemctl restart cloudflared
sudo systemctl restart nginx

# View service logs
sudo journalctl -u cloudflared -f
sudo journalctl -u nginx -f
```

### C. Security Checklist

- [ ] SSL/TLS set to **Full (Strict)**
- [ ] Bot Fight Mode enabled
- [ ] WAF rate limiting configured
- [ ] Security headers configured
- [ ] Cloudflare Access enabled (for admin endpoints)
- [ ] Regular security audits scheduled
- [ ] Incident response plan documented

### D. Performance Benchmarks

**Target Metrics:**
- Page load time: < 2 seconds
- Time to First Byte (TTFB): < 500ms
- Form submission response: < 1 second
- Cache hit ratio: > 80%
- Uptime: > 99.9%

**Monitoring Tools:**
- Cloudflare Analytics
- Cloudflare Speed Insights
- Raspberry Pi 5 system monitoring (htop)
- nginx access/error logs

### E. Cost Summary

**Monthly Costs:**
- Cloudflare Free Plan: **$0**
- Raspberry Pi 5 electricity: ~$2-5/month
- Domain registration: $10-15/year (~$1.25/month)

**Total Estimated Cost: $3-6/month**

**Optional Paid Features:**
- Cloudflare Pro: $20/month (additional WAF rules, image optimization)
- Cloudflare Workers: $5/month (for serverless form processing)

### F. Additional Resources

**Official Documentation:**
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)
- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/)
- [nginx Documentation](https://nginx.org/en/docs/)
- [n8n Documentation](https://docs.n8n.io/)

**Community Resources:**
- [Cloudflare Community](https://community.cloudflare.com/)
- [n8n Community](https://community.n8n.io/)
- [nginx Forum](https://forum.nginx.org/)

**Tutorial References:**
- [Submit a Static Website Form with Cloudflare Workers](https://dev.to/mattferderer/submit-a-static-website-form-with-cloudflare-workers-27hk)
- [Using Workers To Make Static Sites Dynamic](https://blog.cloudflare.com/using-workers-to-make-static-sites-dynamic/)

---

## Document Control

**Version:** 1.0.0
**Last Updated:** 2026-01-26
**Next Review:** 2026-04-26
**Author:** DevOps Team
**Status:** Production Ready

**Change Log:**

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-26 | 1.0.0 | Initial document creation | DevOps Team |

---

**End of Document**
