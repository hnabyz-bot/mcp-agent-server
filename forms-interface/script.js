/**
 * Issue Submission Form Script
 *
 * Features:
 * - Client-side validation for required fields
 * - File upload handling with drag-and-drop support
 * - Form submission to n8n webhook endpoint
 * - Loading states and error handling
 * - Accessibility enhancements (ARIA, keyboard navigation)
 */

// ========================================
// Configuration
// ========================================

const CONFIG = {
    webhookUrl: 'https://api.abyz-lab.work/webhook/issue-submission',
    maxFileSize: 10 * 1024 * 1024, // 10MB in bytes
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

// ========================================
// DOM Elements
// ========================================

const form = document.getElementById('issueForm');
const submitBtn = document.getElementById('submitBtn');
const resetBtn = document.getElementById('resetBtn');
const statusMessage = document.getElementById('statusMessage');
const fileInput = document.getElementById('attachments');
const fileDropZone = document.getElementById('fileDropZone');
const fileList = document.getElementById('fileList');

// Store selected files
let selectedFiles = [];

// ========================================
// Utility Functions
// ========================================

/**
 * Format file size in human-readable format
 * @param {number} bytes - File size in bytes
 * @returns {string} Formatted file size
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

/**
 * Validate email format
 * @param {string} email - Email address to validate
 * @returns {boolean} True if valid email format
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Show status message
 * @param {string} message - Message to display
 * @param {string} type - Message type: 'success', 'error', 'info'
 */
function showStatusMessage(message, type = 'info') {
    statusMessage.textContent = message;
    statusMessage.className = `status-message ${type}`;
    statusMessage.hidden = false;

    // Scroll to message
    statusMessage.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

    // Auto-hide after 5 seconds for success messages
    if (type === 'success') {
        setTimeout(() => {
            statusMessage.hidden = true;
        }, 5000);
    }
}

/**
 * Hide status message
 */
function hideStatusMessage() {
    statusMessage.hidden = true;
}

/**
 * Set button loading state
 * @param {boolean} isLoading - Whether button should be in loading state
 */
function setButtonLoading(isLoading) {
    const btnText = submitBtn.querySelector('.btn-text');
    const btnLoading = submitBtn.querySelector('.btn-loading');

    if (isLoading) {
        submitBtn.disabled = true;
        btnText.hidden = true;
        btnLoading.hidden = false;
    } else {
        submitBtn.disabled = false;
        btnText.hidden = false;
        btnLoading.hidden = true;
    }
}

/**
 * Show field error
 * @param {HTMLElement} field - Form field element
 * @param {string} message - Error message
 */
function showFieldError(field, message) {
    field.classList.add('error');
    field.classList.remove('success');

    const errorElement = document.getElementById(`${field.id}-error`);
    if (errorElement) {
        errorElement.textContent = message;
    }

    // Set ARIA invalid state
    field.setAttribute('aria-invalid', 'true');
}

/**
 * Clear field error
 * @param {HTMLElement} field - Form field element
 */
function clearFieldError(field) {
    field.classList.remove('error');
    field.classList.add('success');

    const errorElement = document.getElementById(`${field.id}-error`);
    if (errorElement) {
        errorElement.textContent = '';
    }

    // Set ARIA valid state
    field.setAttribute('aria-invalid', 'false');
}

/**
 * Clear all field states
 */
function clearAllFieldStates() {
    const fields = form.querySelectorAll('.form-input, .form-select, .form-textarea');
    fields.forEach(field => {
        field.classList.remove('error', 'success');
        field.removeAttribute('aria-invalid');

        const errorElement = document.getElementById(`${field.id}-error`);
        if (errorElement) {
            errorElement.textContent = '';
        }
    });
}

// ========================================
// Validation Functions
// ========================================

/**
 * Validate required field
 * @param {HTMLElement} field - Form field element
 * @returns {boolean} True if valid
 */
function validateRequired(field) {
    if (!field.required) return true;

    const value = field.value.trim();
    if (!value) {
        showFieldError(field, '이 필드는 필수 항목입니다');
        return false;
    }

    clearFieldError(field);
    return true;
}

/**
 * Validate title field
 * @param {HTMLElement} field - Title input field
 * @returns {boolean} True if valid
 */
function validateTitle(field) {
    if (!validateRequired(field)) return false;

    const value = field.value.trim();
    if (value.length < 3) {
        showFieldError(field, '제목은 최소 3자 이상 입력해야 합니다');
        return false;
    }

    if (value.length > 255) {
        showFieldError(field, '제목은 255자 이하여야 합니다');
        return false;
    }

    clearFieldError(field);
    return true;
}

/**
 * Validate description field
 * @param {HTMLElement} field - Description textarea
 * @returns {boolean} True if valid
 */
function validateDescription(field) {
    if (!validateRequired(field)) return false;

    const value = field.value.trim();
    if (value.length < 10) {
        showFieldError(field, '설명은 최소 10자 이상 입력해야 합니다');
        return false;
    }

    clearFieldError(field);
    return true;
}

/**
 * Validate assignee field
 * @param {HTMLElement} field - Assignee input field
 * @returns {boolean} True if valid
 */
function validateAssignee(field) {
    const value = field.value.trim();
    if (!value) {
        clearFieldError(field);
        return true; // Optional field
    }

    // Check if it's email or username format
    if (!isValidEmail(value) && !/^[a-zA-Z0-9_-]+$/.test(value)) {
        showFieldError(field, '유효한 이메일 또는 사용자명을 입력하세요');
        return false;
    }

    clearFieldError(field);
    return true;
}

/**
 * Validate related issues field
 * @param {HTMLElement} field - Related issues input field
 * @returns {boolean} True if valid
 */
function validateRelatedIssues(field) {
    const value = field.value.trim();
    if (!value) {
        clearFieldError(field);
        return true; // Optional field
    }

    // Check if comma-separated issue IDs are valid numbers
    const issueIds = value.split(',').map(id => id.trim());
    const invalidIds = issueIds.filter(id => id && !/^\d+$/.test(id));

    if (invalidIds.length > 0) {
        showFieldError(field, '유효한 이슈 ID를 입력하세요 (숫자만)');
        return false;
    }

    clearFieldError(field);
    return true;
}

/**
 * Validate all form fields
 * @returns {boolean} True if all fields are valid
 */
function validateForm() {
    let isValid = true;

    // Validate title
    const titleField = document.getElementById('title');
    if (!validateTitle(titleField)) {
        isValid = false;
    }

    // Validate email
    const emailField = document.getElementById('email');
    if (!validateRequired(emailField)) {
        isValid = false;
    } else if (!isValidEmail(emailField.value.trim())) {
        showFieldError(emailField, '유효한 이메일 주소를 입력하세요');
        isValid = false;
    } else {
        clearFieldError(emailField);
    }

    // Validate description
    const descriptionField = document.getElementById('description');
    if (!validateDescription(descriptionField)) {
        isValid = false;
    }

    // Validate assignee
    const assigneeField = document.getElementById('assignee');
    if (!validateAssignee(assigneeField)) {
        isValid = false;
    }

    // Validate related issues
    const relatedIssuesField = document.getElementById('relatedIssues');
    if (!validateRelatedIssues(relatedIssuesField)) {
        isValid = false;
    }

    return isValid;
}

// ========================================
// File Handling Functions
// ========================================

/**
 * Check if file type is allowed
 * @param {File} file - File to check
 * @returns {boolean} True if file type is allowed
 */
function isFileTypeAllowed(file) {
    return CONFIG.allowedFileTypes.includes(file.type) || file.name.endsWith('.md');
}

/**
 * Validate file
 * @param {File} file - File to validate
 * @returns {Object} Validation result with isValid and message
 */
function validateFile(file) {
    if (!isFileTypeAllowed(file)) {
        return {
            isValid: false,
            message: `허용되지 않는 파일 형식입니다: ${file.name}`
        };
    }

    if (file.size > CONFIG.maxFileSize) {
        return {
            isValid: false,
            message: `파일 크기가 초과되었습니다 (${formatFileSize(file.size)}): ${file.name}`
        };
    }

    return { isValid: true };
}

/**
 * Add file to selection
 * @param {File} file - File to add
 */
function addFile(file) {
    // Check max files limit
    if (selectedFiles.length >= CONFIG.maxFiles) {
        showStatusMessage(`최대 ${CONFIG.maxFiles}개의 파일까지 업로드할 수 있습니다`, 'error');
        return;
    }

    // Validate file
    const validation = validateFile(file);
    if (!validation.isValid) {
        showStatusMessage(validation.message, 'error');
        return;
    }

    // Check for duplicates
    const isDuplicate = selectedFiles.some(f => f.name === file.name && f.size === file.size);
    if (isDuplicate) {
        showStatusMessage(`파일이 이미 선택되었습니다: ${file.name}`, 'error');
        return;
    }

    // Add to selected files
    selectedFiles.push(file);
    updateFileList();
}

/**
 * Remove file from selection
 * @param {number} index - Index of file to remove
 */
function removeFile(index) {
    selectedFiles.splice(index, 1);
    updateFileList();
}

/**
 * Update file list display
 */
function updateFileList() {
    fileList.innerHTML = '';

    if (selectedFiles.length === 0) {
        return;
    }

    selectedFiles.forEach((file, index) => {
        const fileItem = document.createElement('div');
        fileItem.className = 'file-item';
        fileItem.setAttribute('role', 'listitem');

        const fileInfo = document.createElement('div');
        fileInfo.className = 'file-info';

        // File icon (SVG)
        const fileIcon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        fileIcon.setAttribute('class', 'file-icon');
        fileIcon.setAttribute('fill', 'none');
        fileIcon.setAttribute('viewBox', '0 0 24 24');
        fileIcon.setAttribute('stroke', 'currentColor');
        fileIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />';

        // File name and size
        const fileName = document.createElement('span');
        fileName.className = 'file-name';
        fileName.textContent = file.name;

        const fileSize = document.createElement('span');
        fileSize.className = 'file-size';
        fileSize.textContent = formatFileSize(file.size);

        fileInfo.appendChild(fileIcon);
        fileInfo.appendChild(fileName);
        fileInfo.appendChild(fileSize);

        // Remove button
        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'file-remove';
        removeBtn.setAttribute('aria-label', `파일 제거: ${file.name}`);
        removeBtn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>';
        removeBtn.addEventListener('click', () => removeFile(index));

        fileItem.appendChild(fileInfo);
        fileItem.appendChild(removeBtn);
        fileList.appendChild(fileItem);
    });
}

/**
 * Clear all selected files
 */
function clearFiles() {
    selectedFiles = [];
    fileInput.value = ''; // Reset file input
    updateFileList();
}

// ========================================
// Form Submission
// ========================================

/**
 * Prepare form data for submission
 * @returns {FormData} Form data ready to send
 */
function prepareFormData() {
    const formData = new FormData();

    // Add form fields
    formData.append('title', document.getElementById('title').value.trim());
    formData.append('email', document.getElementById('email').value.trim());
    formData.append('description', document.getElementById('description').value.trim());
    formData.append('priority', document.getElementById('priority').value);
    formData.append('labels', document.getElementById('labels').value.trim());
    formData.append('assignee', document.getElementById('assignee').value.trim());
    formData.append('milestone', document.getElementById('milestone').value.trim());
    formData.append('relatedIssues', document.getElementById('relatedIssues').value.trim());

    // Add files
    selectedFiles.forEach((file, index) => {
        formData.append(`file_${index}`, file);
    });

    // Add metadata
    formData.append('fileCount', selectedFiles.length.toString());
    formData.append('submittedAt', new Date().toISOString());

    return formData;
}

/**
 * Submit form to webhook
 * @param {FormData} formData - Form data to submit
 */
async function submitForm(formData) {
    try {
        setButtonLoading(true);
        hideStatusMessage();

        const response = await fetch(CONFIG.webhookUrl, {
            method: 'POST',
            body: formData,
            // Don't set Content-Type header, let browser set it with boundary
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();

        // Success
        showStatusMessage(
            `이슈가 성공적으로 제출되었습니다! 이슈 ID: ${result.issueId || 'N/A'}`,
            'success'
        );

        // Reset form after delay
        setTimeout(() => {
            resetForm();
        }, 2000);

    } catch (error) {
        console.error('Form submission error:', error);
        showStatusMessage(
            `이슈 제출 중 오류가 발생했습니다: ${error.message}. 나중에 다시 시도해주세요.`,
            'error'
        );
    } finally {
        setButtonLoading(false);
    }
}

/**
 * Reset form to initial state
 */
function resetForm() {
    form.reset();
    clearAllFieldStates();
    clearFiles();
    hideStatusMessage();
}

// ========================================
// Event Listeners
// ========================================

/**
 * Initialize event listeners
 */
function initEventListeners() {
    // Form submission
    form.addEventListener('submit', (e) => {
        e.preventDefault();

        // Validate form
        if (!validateForm()) {
            showStatusMessage('필수 항목을 모두 입력하고 유효성을 확인해주세요', 'error');
            return;
        }

        // Prepare and submit form
        const formData = prepareFormData();
        submitForm(formData);
    });

    // Form reset
    resetBtn.addEventListener('click', (e) => {
        e.preventDefault();
        resetForm();
    });

    // Real-time validation on blur
    const titleField = document.getElementById('title');
    titleField.addEventListener('blur', () => validateTitle(titleField));

    const emailField = document.getElementById('email');
    emailField.addEventListener('blur', () => {
        if (!validateRequired(emailField)) {
            return;
        }
        if (!isValidEmail(emailField.value.trim())) {
            showFieldError(emailField, '유효한 이메일 주소를 입력하세요');
        } else {
            clearFieldError(emailField);
        }
    });

    const descriptionField = document.getElementById('description');
    descriptionField.addEventListener('blur', () => validateDescription(descriptionField));

    const assigneeField = document.getElementById('assignee');
    assigneeField.addEventListener('blur', () => validateAssignee(assigneeField));

    const relatedIssuesField = document.getElementById('relatedIssues');
    relatedIssuesField.addEventListener('blur', () => validateRelatedIssues(relatedIssuesField));

    // Clear error on input
    const allFields = form.querySelectorAll('.form-input, .form-select, .form-textarea');
    allFields.forEach(field => {
        field.addEventListener('input', () => {
            if (field.classList.contains('error')) {
                clearFieldError(field);
            }
        });
    });

    // File input change
    fileInput.addEventListener('change', (e) => {
        const files = Array.from(e.target.files);
        files.forEach(file => addFile(file));
        fileInput.value = ''; // Reset to allow selecting same file again
    });

    // Drag and drop for file upload
    fileDropZone.addEventListener('click', () => {
        fileInput.click();
    });

    fileDropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.stopPropagation();
        fileDropZone.classList.add('dragover');
    });

    fileDropZone.addEventListener('dragleave', (e) => {
        e.preventDefault();
        e.stopPropagation();
        fileDropZone.classList.remove('dragover');
    });

    fileDropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        e.stopPropagation();
        fileDropZone.classList.remove('dragover');

        const files = Array.from(e.dataTransfer.files);
        files.forEach(file => addFile(file));
    });

    // Keyboard navigation for file drop zone
    fileDropZone.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            fileInput.click();
        }
    });
}

// ========================================
// Initialize
// ========================================

/**
 * Initialize the form when DOM is ready
 */
function init() {
    initEventListeners();
    console.log('Issue submission form initialized');
}

// Initialize when DOM is fully loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
