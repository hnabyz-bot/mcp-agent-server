# Pre-deployment Checklist for forms-interface

> **목적:** 배포 실패를 방지하기 위한 사전 검증 체크리스트
> **적용:** Windows에서 변경 후 `windows-deploy.bat` 실행 전, Raspberry Pi에서 `deploy-and-restart.sh` 실행 전

---

## Windows (개발 환경)

### Phase 1: 파일 검증

**핵심 파일 존재 확인:**
```powershell
# PowerShell에서 실행
$files = @(
    "forms-interface/index.html",
    "forms-interface/script.js",
    "forms-interface/styles.css"
)

$files | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "✓ $_ exists" -ForegroundColor Green
    } else {
        Write-Host "✗ $_ NOT FOUND" -ForegroundColor Red
        exit 1
    }
}
```

**파일명 일치 확인:**
```bash
# Git Bash에서 실행
cd forms-interface
ls -la *.css *.js *.html
# 실제 파일이 styles.css인지 확인
```

### Phase 2: 코드 검증

**index.html 스크립트 경로 확인:**
```html
<!-- 올바른 예 -->
<link rel="stylesheet" href="styles.css">
<script src="script.js?v=1.0.5"></script>
```

**forms-interface/ 스크립트 로드 순서:**
1. `styles.css` - CSS 먼저 로드
2. `script.js` - JavaScript 나중에 로드

### Phase 3: Git 상태 확인

```bash
# 1. Git 상태 확인
git status

# 2. 커밋되지 않은 파일 없는지 확인
git status --porcelain

# 3. 원격 저장소 동기화 확인
git fetch origin --dry-run
```

### Phase 4: 캐시 버전 확인

```bash
# 현재 버전 확인
grep -oP 'script\.js\?v=\K[0-9.]+' forms-interface/index.html
```

---

## Raspberry Pi (배포 환경)

### Phase 1: 사전 검증 (git pull 전)

**필수 파일 확인:**
```bash
cd ~/workspace/mcp-agent-server

# 핵심 파일 존재 확인
ls -la forms-interface/*.html
ls -la forms-interface/*.js
ls -la forms-interface/*.css

# expected output:
# -rw-r--r-- 1 raspi raspi ... index.html
# -rw-r--r-- 1 raspi raspi ... script.js
# -rw-r--r-- 1 raspi raspi ... styles.css
```

**파일명 일치 검증:**
```bash
# 스크립트에서 참조하는 파일명 확인
grep -n "\.css" forms-interface/index.html
# 출력: href="styles.css" 여야 함 (style.css 아니라)
```

**권한 확인:**
```bash
# 배포 스크립트 실행 권한 확인
ls -la deploy-and-restart.sh setup-raspberry-pi.sh

# 실행 권한 없으면 부여
chmod +x deploy-and-restart.sh
chmod +x setup-raspberry-pi.sh
```

**웹 서버 상태:**
```bash
# nginx 상태 확인
sudo systemctl status nginx

# nginx 설정 테스트
sudo nginx -t
```

**네트워크 연결:**
```bash
# GitHub 연결 확인
ping -c 2 github.com

# 원격 저장소 접근 확인
git ls-remote origin
```

### Phase 2: 배포 스크립트 실행

**실행 전 백업:**
```bash
# 기존 배포 백업 위치 확인
ls -la /var/www/html/forms*

# 백업이 너무 많은지 확인 (최신 5개만 보관)
ls -dt /var/www/html/forms.backup.* | head -10
```

**배포 실행:**
```bash
cd ~/workspace/mcp-agent-server
sudo ./deploy-and-restart.sh 2>&1 | tee deploy-output.log
```

### Phase 3: 배포 후 검증

**심볼릭 링크 확인:**
```bash
# 심볼릭 링크 확인
ls -la /var/www/html/forms

# 실제 경로 확인
readlink -f /var/www/html/forms
# expected: /home/raspi/workspace/mcp-agent-server/forms-interface
```

**파일 접근 테스트:**
```bash
# 웹 서버에서 파일 읽기 테스트
curl -I http://localhost/forms/index.html
curl -I http://localhost/forms/script.js
curl -I http://localhost/forms/styles.css
# expected: HTTP/1.1 200 OK
```

**권한 검증:**
```bash
# 읽기 전용 파일 확인
ls -la forms-interface/index.html forms-interface/script.js forms-interface/styles.css
# expected: -r--r--r-- (444)
```

**캐시 버전 확인:**
```bash
# 배포된 버전 확인
grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html
```

**브라우저 접속 테스트:**
```bash
# 로컬에서 접속 테스트
curl -s http://localhost/forms | head -20

# 외부에서 접속 테스트 (Cloudflare Tunnel 통해)
curl -s https://forms.abyz-lab.work | head -20
```

---

## 문제 해결 가이드

