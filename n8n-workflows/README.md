# Issue Submission Workflows - Quick Start Guide

**Last Updated:** 2026-01-27
**Workflow Version:** 1.1.0

---

## Available Workflows

### 1. Issue Submission with Email (`issue-with-email.json)

**Purpose:** Receive form submissions and send direct email notification

**Workflow Structure:**
```
Form Input (forms.abyz-lab.work)
    ↓
n8n Webhook (/webhook/issue-submission)
    ↓
Direct Email Send (drake.lee@abyzr.com)
    ↓
Response to Webhook
```

**Configuration:**
- **From Email:** noreply@abyz-lab.work
- **To Email:** drake.lee@abyzr.com (direct, no forwarding)
- **Email Type:** HTML with styled template
- **Webhook Path:** `/issue-submission`

**Note:** This workflow sends emails directly to the recipient. The SMTP server configuration is managed separately in n8n credentials.

---

## Gmail SMTP Configuration Guide

### Overview

The `issue-with-email.json` workflow uses Gmail SMTP for sending emails. This guide will help you configure Gmail SMTP in n8n correctly.

### Prerequisites

- Gmail account with 2-Step Verification enabled
- Access to n8n web interface

### Step 1: Create Gmail App Password

Gmail requires an **App Password** instead of your regular password for SMTP access.

**Create App Password:**

1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **Security** → **2-Step Verification**
3. Ensure 2-Step Verification is enabled
4. Scroll to **App passwords** section
5. Click **Create** app password
6. Select:
   - **App:** Mail
   - **Device:** Other (Custom name) → Enter "n8n"
7. Click **Generate**
8. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

**Important:**
- Store this password securely
- You won't see it again after closing the window
- This is different from your Gmail password

### Step 2: Configure SMTP Credentials in n8n

1. Open n8n web interface
2. Navigate to **Credentials** → **Add Credential**
3. Select **SMTP** credential type
4. Configure with following settings:

```
Host: smtp.gmail.com
Port: 587
Security: TLS

Username: your-email@gmail.com
Password: (your 16-character App Password)

From Email: noreply@abyz-lab.work
```

5. Click **Save**
6. Test connection by sending a test email

### Step 3: Verify Workflow Configuration

In the `issue-with-email.json` workflow, verify the **Send Email** node:

```json
{
  "fromEmail": "noreply@abyz-lab.work",
  "toEmail": "drake.lee@abyzr.com",
  "subject": "=New Issue: {{ $json.title }}"
}
```

**Configuration Checklist:**

- [ ] SMTP credentials created and tested
- [ ] From email matches your domain or Gmail
- [ ] To email is correct recipient
- [ ] Security is set to TLS (Port 587) or SSL (Port 465)

### Step 4: Test Email Sending

```bash
curl -X POST http://your-n8n-url:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Email",
    "description": "Testing Gmail SMTP configuration"
  }'
```

**Expected Result:**
- Email arrives at recipient inbox
- Check Spam folder if not received
- Verify n8n execution log for success status

### Gmail Sending Limits

**Free Gmail Account:**
- **Daily Limit:** 500 emails per day
- **Recipient Limit:** 500 unique recipients per day
- **Rate Limit:** Prevents sending too quickly

**Google Workspace (Paid):**
- Daily limits vary by plan (1,500-2,000+ emails/day)
- Consider upgrading for higher volume

**If You Hit the Limit:**
- Wait 24 hours for limit to reset
- Consider using transactional email service (SendGrid, Mailgun)
- Distribute sending across multiple accounts

### Troubleshooting Gmail SMTP

#### Issue: Authentication Failed [AUTHENTICATIONFAILED]

**Cause:** Incorrect password or 2FA not enabled

**Solution:**
1. Verify 2-Step Verification is enabled
2. Regenerate App Password
3. Ensure no extra spaces in password
4. Check username is correct (full Gmail address)

#### Issue: Connection Timed Out

**Cause:** Firewall or incorrect port

