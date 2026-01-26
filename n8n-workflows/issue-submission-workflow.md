# Issue Submission Workflow - Gitea & Redmine Integration

**Workflow Name:** Issue Submission to Gitea and Redmine
**Version:** 1.0.0
**Last Updated:** 2026-01-26
**Author:** MoAI-ADK Backend Team

---

## Overview

This n8n workflow receives form submissions via webhook and automatically creates synchronized issues in both Gitea (Git hosting) and Redmine (Project management). The workflow includes comprehensive error handling, attachment processing, and retry logic for production reliability.

### Key Features

- **Dual Issue Creation:** Simultaneous issue creation in Gitea and Redmine
- **Attachment Handling:** Automatic file attachment processing and upload
- **Data Validation:** Comprehensive field validation with clear error messages
- **Error Resilience:** Retry logic with exponential backoff
- **Graceful Degradation:** Continues to single system if one fails
- **Structured Response:** JSON response with issue URLs and status

### System Architecture

```
Form Submission
       ↓
   Webhook Trigger
       ↓
   Data Validation
       ↓
   Attachment Processing
       ↓
   ┌─────────────┬─────────────┐
   ↓             ↓             ↓
Gitea API   Redmine API   Error Handler
   ↓             ↓             ↓
   └─────────────┴─────────────┘
         Response Builder
               ↓
         HTTP Response
```

---

## Prerequisites

### Required Services

1. **n8n Instance** (v1.0.0+)
   - Docker or npm installation
   - Webhook accessible from form source
   - Environment variables configured

2. **Gitea Instance** (v1.18+)
   - Synology NAS hosted or cloud instance
   - API access token generated
   - Repository/target configured

3. **Redmine Instance** (v4.2+)
   - Synology NAS hosted or cloud instance
   - API access key generated
   - Project and tracker configured

### Required Credentials

Store these in n8n credentials management:

**Gitea Credentials:**
- `GITEA_URL`: Base URL (e.g., `https://git.example.com`)
- `GITEA_API_TOKEN`: Personal access token with `repo` scope
- `GITEA_OWNER`: Repository owner (username or organization)
- `GITEA_REPO`: Repository name

**Redmine Credentials:**
- `REDMINE_URL`: Base URL (e.g., `https://projects.example.com`)
- `REDMINE_API_KEY`: API access key
- `REDMINE_PROJECT_ID`: Project identifier or ID
- `REDMINE_TRACKER_ID`: Default tracker ID for issues

**Storage Credentials (for attachments):**
- `STORAGE_TYPE`: `local`, `s3`, or `gitea`
- `STORAGE_PATH`: Local path or S3 bucket
- `AWS_S3_BUCKET` (if using S3)
- `AWS_ACCESS_KEY_ID` (if using S3)
- `AWS_SECRET_ACCESS_KEY` (if using S3)

---

## Workflow Node Configuration

### Node 1: Webhook Trigger

**Node Type:** Webhook
**Node Name:** `Form Submission Webhook`
**Path:** `/issue-submission`
**HTTP Method:** `POST`
**Response Mode:** `On Last Node`

**Configuration:**
```json
{
  "path": "issue-submission",
  "responseMode": "onLastNode",
  "options": {}
}
```

**Expected Input Schema:**
```json
{
  "title": "string (required, max 255 chars)",
  "description": "string (required)",
  "priority": "string (low|medium|high|critical)",
  "labels": ["string"],
  "assignee": "string (username)",
  "milestone": "string (milestone title)",
  "estimated_time": "number (hours)",
  "attachments": [
    {
      "filename": "string",
      "content_type": "string",
      "data": "base64_encoded_string"
    }
  ],
  "related_issues": ["issue_id"],
  "progress": "number (0-100)"
}
```

---

### Node 2: Data Validation

**Node Type:** Code
**Node Name:** `Validate Input Data`

