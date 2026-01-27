# Forms Interface 배포 가이드

## 🔄 전체 배포 워크플로우

### 개요
- **Windows (개발 머신):** 버전 관리 및 Git Push
- **Raspberry Pi (배포 서버):** Git Pull 및 배포

```
Windows 개발 머신
  ↓
1. windows-deploy.bat 실행
  ↓ (자동 버전 증가 + Git Push)
GitHub
  ↓
Raspberry Pi
  ↓
2. git pull
  ↓
3. sudo ./deploy-and-restart.sh
  ↓ (배포 + Nginx 재시작)
완료!
```

---

## 🪟 Windows (개발 머신) 배포

### 사전 요구사항
- Git이 설치되어 있어야 함
- GitHub에 push 할 수 있는 권한 필요

### 배포 단계

#### 1단계: 배포 스크립트 실행

```cmd
cd d:\workspace\github-space\mcp-agent-server
windows-deploy.bat
```

#### 자동으로 수행되는 작업
- ✅ Git 저장소 상태 확인
- ✅ 현재 캐시 버전 읽기
- ✅ 버전 자동 증가 (예: 1.0.3 → 1.0.4)
- ✅ `forms-interface/index.html` 업데이트
- ✅ Git commit (자동 생성된 메시지)
- ✅ GitHub로 push

#### 출력 예시
```
====================================
Forms Interface Deployment (Windows)
====================================

Step 1: Checking git status...
[OK] Working directory is clean

Step 2: Reading current cache version...
Current version: 1.0.3

Step 3: Incrementing cache version...
New version: 1.0.4

Step 4: Updating forms-interface\index.html...
[OK] Cache version updated to 1.0.4

Step 5: Committing and pushing changes...
[OK] Changes committed
Pushing to GitHub...
[OK] Changes pushed to GitHub

====================================
Deployment completed successfully!
====================================

Deployment Summary:
  Previous Version: 1.0.3
  New Version: 1.0.4

Next Steps:
  1. SSH into Raspberry Pi
  2. Run: cd ~/workspace/mcp-agent-server
  3. Run: git pull
  4. Run: sudo ./deploy-and-restart.sh
```

---

## 🍇 Raspberry Pi (배포 서버) 배포

### 1단계: SSH 접속

```bash
ssh pi@your-pi-ip
```

### 2단계: 최신 코드 가져오기

```bash
cd ~/workspace/mcp-agent-server
git pull origin main
```

**예상 출력:**
```
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Total 5 (delta 3), reused 3 (delta 1), pack-reused 0
Unpacking objects: 100% (5/5), 686 bytes | 343.00 KiB/s, done.
From github.com:yourusername/mcp-agent-server
   abc123d..def4567  main -> origin/main
Updating abc123d..def4567
Fast-forward
 forms-interface/index.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### 3단계: 자동 배포 실행

```bash
chmod +x deploy-and-restart.sh
sudo ./deploy-and-restart.sh
```

#### 자동으로 수행되는 작업
- ✅ 최신 코드 이미 git pull로 가져옴
- ✅ 현재 캐시 버전 읽기 (변경 없음)
- ✅ 웹 서버 감지 (nginx/Apache)
- ✅ `/var/www/html/forms`에 배포
- ✅ 파일 권한 설정 (www-data:www-data)
- ✅ Nginx/Apache 재시작
- ✅ 배포 검증

**중요:** 버전 증가는 Windows에서만 수행됩니다. Raspberry Pi는 배포만 합니다.

#### 출력 예시
```
===================================
Forms Interface Auto-Deployment
===================================

Step 1: Pulling latest changes...
✓ Git pull completed

Step 2: Reading cache version...
✓ Current cache version: 1.0.4
Note: Version is managed on Windows, not modified here

Step 3: Detecting web server...
✓ Detected: nginx

Step 4: Deploying to /var/www/html...
Backing up existing deployment...
Creating symbolic link...
Setting permissions...
✓ Deployment completed

Step 5: Restarting web server...
✓ nginx restarted

