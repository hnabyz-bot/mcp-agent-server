# Forms Interface 배포 가이드

## 🚀 빠른 시작 (라즈베리 파이)

### 1단계: 최신 코드 가져오기

```bash
cd ~/workspace/mcp-agent-server
git pull
```

### 2단계: 자동 배포 실행

```bash
chmod +x deploy-and-restart.sh
sudo ./deploy-and-restart.sh
```

이 스크립트가 자동으로 수행하는 작업:
- ✅ 최신 코드 pull
- ✅ 캐시 버전 자동 증가
- ✅ nginx에 배포
- ✅ 파일 권한 설정
- ✅ nginx 서비스 재시작
- ✅ 배포 검증
- ✅ 변경사항 push

### 3단계: 서비스만 재시작 (필요시)

```bash
chmod +x restart-services.sh
sudo ./restart-services.sh
```

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

## 🔍 배포 확인

### 1. 파일 확인

```bash
# 배포된 script.js에 email 필드 확인
grep "formData.append('email'" /var/www/html/forms/script.js

# 결과:
# formData.append('email', document.getElementById('email').value.trim());
```

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

## 🛠️ 수동 배포 (자동 스크립트 실패시)

```bash
cd ~/workspace/mcp-agent-server

# 1. git pull
git pull

# 2. 수동으로 파일 복사
sudo cp forms-interface/script.js /var/www/html/forms/script.js
sudo cp forms-interface/index.html /var/www/html/forms/index.html

# 3. 권한 설정
sudo chown www-data:www-data /var/www/html/forms/script.js
sudo chown www-data:www-data /var/www/html/forms/index.html

# 4. nginx 재시작
sudo systemctl restart nginx

# 5. 확인
ls -la /var/www/html/forms/
```

## 📊 현재 배포 상태

- **최신 버전:** v1.0.2
- **배포 경로:** /var/www/html/forms
- **웹 서버:** nginx
- **외부 접속:** https://forms.abyz-lab.work

## 🐛 문제 해결

### 이메일이 여전히 webhook에 없을 때

1. **배포된 파일 확인:**
   ```bash
   cat /var/www/html/forms/script.js | grep -n "formData.append('email'"
   ```

2. **브라우저 개발자 도구에서 캐시 삭제:**
   - F12 - Application - Clear site data

3. **시크릿 모드로 테스트:**
   - 캐시 영향을 받지 않음

### n8n 이메일 발송 실패

1. **n8n SMTP 자격증명 확인:**
   - n8n UI → Credentials → SMTP

2. **Gmail App Password 생성:**
   - [가이드 참조](n8n-workflows/README.md#46-62)

3. **n8n 로그 확인:**
   ```bash
   docker logs -f n8n
   ```

## 🔄 배포 워크플로우

```
개발자 작업 (Windows)
  ↓
git push
  ↓
라즈베리 파이 (git pull)
  ↓
sudo ./deploy-and-restart.sh
  ↓
브라우저 캐시 삭제
  ↓
테스트
```

## 📝 변경 이력

- **2026-01-27:**
  - email 필드 추가 (script.js)
  - 캐시 버전 자동 관리 시스템 구축
  - 완전 자동화 배포 스크립트 작성
  - 서비스 재시작 스크립트 작성

---

**버전:** 1.0.0
**마지막 업데이트:** 2026-01-27