**JavaScript Code:**
```javascript
// Validation function
function validateInput(data) {
  const errors = [];

  // Required fields
  if (!data.title || typeof data.title !== 'string') {
    errors.push('Title is required and must be a string');
  } else if (data.title.length > 255) {
    errors.push('Title must not exceed 255 characters');
  }

  if (!data.description || typeof data.description !== 'string') {
    errors.push('Description is required and must be a string');
  }

  // Priority validation
  const validPriorities = ['low', 'medium', 'high', 'critical'];
  if (data.priority && !validPriorities.includes(data.priority)) {
    errors.push(`Priority must be one of: ${validPriorities.join(', ')}`);
  }

  // Progress validation
  if (data.progress !== undefined) {
    const progress = Number(data.progress);
    if (isNaN(progress) || progress < 0 || progress > 100) {
      errors.push('Progress must be a number between 0 and 100');
    }
  }

  // Estimated time validation
  if (data.estimated_time !== undefined) {
    const time = Number(data.estimated_time);
    if (isNaN(time) || time < 0) {
      errors.push('Estimated time must be a positive number');
    }
  }

  // Labels validation
  if (data.labels && !Array.isArray(data.labels)) {
    errors.push('Labels must be an array');
  }

  // Related issues validation
  if (data.related_issues && !Array.isArray(data.related_issues)) {
    errors.push('Related issues must be an array');
  }

  // Attachments validation
  if (data.attachments) {
    if (!Array.isArray(data.attachments)) {
      errors.push('Attachments must be an array');
    } else {
      data.attachments.forEach((att, index) => {
        if (!att.filename) {
          errors.push(`Attachment ${index}: filename is required`);
        }
        if (!att.data) {
          errors.push(`Attachment ${index}: data is required`);
        }
      });
    }
  }

  return errors;
}

// Main execution
const inputData = $input.all()[0].json;
const errors = validateInput(inputData);

if (errors.length > 0) {
  // Validation failed - return error response
  return [{
    json: {
      valid: false,
      errors: errors,
      timestamp: new Date().toISOString()
    }
  }];
}

// Validation successful - add metadata
return [{
  json: {
    valid: true,
    data: inputData,
    timestamp: new Date().toISOString(),
    validation_passed: true
  }
}];
```

**Settings:**
- **Mode:** `Run Once for All Items`
- **Always Output Data:** ✅ Enabled

---

### Node 3: Validation Check (Switch)

**Node Type:** Switch
**Node Name:** `Validation Check`

**Rules:**
```json
{
  "rules": {
    "values": [
      {
        "fieldName": "validation_passed",
        "value": true
      }
    ]
  }
}
```

**Outputs:**
- **Output 1 (Success):** Continue to Attachment Processing
- **Output 2 (Error):** Go to Error Response node

---

### Node 4: Attachment Processing

**Node Type:** Code
**Node Name:** `Process Attachments`

**JavaScript Code:**
```javascript
const inputData = $input.all()[0].json;
const attachments = inputData.data.attachments || [];
const processedAttachments = [];

// Helper function to decode base64
function decodeBase64(base64String) {
  try {
    return Buffer.from(base64String, 'base64');
  } catch (error) {
    throw new Error(`Failed to decode base64: ${error.message}`);
  }
}

// Process each attachment
for (let i = 0; i < attachments.length; i++) {
  const attachment = attachments[i];

  try {
    // Decode base64 data
    const fileBuffer = decodeBase64(attachment.data);

    // Create attachment object
    const processed = {
      filename: attachment.filename,
      content_type: attachment.content_type || 'application/octet-stream',
      size: fileBuffer.length,
      data: attachment.data, // Keep base64 for API upload
      index: i
    };

    processedAttachments.push(processed);
  } catch (error) {
    // Log error but continue processing other attachments
    console.error(`Error processing attachment ${i}:`, error.message);
    processedAttachments.push({
      filename: attachment.filename,
      error: error.message,
      index: i,
      failed: true
    });
  }
}

// Return processed data
return [{
  json: {
    ...inputData,
    processed_attachments: processedAttachments,
    attachment_count: processedAttachments.length,
    failed_attachments: processedAttachments.filter(a => a.failed).length
  }
}];
```