Step 6: Verifying deployment...
✓ Symbolic link exists
✓ script.js found
✓ Email field present in script.js
✓ Cache version 1.0.4 verified in index.html

Step 7: Deployment complete!
Note: Version was already updated on Windows before git push

===================================
Deployment completed successfully!
===================================

Deployment Summary:
  Cache Version: 1.0.4
  Web Server: nginx
  Deployment Path: /var/www/html/forms

Access URLs:
  → http://localhost/forms
  → https://forms.abyz-lab.work

Important: Clear browser cache to see changes!
  Windows/Linux: Ctrl + Shift + R
  Mac: Cmd + Shift + R
  Or use Incognito/Private mode
```

### 4단계: 배포 확인

```bash
# 배포된 버전 확인
grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html
# 출력: 1.0.4

# 파일 권한 확인
ls -la /var/www/html/forms/
```

---

## 🗑️ 브라우저 캐시 삭제 (필수!)

## 📋 브라우저 캐시 삭제

배포 후 반드시 브라우저 캐시를 삭제하세요:

**Windows/Linux:**
- `Ctrl + Shift + R`

**Mac:**
- `Cmd + Shift + R`

**또는 시크릿 모드/프라이빗 모드 사용:**
- Chrome: `Ctrl + Shift + N`
- Edge: `Ctrl + Shift + P`
- Firefox: `Ctrl + Shift + P`

## 🔍 배포 검증

### 1. 로컬 파일 확인 (Raspberry Pi)

```bash
# 배포된 script.js에 email 필드 확인
grep "formData.append('email'" /var/www/html/forms/script.js

# 결과:
# formData.append('email', document.getElementById('email').value.trim());
```

### 2. 캐시 버전 확인

```bash
# 배포된 버전 확인
grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html

# 예상 출력:
# 1.0.4
```

### 3. 웹 브라우저 테스트

```
https://forms.abyz-lab.work
```

개발자 도구 (F12) → Network 탭 → `script.js?v=1.0.4` 확인

### 4. n8n 웹훅 테스트 (선택사항)

### 2. n8n 웹훅 테스트

```bash
curl -X POST https://api.abyz-lab.work/webhook/issue-submission \
  -H "Content-Type: application/json" \
  -d '{
    "title": "배포 테스트",
    "email": "test@example.com",
    "description": "email 필드 확인"
  }'
```

### 3. 폼 접속 테스트

```
https://forms.abyz-lab.work
```

## 🛠️ 문제 해결

### Git 충돌 발생시

**증상:** Raspberry Pi에서 git pull 시 충돌 발생

**원인:** Windows에서 버전을 수정하기 전에 Raspberry Pi에서 변경사항이 있음

**해결:**
```bash
# 변경사항 저장
git stash

# 최신 코드 가져오기
git pull origin main

# 저장된 변경사항 폐기 (Windows가 항상 정본임)
git stash drop
```

### 배포 스크립트 실행 실패

**증상:** `deploy-and-restart.sh` 실행 권한 없음

**해결:**
```bash
chmod +x deploy-and-restart.sh
sudo ./deploy-and-restart.sh
```

### Nginx 재시작 실패

**증상:** nginx 재시작 시 오류

**해결:**
```bash
# 설정 테스트
sudo nginx -t

# 구체적인 오류 확인
sudo journalctl -xe -u nginx

# 재시작
sudo systemctl restart nginx
```

### 캐시 버전이 업데이트되지 않음

**증상:** 브라우저에서 이전 버전이 계속 표시됨

**해결:**
1. **Hard Refresh:**
   - Windows/Linux: `Ctrl + Shift + R`
   - Mac: `Cmd + Shift + R`

2. **개발자 도구에서 캐시 삭제:**
   - F12 → Application → Clear site data

3. **시크릿 모드로 테스트:**
   - Chrome: `Ctrl + Shift + N`
   - Edge: `Ctrl + Shift + P`
   - Firefox: `Ctrl + Shift + P`

### 버전 불일치

**증상:** Windows와 Raspberry Pi의 버전이 다름

**확인:**
```bash
# Windows
cd d:\workspace\github-space\mcp-agent-server
findstr "script.js?v=" forms-interface\index.html

