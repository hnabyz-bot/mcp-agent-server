# Issue Submission Form

A modern, responsive HTML/CSS/JavaScript form for submitting Gitea/Redmine issues with comprehensive validation and file upload support.

## Features

- ✅ Complete form with all required fields
- 🎨 Modern, clean design with blue/gray color scheme
- 📱 Fully responsive layout (mobile-first design)
- ✨ Client-side validation for all fields
- 📎 Drag-and-drop file upload support
- 🔄 Loading states during submission
- ✅ Success/error message display
- ♿ WCAG 2.1 AA compliant (ARIA labels, keyboard navigation)
- 🇰🇷 Korean language interface
- 🚀 Pure HTML5, CSS3, vanilla JavaScript (no frameworks)

## Form Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **제목 (Title)** | Text | Yes | Issue title (min 3, max 255 characters) |
| **설명 (Description)** | Textarea | Yes | Detailed description (min 10 characters) |
| **우선순위 (Priority)** | Dropdown | No | Low, Normal, High, Urgent |
| **레이블 (Labels)** | Text | No | Comma-separated labels |
| **담당자 (Assignee)** | Text | No | Email or username |
| **마일스톤 (Milestone)** | Text | No | Milestone name |
| **예상 시간 (Estimated Time)** | Number | No | Time estimate in hours |
| **진행률 (Progress)** | Number | No | Progress percentage (0-100) |
| **관련 이슈 (Related Issues)** | Text | No | Comma-separated issue IDs |
| **첨부 파일 (Attachments)** | File | No | Multiple files (max 10 files, 10MB each) |

## File Structure

```
forms-interface/
├── index.html       # Main form HTML
├── styles.css       # All styles
├── script.js        # Form logic, validation, API calls
└── README.md        # Setup instructions
```

## Setup Instructions

### Option 1: Open Directly in Browser

1. Navigate to the `forms-interface/` directory
2. Open `index.html` in your web browser

### Option 2: Local Web Server (Recommended)

#### Using Python

```bash
# Python 3
cd forms-interface
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

#### Using Node.js (npx)

```bash
cd forms-interface
npx serve
```

#### Using PHP

```bash
cd forms-interface
php -S localhost:8000
```

Then open your browser and navigate to:
- Python/PHP: `http://localhost:8000`
- Node.js: `http://localhost:3000`

### Option 3: Deploy to Web Server

Upload all files to your web server (Apache, Nginx, etc.):

```bash
scp forms-interface/* user@server:/var/www/html/
```

## Configuration

### Webhook Endpoint

The form submits to the n8n webhook endpoint configured in `script.js`:

```javascript
const CONFIG = {
    webhookUrl: 'https://api.abyz-lab.work/webhook/issue-submit',
    // ...
};
```

To change the endpoint, edit the `webhookUrl` value in `script.js`.

### File Upload Limits

Default file upload limits in `script.js`:

```javascript
const CONFIG = {
    maxFileSize: 10 * 1024 * 1024, // 10MB
    maxFiles: 10,
    allowedFileTypes: [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'application/pdf',
        'text/plain',
        'text/markdown',
        'application/json',
        'application/zip'
    ]
};
```

Adjust these values according to your needs.

## Form Submission Data Format

The form submits data as `FormData` with the following fields:

```
title: string
description: string
priority: 'low' | 'normal' | 'high' | 'urgent'
labels: string
assignee: string
milestone: string
estimatedTime: string
progress: string
relatedIssues: string
file_0, file_1, ...: File objects
fileCount: number
submittedAt: ISO datetime string
```

## Validation Rules

### Title
- Required: Yes
- Min length: 3 characters
- Max length: 255 characters

### Description
- Required: Yes
- Min length: 10 characters

### Priority
- Required: No
- Options: low, normal (default), high, urgent

### Assignee
- Required: No
- Format: Valid email or username (alphanumeric with dashes/underscores)

### Progress
- Required: No
- Range: 0-100
- Default: 0

### Estimated Time
- Required: No
- Format: Positive number (decimal allowed)
- Unit: Hours

### Related Issues
- Required: No
- Format: Comma-separated numeric issue IDs

### Attachments
- Required: No
- Max files: 10
- Max size per file: 10MB
- Allowed types: Images, PDF, text, markdown, JSON, ZIP

## Browser Support

- Chrome/Edge: Latest 2 versions
- Firefox: Latest 2 versions
- Safari: Latest 2 versions
- Opera: Latest 2 versions

## Accessibility

This form follows WCAG 2.1 AA guidelines:

- ✅ Semantic HTML structure
- ✅ ARIA labels and roles
- ✅ Keyboard navigation support
- ✅ Focus indicators
- ✅ Error messages with `role="alert"`
- ✅ Required field indicators
- ✅ Form validation feedback
- ✅ Screen reader support

## Security Considerations

1. **HTTPS**: Always use HTTPS for the webhook endpoint in production
2. **CORS**: Ensure your n8n webhook allows CORS from your domain
3. **File Validation**: Client-side validation is implemented, but server-side validation is also required
4. **Rate Limiting**: Consider implementing rate limiting on the webhook endpoint
5. **Data Sanitization**: Sanitize all user input on the server side

## Customization

### Changing Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --color-primary-500: #3b82f6;  /* Primary blue */
    --color-primary-600: #2563eb;  /* Darker blue */
    /* ... */
}
```

### Changing Language

1. Edit text in `index.html` for labels and placeholders
2. Update error messages in `script.js`
3. Don't forget to update `<html lang="ko">` attribute

### Adding More Fields

1. Add HTML in `index.html`:
```html
<div class="form-group">
    <label for="customField" class="form-label">Custom Field</label>
    <input type="text" id="customField" name="customField" class="form-input">
</div>
```

2. Add validation in `script.js`:
```javascript
function validateCustomField(field) {
    // Your validation logic
    return true;
}
```

3. Add to `FormData` in `prepareFormData()`:
```javascript
formData.append('customField', document.getElementById('customField').value.trim());
```

## Troubleshooting

### Form not submitting

1. Check browser console for errors (F12)
2. Verify webhook URL is correct
3. Check CORS settings on webhook endpoint
4. Ensure network connectivity

### File upload not working

1. Check file size (max 10MB per file)
2. Verify file type is allowed
3. Check max files limit (10 files)
4. Ensure browser supports File API

### Validation errors not showing

1. Check browser console for JavaScript errors
2. Verify error element IDs match field IDs
3. Ensure CSS is loaded correctly

## Development

To modify the form:

1. **HTML structure**: Edit `index.html`
2. **Styling**: Edit `styles.css`
3. **Logic/Validation**: Edit `script.js`
4. **Configuration**: Edit `CONFIG` object in `script.js`

## Testing

### Manual Testing Checklist

- [ ] All required fields validate correctly
- [ ] Optional fields accept empty values
- [ ] File upload works with drag-and-drop
- [ ] File upload works with click-to-select
- [ ] Multiple files can be selected
- [ ] File removal works
- [ ] Form submits successfully
- [ ] Loading state shows during submission
- [ ] Success message displays on completion
- [ ] Error message displays on failure
- [ ] Reset button clears form
- [ ] Form is responsive on mobile devices
- [ ] Keyboard navigation works
- [ ] Screen reader announces errors

### Cross-Browser Testing

Test the form in multiple browsers to ensure compatibility:

- Google Chrome
- Mozilla Firefox
- Safari
- Microsoft Edge

## License

This form is provided as-is for use with Abyz Lab's n8n webhook integration.

## Support

For issues or questions, please contact the development team.

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