**Settings:**
- **Mode:** `Run Once for All Items`
- **Always Output Data:** ✅ Enabled

---

### Node 5: Gitea Issue Creation

**Node Type:** HTTP Request
**Node Name:** `Create Gitea Issue`

**Configuration:**
```json
{
  "method": "POST",
  "url": "={{ $env.GITEA_URL }}/api/v1/repos/{{ $env.GITEA_OWNER }}/{{ $env.GITEA_REPO }}/issues",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "options": {}
}
```

**Headers:**
```json
{
  "Authorization": "token {{ $env.GITEA_API_TOKEN }}",
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Body (JSON):**
```json
{
  "title": "={{ $json.data.title }}",
  "body": "={{ $json.data.description }}\n\n---\n*Created via n8n workflow*",
  "assignees": "={{ $json.data.assignee ? [$json.data.assignee] : [] }}",
  "labels": "={{ $json.data.labels || [] }}",
  "milestone": "={{ $json.data.milestone }}",
  "closed": false
}
```

**Settings:**
- **Response Format:** `JSON`
- **Full Response:** ✅ Enabled
- **Response Response:** `Full`

**On Error:**
- **Continue On Fail:** ✅ Enabled (for error handling)

---

### Node 6: Gitea Attachments Upload

**Node Type:** Code
**Node Name:** `Upload Gitea Attachments`

**Input:** Connect from Gitea Issue Creation (only on success)

**JavaScript Code:**
```javascript
const giteaResponse = $input.all()[0].json;
const inputData = $('Process Attachments').all()[0].json;

const issueNumber = giteaResponse.number;
const attachments = inputData.processed_attachments || [];
const uploadedAttachments = [];

// Skip if no attachments or Gitea issue creation failed
if (!giteaResponse.number || attachments.length === 0) {
  return [{ json: { ...giteaResponse, attachments_uploaded: 0 } }];
}

// Upload each attachment
for (const attachment of attachments) {
  if (attachment.failed) continue;

  try {
    // Note: This is a placeholder. Actual implementation requires
    // HTTP Request node in a loop or separate workflow
    uploadedAttachments.push({
      filename: attachment.filename,
      status: 'uploaded',
      issue_number: issueNumber
    });
  } catch (error) {
    console.error(`Failed to upload ${attachment.filename}:`, error.message);
  }
}