**Solution:**
1. Verify port 587 (TLS) or 465 (SSL) is open
2. Check security setting matches port
3. Test connectivity: `telnet smtp.gmail.com 587`

#### Issue: Emails Go to Spam

**Cause:** Sender reputation or missing SPF/DKIM

**Solution:**
1. Use verified domain for fromEmail
2. Set up SPF record for your domain
3. Add recipient to contacts
4. Avoid spam trigger words in subject

#### Issue: "Less Secure Apps" Error

**Cause:** Google disabled less secure app access

**Solution:**
- You MUST use App Password (not regular password)
- Enable 2-Step Verification first
- Create App Password as shown in Step 1

### Security Best Practices

**Credential Security:**
- [ ] Never commit App Password to git
- [ ] Store in environment variables if possible
- [ ] Rotate App Passwords quarterly
- [ ] Use separate Gmail account for n8n

**Domain Configuration (if using custom domain):**
```
From Email: noreply@abyz-lab.work

SPF Record (DNS):
v=spf1 include:_spf.google.com ~all

DKIM: Generate key in Google Workspace
DMARC: Create policy record
```

### Alternative Email Services

If Gmail limits are insufficient, consider:

**Transactional Email Services:**
- **SendGrid:** 100 emails/day free
- **Mailgun:** 5,000 emails/month free
- **Amazon SES:** Pay-as-you-go ($0.10/1000 emails)
- **Brevo (Sendinblue):** 300 emails/day free

**Migration Guide:**
1. Create account with chosen service
2. Generate SMTP credentials
3. Update n8n SMTP credential with new host/port
4. Test workflow

---

## Issue Submission Workflow (Gitea/Redmine) - Setup Guide (5 Minutes)

### Step 1: Import Workflow into n8n

### Step 1: Import Workflow into n8n

1. Open n8n web interface
2. Click **Workflows** → **Import from File**
3. Select `issue-submission-workflow.json`
4. Click **Import**

### Step 2: Configure Environment Variables

Go to **Settings** → **Variables** and add:

```bash
# Gitea Configuration
GITEA_URL=https://git.example.com
GITEA_API_TOKEN=your_gitea_token_here
GITEA_OWNER=your_org_or_username
GITEA_REPO=your_repository_name

# Redmine Configuration
REDMINE_URL=https://projects.example.com
REDMINE_API_KEY=your_redmine_api_key_here
REDMINE_PROJECT_ID=123
REDMINE_TRACKER_ID=1
```

**Get Gitea API Token:**
1. Log in to Gitea
2. Settings → Applications → Generate Token
3. Select `repo` scope
4. Copy token

**Get Redmine API Key:**
1. Log in to Redmine
2. My account → API access key
3. Show & copy key

**Find Project/Tracker IDs:**
```bash
# List projects
curl https://projects.example.com/projects.json -H "X-Redmine-API-Key: YOUR_KEY"

# List trackers
curl https://projects.example.com/trackers.json -H "X-Redmine-API-Key: YOUR_KEY"
```

### Step 3: Activate Workflow

1. Open imported workflow
2. Click **Inactive** toggle to activate
3. Note the webhook URL displayed

### Step 4: Test Workflow

```bash
curl -X POST http://your-n8n-url:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Issue",
    "description": "Testing the workflow",
    "priority": "medium"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Issue created successfully in both Gitea and Redmine",
  "gitea_issue_url": "https://git.example.com/owner/repo/issues/1",
  "redmine_issue_url": "https://projects.example.com/issues/1",
  "errors": []
}
```

---

## Form Integration

### HTML Form Example