# Raspberry Pi
grep "script.js?v=" ~/workspace/mcp-agent-server/forms-interface/index.html
```

**해결:**
```bash
# Raspberry Pi에서 로컬 변경사항 폐기
cd ~/workspace/mcp-agent-server
git reset --hard origin/main
```

---

## 📊 현재 배포 상태

## 📊 현재 배포 상태

- **최신 버전:** v1.0.2
- **배포 경로:** /var/www/html/forms
- **웹 서버:** nginx
- **외부 접속:** https://forms.abyz-lab.work

## 🔄 완전한 배포 사이클 예시

### 시나리오: 새로운 기능 배포

#### 1단계: Windows에서 코드 수정
- 파일 수정: `forms-interface/script.js`
- 변경사항 확인

#### 2단계: Windows 배포
```cmd
cd d:\workspace\github-space\mcp-agent-server
windows-deploy.bat
```
- 버전: 1.0.3 → 1.0.4
- Git commit: "Bump cache version to 1.0.4"
- Git push: 완료

#### 3단계: Raspberry Pi 배포
```bash
ssh pi@your-pi-ip
cd ~/workspace/mcp-agent-server
git pull origin main
sudo ./deploy-and-restart.sh
```
- git pull: 버전 1.0.4 수신
- 배포: /var/www/html/forms에 배포
- 검증: 버전 1.0.4 확인

#### 4단계: 브라우저 테스트
```
1. Chrome 개발자 도구 열기 (F12)
2. Network 탭으로 이동
3. https://forms.abyz-lab.work 접속
4. Ctrl + Shift + R (Hard Refresh)
5. script.js?v=1.0.4 로드 확인
6. 기능 테스트
```

---

## 📝 버전 관리 정책

### 버전 넘버링 규칙
- **형식:** `MAJOR.MINOR.PATCH` (예: 1.0.4)
- **증가:** 배포 시마다 PATCH 버전 자동 증가
- **위치:** `forms-interface/index.html`의 `script.js?v=X.X.X`

### 버전 관리 책임 분담
- **Windows:** 버전 증가, Git commit, Git push
- **Raspberry Pi:** git pull만 수행, 버전 수정 안 함

### Git 충돌 방지
- Windows만 버전을 수정함
- Raspberry Pi는 읽기 전용으로 배포만 수행
- 충돌 발생 시: `git reset --hard origin/main`

---

## 🚑 응급 상황 대처

### 이전 버전으로 즉시 롤백

```bash
# Raspberry Pi에서
cd ~/workspace/mcp-agent-server

# 이전 버전 체크아웃
git log --oneline -5
# 예: abc1234 Bump cache version to 1.0.4
#     def5678 Bump cache version to 1.0.3

# 이전 버전으로 복원
git checkout def5678
sudo ./deploy-and-restart.sh
```

### 핫픽스 배포 (긴급 수정)

```bash
# Windows에서
# 1. 긴급 수정 완료
# 2. windows-deploy.bat 실행

# Raspberry Pi에서
git pull
sudo ./deploy-and-restart.sh
```

---

## 📝 변경 이력

- **2026-01-27 (v2.0.0):**
  - ✨ Windows 배포 스크립트 추가 (`windows-deploy.bat`)
  - ✨ 버전 관리 분리: Windows(증가) + Raspberry Pi(배포만)
  - 🐛 Git 충돌 문제 해결
  - 📚 배포 가이드 전체 개편
  - 🔍 배포 검증 절차 강화

- **2026-01-27 (v1.0.0):**
  - email 필드 추가 (script.js)
  - 캐시 버전 자동 관리 시스템 구축
  - 완전 자동화 배포 스크립트 작성
  - 서비스 재시작 스크립트 작성

---

**문서 버전:** 2.0.0
**마지막 업데이트:** 2026-01-27