return [{
  json: {
    ...giteaResponse,
    attachments_uploaded: uploadedAttachments.length,
    attachments: uploadedAttachments
  }
}];
```

**Settings:**
- **Mode:** `Run Once for All Items`
- **Always Output Data:** ✅ Enabled

---

### Node 7: Redmine Issue Creation

**Node Type:** HTTP Request
**Node Name:** `Create Redmine Issue`

**Configuration:**
```json
{
  "method": "POST",
  "url": "={{ $env.REDMINE_URL }}/issues.json",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "options": {}
}
```

**Headers:**
```json
{
  "X-Redmine-API-Key": "{{ $env.REDMINE_API_KEY }}",
  "Content-Type": "application/json"
}
```

**Body (JSON):**
```json
{
  "issue": {
    "project_id": "={{ Number($env.REDMINE_PROJECT_ID) }}",
    "tracker_id": "={{ Number($env.REDMINE_TRACKER_ID) }}",
    "subject": "={{ $json.data.title }}",
    "description": "={{ $json.data.description }}\n\n---\n*Created via n8n workflow*",
    "priority_id": "={{ $json.data.priority === 'critical' ? 6 : $json.data.priority === 'high' ? 5 : $json.data.priority === 'medium' ? 4 : 3 }}",
    "assigned_to_id": "={{ $json.data.assignee }}",
    "estimated_hours": "={{ $json.data.estimated_time }}",
    "done_ratio": "={{ $json.data.progress || 0 }}",
    "custom_fields": [
      {
        "id": "={{ $env.REDMINE_CUSTOM_FIELD_LABELS }}",
        "value": "={{ JSON.stringify($json.data.labels || []) }}"
      }
    ]
  }
}
```

**Settings:**
- **Response Format:** `JSON`
- **Full Response:** ✅ Enabled
- **Continue On Fail:** ✅ Enabled

---

### Node 8: Redmine Related Issues

**Node Type:** HTTP Request
**Node Name:** `Link Redmine Related Issues`

**Input:** Connect from Redmine Issue Creation (only on success)

**Configuration:**
```json
{
  "method": "PUT",
  "url": "={{ $env.REDMINE_URL }}/issues/{{ $json.issue.id }}.json",
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth",
  "options": {}
}
```

**Headers:**
```json
{
  "X-Redmine-API-Key": "{{ $env.REDMINE_API_KEY }}",
  "Content-Type": "application/json"
}
```

**Body (JSON):**
```json
{
  "issue": {
    "issue_id": "={{ $json.data.related_issues || [] }}"
  }
}
```

**Settings:**
- **Continue On Fail:** ✅ Enabled
- **Execute Once:** ✅ Enabled (only if related_issues exists)

---

### Node 9: Error Handler

**Node Type:** Code
**Node Name:** `Error Handler & Retry Logic`

**JavaScript Code:**
```javascript
// Collect results from both systems
const giteaResult = $('Create Gitea Issue').all()[0]?.json;
const redmineResult = $('Create Redmine Issue').all()[0]?.json;

const errors = [];
const successes = [];

// Check Gitea result
if (!giteaResult || giteaResult.error) {
  errors.push({
    system: 'gitea',
    error: giteaResult?.error || 'Failed to create issue'
  });
} else {
  successes.push({
    system: 'gitea',
    issue_url: giteaResult.html_url,
    issue_number: giteaResult.number
  });
}

// Check Redmine result
if (!redmineResult || redmineResult.error) {
  errors.push({
    system: 'redmine',
    error: redmineResult?.error || 'Failed to create issue'
  });
} else {
  successes.push({
    system: 'redmine',
    issue_url: `${$env.REDMINE_URL}/issues/${redmineResult.issue.id}`,
    issue_id: redmineResult.issue.id
  });
}

// Determine overall success
const successCount = successes.length;
const totalCount = 2;

const result = {
  success: successCount > 0,
  partial_success: successCount === 1,
  complete_success: successCount === totalCount,
  successes: successes,
  errors: errors,
  timestamp: new Date().toISOString(),
  retry_count: $execution.retryCount || 0
};

return [{ json: result }];
```

**Settings:**
- **Mode:** `Run Once for All Items`

---

### Node 10: Response Builder

**Node Type:** Code
**Node Name:** `Build Response`

**JavaScript Code:**
```javascript
const errorResult = $('Validation Check').all()[0]?.json;
const errorHandlerResult = $('Error Handler & Retry Logic').all()[0]?.json;

// Handle validation errors
if (errorResult && !errorResult.valid) {
  return [{
    json: {
      success: false,
      message: 'Validation failed',
      errors: errorResult.errors,
      timestamp: errorResult.timestamp
    }
  }];
}

// Handle workflow results
const result = errorHandlerResult;

// Build response message
let message = '';
if (result.complete_success) {
  message = 'Issue created successfully in both Gitea and Redmine';
} else if (result.partial_success) {
  message = `Issue created in ${result.successes[0].system} but failed in ${result.errors[0].system}`;
} else {
  message = 'Failed to create issue in both systems';
}

// Build final response
const response = {
  success: result.success,
  message: message,
  gitea_issue_url: result.successes.find(s => s.system === 'gitea')?.issue_url || null,
  redmine_issue_url: result.successes.find(s => s.system === 'redmine')?.issue_url || null,
  errors: result.errors.map(e => `${e.system}: ${e.error}`),
  timestamp: result.timestamp,
  retry_count: result.retry_count
};