```html
<form id="issue-form">
  <input type="text" id="title" placeholder="Issue Title" required>
  <textarea id="description" placeholder="Description" required></textarea>
  <select id="priority">
    <option value="low">Low</option>
    <option value="medium" selected>Medium</option>
    <option value="high">High</option>
    <option value="critical">Critical</option>
  </select>
  <input type="text" id="labels" placeholder="Labels (comma-separated)">
  <input type="text" id="assignee" placeholder="Assignee Username">
  <input type="number" id="estimated_time" placeholder="Estimated Hours">
  <input type="file" id="attachments" multiple>
  <button type="submit">Submit Issue</button>
</form>

<script>
const form = document.getElementById('issue-form');
const webhookUrl = 'http://your-n8n-url:5678/webhook/issue-submission';

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const formData = {
    title: document.getElementById('title').value,
    description: document.getElementById('description').value,
    priority: document.getElementById('priority').value,
    labels: document.getElementById('labels').value.split(',').map(s => s.trim()).filter(Boolean),
    assignee: document.getElementById('assignee').value || null,
    estimated_time: parseFloat(document.getElementById('estimated_time').value) || null,
    attachments: []
  };

  // Handle file attachments
  const fileInput = document.getElementById('attachments');
  for (const file of fileInput.files) {
    const base64 = await fileToBase64(file);
    formData.attachments.push({
      filename: file.name,
      content_type: file.type,
      data: base64
    });
  }

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });

    const result = await response.json();

    if (result.success) {
      alert(`Issue created!\nGitea: ${result.gitea_issue_url}\nRedmine: ${result.redmine_issue_url}`);
      form.reset();
    } else {
      alert(`Failed: ${result.message}\nErrors: ${result.errors.join(', ')}`);
    }
  } catch (error) {
    alert(`Error: ${error.message}`);
  }
});

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result.split(',')[1]);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
</script>
```

### JavaScript/TypeScript Example

```typescript
interface IssueSubmission {
  title: string;
  description: string;
  priority?: 'low' | 'medium' | 'high' | 'critical';
  labels?: string[];
  assignee?: string;
  milestone?: string;
  estimated_time?: number;
  progress?: number;
  attachments?: Array<{
    filename: string;
    content_type: string;
    data: string; // base64 encoded
  }>;
  related_issues?: string[];
}

interface IssueResponse {
  success: boolean;
  message: string;
  gitea_issue_url: string | null;
  redmine_issue_url: string | null;
  errors: string[];
  timestamp: string;
}

async function submitIssue(data: IssueSubmission): Promise<IssueResponse> {
  const webhookUrl = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/issue-submission';

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json();
}

// Usage
const issue = await submitIssue({
  title: 'Bug: Login page crashes',
  description: 'Steps to reproduce...',
  priority: 'high',
  labels: ['bug', 'urgent'],
  assignee: 'john_doe',
  estimated_time: 4
});

console.log(`Created: ${issue.gitea_issue_url}`);
```

---

## Testing Checklist

### ✅ Basic Functionality

- [ ] Workflow activates successfully
- [ ] Webhook receives POST requests
- [ ] Validation works (test with empty title)
- [ ] Valid data creates issues in both systems
- [ ] Response includes correct issue URLs

### ✅ Gitea Integration

- [ ] Issue appears in Gitea repository
- [ ] Title, description, labels set correctly
- [ ] Assignee assigned (if specified)
- [ ] Milestone set (if specified)

### ✅ Redmine Integration

- [ ] Issue appears in Redmine project
- [ ] Subject, description set correctly
- [ ] Priority mapped correctly
- [ ] Estimated time and progress saved

### ✅ Error Handling

- [ ] Invalid Gitea token returns error
- [ ] Invalid Redmine key returns error
- [ ] Missing required fields return validation error
- [ ] Partial success (one system fails) works correctly

### ✅ Attachments

- [ ] Small file (<1MB) uploads successfully
- [ ] Multiple files upload correctly
- [ ] Invalid base64 returns error
- [ ] File size limits enforced

---

## Troubleshooting

### Issue: Webhook Not Receiving Data

**Test:**
```bash
curl -v -X POST http://localhost:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "description": "Test"}'
```

**Fix:**
- Check n8n is running: `docker ps` or `ps aux | grep n8n`
- Verify webhook path matches: `/issue-submission`
- Check firewall allows port 5678