### 문제 1: 파일명 불일치

**증상:**
```
chmod: cannot access '.../style.css': No such file or directory
```

**원인:** 실제 파일은 `styles.css`인데 코드에서 `style.css`로 참조

**해결:**
```bash
# 1. 실제 파일명 확인
ls -la forms-interface/*.css

# 2. 코드베이스 전체 검색
grep -r "style\.css" --include="*.html" --include="*.js" --include="*.sh" --include="*.md"

# 3. 일괄적으로 styles.css로 수정
```

### 문제 2: 실행 권한 소실

**증상:**
```
sudo-rs: cannot execute '.../deploy-and-restart.sh': Permission denied
```

**원인:** git pull 후 실행 권한이 유지되지 않음

**해결:**
```bash
# 권한 재부여
chmod +x deploy-and-restart.sh

# 권한 확인
ls -la deploy-and-restart.sh
# expected: -rwxr-xr-x (755)
```

### 문제 3: sudo-rs 실행 거부

**증상:**
```
thread 'main' panicked at src/exec/use_pty/monitor.rs:283:45
```

**원인:** sudo-rs가 특정 상황에서 실행 거부

**해결:**
```bash
# 방법 1: 권한 재부여 후 재시도
chmod +x deploy-and-restart.sh
sudo ./deploy-and-restart.sh

# 방법 2: sudo -s를 사용하여 shell 실행
sudo -s bash -c './deploy-and-restart.sh'
```

### 문제 4: 브라우저 캐시

**증상:** 변경사항이 반영되지 않음

**해결:**
1. 캐시 강력 새로고침: `Ctrl + Shift + R` (Windows/Linux)
2. 시크릿 모드/Incognito 모드 사용
3. 캐시 버전이 올바르게 증가했는지 확인

---

## 자동화 스크립트

사용을 위한 자동 검증 스크립트를 생성할 수 있습니다:

```bash
#!/bin/bash
# pre-flight-check.sh

echo "==================================="
echo "Pre-deployment Checklist"
echo "==================================="
echo ""

# Check files exist
echo "Checking files..."
for file in forms-interface/index.html forms-interface/script.js forms-interface/styles.css; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file NOT FOUND"
        exit 1
    fi
done

# Check script permissions
echo ""
echo "Checking script permissions..."
if [ -x "deploy-and-restart.sh" ]; then
    echo "✓ deploy-and-restart.sh is executable"
else
    echo "⚠ deploy-and-restart.sh is NOT executable"
    chmod +x deploy-and-restart.sh
    echo "✓ Fixed: chmod +x deploy-and-restart.sh"
fi

# Check network
echo ""
echo "Checking network..."
if ping -c 1 github.com &> /dev/null; then
    echo "✓ GitHub is reachable"
else
    echo "✗ Cannot reach GitHub"
    exit 1
fi

echo ""
echo "All checks passed! Ready to deploy."
```

---

## Best Practices

### 1. 개발 워크플로우

```
Windows 개발
    ↓
1. 로컬 파일 수정
2. Pre-flight 체크리스트 실행
3. Git 커밋
4. windows-deploy.bat 실행 (캐시 버전 증가 + 푸시)
    ↓
Raspberry Pi 배포
    ↓
1. git pull
2. Pre-flight 체크리스트 실행
3. sudo ./deploy-and-restart.sh
4. 배포 후 검증
```

### 2. 검증 우선순위

**반드시 확인:**
1. 실제 파일 존재 여부
2. 파일명 일치 (`styles.css` vs `style.css`)
3. 실행 권한 (`chmod +x`)
4. 네트워크 연결

**배포 후 확인:**
1. 심볼릭 링크
2. HTTP 응답 (curl -I)
3. 캐시 버전 일치
4. 브라우저 실제 접속

### 3. 실패 시 대응

1. **로그 확인:** `tail -f $HOME/mcp-agent-deploy.log`
2. **롤백 확인:** 백업 위치 확인 후 복원
3. **이슈 트래킹:** 문제 증상, 에러 메시지, 해결 방법 문서화
4. **재시도 전 검증:** Pre-flight 체크리스트 재실행

---

## 체크리스트 완료 기준

- [ ] Windows: 모든 핵심 파일 존재 확인
- [ ] Windows: 파일명 일치 검증 (`styles.css`)
- [ ] Windows: Git 상태 확인
- [ ] Raspberry Pi: 파일 존재 및 권한 확인
- [ ] Raspberry Pi: 실행 권한 확인
- [ ] Raspberry Pi: 네트워크 연결 확인
- [ ] 배포 후: 심볼릭 링크 확인
- [ ] 배포 후: HTTP 접속 테스트
- [ ] 배포 후: 브라우저 실제 접속 확인

---

**마지막 업데이트:** 2026-01-28
**버전:** 1.0
**유지 관리자:** 개발 팀