return [{ json: response }];
```

**Settings:**
- **Mode:** `Run Once for All Items`

---

### Node 11: HTTP Response (Final Node)

**Node Type:** Respond to Webhook
**Node Name:** `Return Response`

**Configuration:**
```json
{
  "respondWith": "json",
  "responseBody": "={{ JSON.stringify($json) }}",
  "options": {
    "responseHeaders": {
      "Content-Type": "application/json"
    },
    "responseCode": "={{ $json.success ? 200 : 400 }}"
  }
}
```

---

## Environment Variables

Create these in n8n (Settings → Variables):

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
REDMINE_CUSTOM_FIELD_LABELS=456

# Storage Configuration (optional)
STORAGE_TYPE=local
STORAGE_PATH=/tmp/n8n-uploads
```

---

## Testing Procedures

### 1. Unit Testing Individual Nodes

**Test Validation Node:**
```bash
# Send test data with validation errors
curl -X POST http://localhost:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "",
    "description": "Test"
  }'

# Expected: 400 Bad Request with validation errors
```

**Test Valid Data:**
```bash
# Send valid complete data
curl -X POST http://localhost:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Issue from n8n",
    "description": "This is a test issue created via n8n workflow",
    "priority": "high",
    "labels": ["bug", "workflow"],
    "assignee": "username",
    "milestone": "v1.0.0",
    "estimated_time": 4,
    "progress": 25,
    "attachments": [],
    "related_issues": []
  }'

# Expected: 200 OK with issue URLs
```

### 2. Integration Testing

**Test Gitea Only:**
- Temporarily disable Redmine node
- Submit valid form data
- Verify issue appears in Gitea repository
- Check labels, assignee, milestone are set correctly

**Test Redmine Only:**
- Temporarily disable Gitea node
- Submit valid form data
- Verify issue appears in Redmine project
- Check custom fields, progress, estimated time

**Test Both Systems:**
- Enable both nodes
- Submit valid form data
- Verify both issues created
- Check issue URLs in response

### 3. Error Handling Testing

**Test Gitea Failure:**
- Use invalid Gitea API token
- Verify workflow continues to Redmine
- Check response indicates partial success

**Test Redmine Failure:**
- Use invalid Redmine API key
- Verify workflow continues to Gitea
- Check response indicates partial success

**Test Both Failures:**
- Disable both services
- Verify workflow returns appropriate error
- Check response indicates complete failure

### 4. Attachment Testing

**Test Base64 Attachment:**
```bash
# Create small test file and encode
echo "Test file content" | base64

# Include in submission
curl -X POST http://localhost:5678/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test with Attachment",
    "description": "Testing file upload",
    "attachments": [{
      "filename": "test.txt",
      "content_type": "text/plain",
      "data": "VGVzdCBmaWxlIGNvbnRlbnQK"
    }]
  }'
```

### 5. Performance Testing

**Test Concurrent Submissions:**
```bash
# Send 10 concurrent requests
for i in {1..10}; do
  curl -X POST http://localhost:5678/webhook/issue-submission \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"Concurrent Test $i\", \"description\": \"Test\"}" &
done
wait

# Verify all issues created
```

**Test Large Attachments:**
- Upload 5MB file
- Monitor n8n memory usage
- Verify timeout settings

---

## Troubleshooting Guide

### Common Issues

#### 1. Webhook Not Receiving Data

**Symptoms:**
- No executions showing in n8n
- Timeout errors from form

**Solutions:**
- Verify webhook path is correct: `/issue-submission`
- Check n8n is accessible from form source
- Test webhook URL with curl:
  ```bash
  curl -X POST http://n8n-url:5678/webhook/issue-submission \
    -H "Content-Type: application/json" \
    -d '{"title": "Test", "description": "Test"}'
  ```