### Issue: 401 Unauthorized from Gitea

**Test:**
```bash
curl -v https://git.example.com/api/v1/user \
  -H "Authorization: token YOUR_TOKEN"
```

**Fix:**
- Regenerate API token in Gitea
- Verify token has `repo` scope
- Check GITEA_URL environment variable

### Issue: 401 Unauthorized from Redmine

**Test:**
```bash
curl -v https://projects.example.com/issues.json \
  -H "X-Redmine-API-Key: YOUR_KEY"
```

**Fix:**
- Regenerate API key in Redmine
- Verify user has issue creation permissions
- Check REDMINE_URL environment variable

### Issue: Issues Not Created

**Debug Steps:**
1. Check n8n execution logs
2. Enable debug mode: `N8N_LOG_LEVEL=debug`
3. Test API endpoints manually with curl
4. Verify project/tracker IDs are correct

---

## Monitoring

### View Execution History

1. n8n UI → Executions
2. Filter by workflow name
3. Check success/failure rates

### Key Metrics

- **Success Rate:** Should be >99%
- **Execution Time:** <5 seconds (no attachments)
- **Error Rate:** <1%

### Set Up Alerts

1. n8n Settings → Workflow Settings
2. Enable "Error Workflow"
3. Create error notification workflow:
```javascript
// Send to Slack/Email/Webhook on error
return [{
  json: {
    text: `Workflow Error: ${$node['Form Submission Webhook'].json.workflow.name}`,
    error: $execution.error,
    timestamp: new Date().toISOString()
  }
}];
```

---

## Advanced Configuration

### Enable Retry Logic

For production use, enable automatic retries:

1. Workflow Settings → Workflow Settings
2. Enable "Error Workflow"
3. Set retry count: 3
4. Set retry delay: 1000ms (exponential backoff)

### Customize Priority Mapping

Edit "Create Redmine Issue" node:

```javascript
// Default mapping (Redmine priority IDs)
priority_id: $json.data.priority === 'critical' ? 6 :  // Urgent
             $json.data.priority === 'high' ? 5 :      // High
             $json.data.priority === 'medium' ? 4 :    // Normal
             3                                          // Low
```

Adjust IDs based on your Redmine configuration.

### Add Custom Fields

For Redmine custom fields:

```javascript
"custom_fields": [
  {
    "id": 1,  // Custom field ID
    "value": "custom_value"
  },
  {
    "id": 2,
    "value": "another_value"
  }
]
```

Find custom field IDs:
```bash
curl https://projects.example.com/custom_fields.json \
  -H "X-Redmine-API-Key: YOUR_KEY"
```

---

## Production Deployment

### Docker Compose

```yaml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_password
      - WEBHOOK_URL=https://n8n.yourdomain.com
      - GITEA_URL=${GITEA_URL}
      - GITEA_API_TOKEN=${GITEA_API_TOKEN}
      - GITEA_OWNER=${GITEA_OWNER}
      - GITEA_REPO=${GITEA_REPO}
      - REDMINE_URL=${REDMINE_URL}
      - REDMINE_API_KEY=${REDMINE_API_KEY}
      - REDMINE_PROJECT_ID=${REDMINE_PROJECT_ID}
      - REDMINE_TRACKER_ID=${REDMINE_TRACKER_ID}
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped

volumes:
  n8n_data:
```

**Deploy:**
```bash
docker-compose up -d
```

### Security Checklist

- [ ] Enable HTTPS (use reverse proxy: nginx/traefik)
- [ ] Set strong admin password
- [ ] Restrict webhook to known IPs
- [ ] Rotate API keys monthly
- [ ] Enable n8n execution logs
- [ ] Regular backup of n8n database

---

## Support

**Documentation:** See `issue-submission-workflow.md`
**Issues:** Create GitHub issue
**Discussions:** Use project forum

---

**Quick Start Version:** 1.0.0
**Compatible:** n8n v1.0.0+, Gitea v1.18+, Redmine v4.2+