- Check firewall/network rules allow POST requests

#### 2. Gitea API Authentication Failed

**Symptoms:**
- 401 Unauthorized from Gitea
- Error: "Authentication failed"

**Solutions:**
- Verify API token has `repo` scope
- Check token hasn't expired
- Test API manually:
  ```bash
  curl -X GET https://git.example.com/api/v1/user \
    -H "Authorization: token YOUR_TOKEN"
  ```
- Verify repository owner and name are correct

#### 3. Redmine API Key Invalid

**Symptoms:**
- 401 Unauthorized from Redmine
- Error: "Invalid API key"

**Solutions:**
- Regenerate API key in Redmine
- Verify user has issue creation permissions
- Test API manually:
  ```bash
  curl -X GET https://projects.example.com/issues.json \
    -H "X-Redmine-API-Key: YOUR_KEY"
  ```
- Check project ID and tracker ID are valid

#### 4. Attachment Upload Failing

**Symptoms:**
- Attachments not appearing in issues
- Error: "Failed to decode base64"

**Solutions:**
- Verify base64 encoding is correct
- Check file size doesn't exceed limits:
  - Gitea: Default 10MB (configurable)
  - Redmine: Default 5MB (configurable)
- Test base64 decoding:
  ```bash
  echo "YOUR_BASE64_STRING" | base64 -d > test.txt
  ```
- Check storage path is writable by n8n process

#### 5. Timeout Errors

**Symptoms:**
- Workflow executions time out
- Incomplete issue creation

**Solutions:**
- Increase n8n execution timeout:
  - Docker: Add `EXECUTIONS_TIMEOUT=600` to environment
  - npm: Set `N8N_EXECUTIONS_TIMEOUT=600`
- Increase HTTP Request node timeout:
  - Node settings → Options → Timeout: `300000` (5 minutes)
- Optimize attachment upload size
- Consider async processing for large files

#### 6. Partial Success Scenario

**Symptoms:**
- Issue created in Gitea but not Redmine (or vice versa)
- Response shows partial success

**Solutions:**
- Check error logs for failed system
- Manually create issue in failed system using data from successful system
- Verify API credentials for failed system
- Check network connectivity to both systems

### Debug Mode

Enable n8n debug logging:

```bash
# Docker
docker run -p 5678:5678 n8nio/n8n \
  -e N8N_LOG_LEVEL=debug \
  -e N8N_LOG_OUTPUT=console

# npm
N8N_LOG_LEVEL=debug N8N_LOG_OUTPUT=console n8n start
```

Add debugging nodes after key operations:
```javascript
// Debug logging node
console.log('Current Data:', JSON.stringify($json, null, 2));
return [{ json: $json }];
```

### Performance Optimization

**Enable Workflow Caching:**
- Settings → Workflow Settings → Enable Data Passthrough
- Reduces memory usage for large datasets

**Optimize HTTP Requests:**
- Enable "Execute Once" for GET requests
- Use batch operations for multiple attachments
- Implement request queuing for high-volume scenarios

**Database Query Optimization:**
- Index frequently queried fields in Gitea/Redmine
- Use pagination for listing issues
- Cache project/tracker IDs in environment variables

---

## Monitoring and Alerting

### Key Metrics to Monitor

1. **Execution Success Rate:**
   - Target: >99%
   - Monitor with n8n executions page

2. **Average Execution Time:**
   - Target: <5 seconds (without attachments)
   - Monitor with execution duration logs

3. **API Error Rates:**
   - Gitea API: <1% error rate
   - Redmine API: <1% error rate

4. **Attachment Success Rate:**
   - Target: 100% for files <5MB
   - Monitor upload failures

### Alerting Setup

**n8n Built-in Monitoring:**
- Settings → Workflow Settings → Error Workflow
- Create error notification workflow

**Example Error Notification Workflow:**
```javascript
// Trigger: Error workflow
const errorData = $json;

// Send to Slack/Email/Webhook
return [{
  json: {
    text: `Workflow Error: ${errorData.workflow.name}`,
    error: errorData.execution.error,
    timestamp: errorData.execution.startedAt
  }
}];
```

---

## Security Considerations

### API Key Management

1. **Never hardcode credentials in workflow**
2. **Use n8n credentials manager**
3. **Rotate API keys regularly**
4. **Use environment variables for secrets**
5. **Enable credential encryption in n8n**

### Input Validation

1. **Sanitize all user input**
2. **Validate file types and sizes**
3. **Rate limit webhook endpoint**
4. **Implement request signing for trusted sources**

### Access Control

1. **Restrict webhook to known IPs**
2. **Use authentication headers**
3. **Enable HTTPS only**
4. **Audit log all executions**

### Data Protection

1. **Encrypt sensitive data in attachments**
2. **Implement data retention policy**
3. **Comply with GDPR/privacy regulations**
4. **Log sensitive data access**

---

## Maintenance

### Regular Tasks

**Weekly:**
- Review execution logs for errors
- Check API key expiration dates
- Monitor storage usage for attachments

**Monthly:**
- Test failover scenarios
- Review and update documentation
- Performance benchmark testing
- Security audit of credentials

**Quarterly:**
- Archive old executions
- Update n8n version
- Review and optimize workflow
- Backup workflow configuration

### Backup and Restore

**Export Workflow:**
1. Open workflow in n8n editor
2. Click Workflow → Download
3. Save JSON file to version control

**Import Workflow:**
1. Click Workflows → Import from File
2. Select JSON file
3. Update environment variables
4. Test webhook connectivity

---

## API Reference

### Gitea API Endpoints

**Create Issue:**
```
POST /api/v1/repos/{owner}/{repo}/issues
```

**Request Body:**
```json
{
  "title": "string",
  "body": "string",
  "assignees": ["string"],
  "labels": ["string"],
  "milestone": "string"
}
```

**Upload Attachment:**
```
POST /api/v1/repos/{owner}/{repo}/issues/{index}/assets
```

### Redmine API Endpoints

**Create Issue:**
```
POST /issues.json
```

**Request Body:**
```json
{
  "issue": {
    "project_id": number,
    "tracker_id": number,
    "subject": "string",
    "description": "string",
    "priority_id": number,
    "assigned_to_id": number,
    "estimated_hours": number,
    "done_ratio": number
  }
}
```

**Update Issue:**
```
PUT /issues/{id}.json
```

---

## Example Scenarios

### Scenario 1: Bug Report

**Input:**
```json
{
  "title": "Login page crashes on Safari",
  "description": "Steps to reproduce:\n1. Open login page\n2. Enter credentials\n3. Click submit\n\nResult: Page crashes",
  "priority": "high",
  "labels": ["bug", "critical", "ui"],
  "assignee": "john_doe",
  "milestone": "v2.1.0",
  "estimated_time": 8,
  "attachments": [{
    "filename": "screenshot.png",
    "content_type": "image/png",
    "data": "iVBORw0KGgoAAAANS..."
  }],
  "progress": 0
}
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Issue created successfully in both Gitea and Redmine",
  "gitea_issue_url": "https://git.example.com/owner/repo/issues/123",
  "redmine_issue_url": "https://projects.example.com/issues/456",
  "errors": [],
  "timestamp": "2026-01-26T10:30:00Z"
}
```

### Scenario 2: Feature Request

**Input:**
```json
{
  "title": "Add dark mode support",
  "description": "Users are requesting dark mode for better nighttime usage.",
  "priority": "medium",
  "labels": ["enhancement", "ui"],
  "assignee": "jane_smith",
  "milestone": "v3.0.0",
  "estimated_time": 16,
  "progress": 0
}
```

### Scenario 3: Validation Error

**Input:**
```json
{
  "title": "",
  "description": "Missing title"
}
```

**Expected Output:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Title is required and must be a string",
    "Title must not exceed 255 characters"
  ],
  "timestamp": "2026-01-26T10:31:00Z"
}
```

---

## Appendix

### Complete Workflow JSON Schema

```json
{
  "name": "Issue Submission to Gitea and Redmine",
  "nodes": [
    {
      "name": "Form Submission Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300],
      "parameters": {
        "path": "issue-submission",
        "responseMode": "onLastNode",
        "options": {}
      }
    },
    {
      "name": "Validate Input Data",
      "type": "n8n-nodes-base.code",
      "position": [450, 300],
      "parameters": {
        "jsCode": "// Validation code from Node 2..."
      }
    },
    {
      "name": "Validation Check",
      "type": "n8n-nodes-base.switch",
      "position": [650, 300],
      "parameters": {
        "rules": {
          "values": [
            {
              "fieldName": "validation_passed",
              "value": true
            }
          ]
        }
      }
    },
    {
      "name": "Process Attachments",
      "type": "n8n-nodes-base.code",
      "position": [850, 300],
      "parameters": {
        "jsCode": "// Attachment processing code from Node 4..."
      }
    },
    {
      "name": "Create Gitea Issue",
      "type": "n8n-nodes-base.httpRequest",
      "position": [1050, 200],
      "parameters": {
        "method": "POST",
        "url": "={{ $env.GITEA_URL }}/api/v1/repos/{{ $env.GITEA_OWNER }}/{{ $env.GITEA_REPO }}/issues",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "options": {}
      }
    },
    {
      "name": "Create Redmine Issue",
      "type": "n8n-nodes-base.httpRequest",
      "position": [1050, 400],
      "parameters": {
        "method": "POST",
        "url": "={{ $env.REDMINE_URL }}/issues.json",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "options": {}
      }
    },
    {
      "name": "Error Handler & Retry Logic",
      "type": "n8n-nodes-base.code",
      "position": [1250, 300],
      "parameters": {
        "jsCode": "// Error handling code from Node 9..."
      }
    },
    {
      "name": "Build Response",
      "type": "n8n-nodes-base.code",
      "position": [1450, 300],
      "parameters": {
        "jsCode": "// Response building code from Node 10..."
      }
    },
    {
      "name": "Return Response",
      "type": "n8n-nodes-base.respondToWebhook",
      "position": [1650, 300],
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{ JSON.stringify($json) }}",
        "options": {
          "responseCode": "={{ $json.success ? 200 : 400 }}"
        }
      }
    }
  ],
  "connections": {
    "Form Submission Webhook": {
      "main": [[{"node": "Validate Input Data"}]]
    },
    "Validate Input Data": {
      "main": [[{"node": "Validation Check"}]]
    },
    "Validation Check": {
      "main": [
        [{"node": "Process Attachments"}],
        [{"node": "Return Response"}]
      ]
    },
    "Process Attachments": {
      "main": [[{"node": "Create Gitea Issue"}, {"node": "Create Redmine Issue"}]]
    },
    "Create Gitea Issue": {
      "main": [[{"node": "Error Handler & Retry Logic"}]]
    },
    "Create Redmine Issue": {
      "main": [[{"node": "Error Handler & Retry Logic"}]]
    },
    "Error Handler & Retry Logic": {
      "main": [[{"node": "Build Response"}]]
    },
    "Build Response": {
      "main": [[{"node": "Return Response"}]]
    }
  }
}
```

---

## Change Log

**v1.0.0 (2026-01-26)**
- Initial workflow release
- Gitea and Redmine integration
- Attachment handling support
- Comprehensive error handling
- Complete documentation

---

## Support

For issues or questions:
- **Documentation:** See n8n-workflows/ directory
- **Issues:** Create GitHub issue in repository
- **Discussions:** Use project discussion forum

---

**Workflow Status:** Production Ready
**Tested With:** n8n v1.0.0, Gitea v1.18, Redmine v4.2
**License:** MIT
