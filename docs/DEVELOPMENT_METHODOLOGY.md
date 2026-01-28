# Development Methodology Improvement Guide

> **목적:** 반복되는 배포 실패를 방지하고 안정적인 개발 및 배포 워크플로우를 구축하기 위한 방법론 가이드
>
> **적용 범위:** Windows 개발 환경 → Raspberry Pi 배포 환경
>
> **마지막 업데이트:** 2026-01-28
>
> **버전:** 1.0

---

## 1. 실패 패턴 분석 (Failure Pattern Analysis)

### 1.1 발생한 실패 사례 총정리

다음은 실제 배포 과정에서 발생한 5가지 주요 실패 패턴입니다:

| # | 실패 유형 | 증상 | 근본 원인 | 영향도 | 발생 빈도 |
|---|----------|------|----------|--------|----------|
| 1 | 파일명 불일치 | `chmod: cannot access 'style.css': No such file or directory` | 실제 파일(`styles.css`)과 코드 참조(`style.css`) 불일치 | **치명적** | 1회 (발견 후 전체 수정) |
| 2 | 실행 권한 소실 | `sudo-rs: cannot execute 'deploy-and-restart.sh': Permission denied` | Windows 커밋 후 git pull로 실행 권한 유지되지 않음 | **높음** | 반복 |
| 3 | Git 머지 충돌 | `Your local changes to the following files would be overwritten by merge` | 로컬 변경사항과 원격 저장소 간 충돌 | **높음** | 반복 |
| 4 | 로그 파일 권한 | `tee: /var/log/mcp-agent-setup.log: Permission denied` | `/var/log` 디렉토리 쓰기 권한 부재 | **중간** | 1회 |
| 5 | sudo-rs 실행 거부 | `thread 'main' panicked at src/exec/use_pty/monitor.rs` | sudo-rs와 특정 스크립트 실행 호환성 문제 | **중간** | 1회 |

### 1.2 근본 원인 분석 (Root Cause Analysis)

#### 원인 1: 환경 불일치 검증 부재

**문제:**
- Windows 개발 환경에서만 파일 존재를 확인
- 실제 배포 환경(Raspberry Pi)에서는 파일명 불일치 발생
- 대소문자 구분: Windows는 대소문자를 구분하지 않지만 Linux는 구분함

**예시:**
```bash
# Windows: style.css와 styles.css를 같은 파일로 인식
# Linux: style.css와 styles.css를 다른 파일로 인식
```

**해결:**
- [ ] 두 환경 모두에서 파일 존재 확인
- [ ] `ls -la`로 실제 파일명 확인 후 코드 작성
- [ ] 대소문자 정확히 일치시키기

#### 원인 2: 기본 검증 단계 생략

**문제:**
- 파일 시스템 권한 검증 없이 chmod 명령 실행
- 스크립트 실행 권한 확인 없이 배포 진행
- git stash/merge 충돌 가능성 사전 확인 안 함

**예시:**
```bash
# 나쁜 예: 확인 없이 바로 실행
chmod 444 forms-interface/style.css

# 좋은 예: 먼저 파일 존재 확인
if [ -f "forms-interface/styles.css" ]; then
    chmod 444 forms-interface/styles.css
fi
```

**해결:**
- [ ] 모든 파일 조작 전 파일 존재 확인
- [ ] 스크립트 실행 전 권한 검증
- [ ] git 작업 전 상태 확인

#### 원인 3: 단일 환경에서의 검증

**문제:**
- Windows에서만 테스트 후 배포 스크립트 실행
- 실제 배포 환경(Raspberry Pi)과의 차이 고려하지 않음
- 테스트 커버리지 부족

**해결:**
- [ ] 개발 환경과 배포 환경 모두에서 검증
- [ ] 통합 테스트 작성
- [ ] Pre-flight 체크리스트 실행

#### 원인 4: 사전 문서화 부족

**문제:**
- 발생한 문제와 해결 방법이 문서화되지 않음
- 동일한 실수 반복
- 팀 전체 지식 공유 부족

**해결:**
- [ ] 모든 문제와 해결 방법 문서화
- [ ] DEPLOYMENT_GUIDE.md에 문제 해결 기록 추가
- [ ] PRE_DEPLOYMENT_CHECKLIST.md 작성

---

## 2. 개발 원칙 수립 (Development Principles)

### 2.1 검증 우선 원칙 (Validation First Principle)

모든 변경사항은 배포 전에 반드시 검증되어야 합니다.

**원칙 1: 이중 환경 검증**
- [ ] Windows 개발 환경에서 1차 검증
- [ ] Raspberry Pi 배포 환경에서 2차 검증
- [ ] 두 환경 모두 통과 시 배포 승인

**원칙 2: 자동화된 검증**
- [ ] Pre-flight 체크리스트 자동화
- [ ] 스크립트 자체 검증 기능 포함
- [ ] 테스트 스위트 통합

**원칙 3: 점진적 배포**
- [ ] 단계별 배포 (setup → deploy → verify)
- [ ] 각 단계별 검증 및 롤백 지점
- [ ] 실패 시 즉시 중단

### 2.2 방어적 프로그래밍 (Defensive Programming)

모든 스크립트는 실패 가능성을 고려해야 합니다.

**원칙 1: 존재 확인 후 조작**
```bash
# 항상 파일 존재 확인
if [ -f "$FILE" ]; then
    chmod 444 "$FILE"
else
    log_error "File not found: $FILE"
    exit 1
fi
```

**원칙 2: 권한 확인 후 실행**
```bash
# 실행 권한 확인
if [ -x "$SCRIPT" ]; then
    ./"$SCRIPT"
else
    log_error "Script not executable: $SCRIPT"
    chmod +x "$SCRIPT"
fi
```

**원칙 3: 명시적 오류 처리**
```bash
# 에러 발생 시 즉시 중단
set -e
trap 'rollback_on_error' ERR
```

### 2.3 문서화 원칙 (Documentation Principle)

모든 실패와 해결 방법은 문서화되어야 합니다.

**원칙 1: 즉시 기록**
- [ ] 문제 발생 즉시 기록
- [ ] 해결 방법 포함
- [ ] 재발 방지책 포함

**원칙 2: 체계적 정리**
- [ ] 유형별 분류 (파일, 권한, 네트워크 등)
- [ ] 날짜순 인덱싱
- [ ] 검색 가능한 키워드

**원칙 3: 지식 공유**
- [ ] 팀 전체 공유
- [ ] 정기적 리뷰
- [ ] 온보딩 자료 활용

---

## 3. 검증 프로세스 (Validation Process)

### 3.1 Pre-Commit 검증 (커밋 전)

Windows 개발 환경에서 커밋 전 실행:

```powershell
# 1. 파일명 일치 확인
ls forms-interface/*.css | ForEach-Object {
    if ($_.Name -ne "styles.css") {
        Write-Host "Unexpected CSS file: $($_.Name)" -ForegroundColor Red
        exit 1
    }
}

# 2. Git 상태 확인
git status --porcelain
if ($LASTEXITCODE -eq 0) {
    Write-Host "No uncommitted changes" -ForegroundColor Green
}

# 3. 캐시 버전 확인
Select-String -Path "forms-interface/index.html" -Pattern 'script\.js\?v=' |
    Select-Object -First 1
```

### 3.2 Pre-Deploy 검증 (배포 전)

Raspberry Pi 배포 환경에서 배포 전 실행:

```bash
#!/bin/bash
# pre-deploy-check.sh

echo "==================================="
echo "Pre-deployment Validation"
echo "==================================="
echo ""

# 1. 핵심 파일 존재 확인
echo "Checking files..."
for file in forms-interface/index.html forms-interface/script.js forms-interface/styles.css; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file NOT FOUND"
        exit 1
    fi
done

# 2. 스크립트 실행 권한 확인
echo ""
echo "Checking script permissions..."
if [ -x "deploy-and-restart.sh" ]; then
    echo "✓ deploy-and-restart.sh is executable"
else
    echo "⚠ deploy-and-restart.sh is NOT executable"
    chmod +x deploy-and-restart.sh
    echo "✓ Fixed: chmod +x deploy-and-restart.sh"
fi

# 3. 네트워크 연결 확인
echo ""
echo "Checking network..."
if ping -c 1 github.com &> /dev/null; then
    echo "✓ GitHub is reachable"
else
    echo "✗ Cannot reach GitHub"
    exit 1
fi

# 4. 웹 서버 상태 확인
echo ""
echo "Checking web server..."
if systemctl is-active --quiet nginx; then
    echo "✓ nginx is running"
else
    echo "⚠ nginx is not running"
fi

echo ""
echo "All checks passed! Ready to deploy."
```

### 3.3 Post-Deploy 검증 (배포 후)

배포 완료 후 실행:

```bash
#!/bin/bash
# post-deploy-check.sh

echo "==================================="
echo "Post-deployment Verification"
echo "==================================="
echo ""

# 1. 심볼릭 링크 확인
echo "Checking symbolic link..."
if [ -L "/var/www/html/forms" ]; then
    echo "✓ Symbolic link exists"
    readlink -f /var/www/html/forms
else
    echo "✗ Symbolic link not found"
    exit 1
fi

# 2. HTTP 접속 테스트
echo ""
echo "Testing HTTP access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/forms/index.html)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ HTTP 200 OK"
else
    echo "✗ HTTP $HTTP_CODE"
    exit 1
fi

# 3. 캐시 버전 확인
echo ""
echo "Verifying cache version..."
DEPLOYED_VERSION=$(grep -oP 'script\.js\?v=\K[0-9.]+' /var/www/html/forms/index.html)
echo "Deployed version: $DEPLOYED_VERSION"

# 4. 파일 권한 확인
echo ""
echo "Checking file permissions..."
INDEX_PERM=$(stat -c "%a" /var/www/html/forms/index.html)
if [ "$INDEX_PERM" = "444" ]; then
    echo "✓ Read-only permissions set (444)"
else
    echo "⚠ Permissions: $INDEX_PERM"
fi

# 5. 브라우저 접속 테스트
echo ""
echo "Testing external access..."
EXTERNAL_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://forms.abyz-lab.work)
if [ "$EXTERNAL_CODE" = "200" ]; then
    echo "✓ External access successful"
else
    echo "⚠ External HTTP $EXTERNAL_CODE"
fi

echo ""
echo "Deployment verification complete!"
```

---

## 4. 워크플로우 개선 (Workflow Improvements)

### 4.1 표준 개발 및 배포 워크플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                    Windows 개발 환경                            │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 1. 코드 수정  │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 2. 로컬 검증 │
                    │   - 파일 존재│
                    │   - 버전 확인│
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 3. Git 커밋 │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │4. windows-   │
                    │   deploy.bat │
                    │ (버전 증가)  │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 5. Git 푸시  │
                    └──────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub 원격 저장소                             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Raspberry Pi 배포 환경                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 6. git pull  │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 7. Pre-deploy│
                    │   체크리스트  │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 8. deploy-   │
                    │   and-restart│
                    │   .sh 실행   │
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 9. Post-     │
                    │   deploy 검증│
                    └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ 10. 브라우저 │
                    │     확인     │
                    └──────────────┘
```

### 4.2 Git 워크플로우 개선

**문제:** git pull 시 머지 충돌 반복 발생

**해결:** stash + reset 방식으로 전환

```bash
# 기존 방식 (문제 있음)
git pull origin main  # 머지 충돌 발생 가능

# 개선된 방식
if ! git diff --quiet || ! git diff --cached --quiet; then
    git stash push -u -m "auto-stash-$(date +%Y%m%d_%H%M%S)"
fi
git fetch origin main
git reset --hard origin/main
```

**장점:**
- 머지 충돌 완전 회피
- 로컬 변경사항 자동 백업
- 원격 저장소 상태로 완전히 동기화

### 4.3 테스트 전략 통합

**단위 테스트 (Unit Tests):**
- 파일 권한 설정 로직
- 캐시 버전 증가 로직
- 버전 파싱 로직

**통합 테스트 (Integration Tests):**
- 전체 배포 워크플로우
- Git 충돌 해결
- 롤백 메커니즘

**보안 테스트 (Security Tests):**
- 권한 에스컬레이션 방지
- 입력 검증
- 취약점 스캔

---

## 5. 실수 방지 체크리스트 (Mistake Prevention Checklist)

### 5.1 공통 실패 패턴

| 실패 패턴 | 증상 | 방지책 |
|----------|------|--------|
| 파일명 불일치 | `No such file or directory` | [ ] `ls -la`로 실제 파일명 확인 후 코드 작성 |
| 실행 권한 소실 | `Permission denied` | [ ] git pull 후 `chmod +x *.sh` 실행 |
| Git 머지 충돌 | `would be overwritten by merge` | [ ] stash + reset 방식 사용 |
| 권한 문제 | `Permission denied (os error 13)` | [ ] `$HOME` 디렉토리 사용 |
| 캐시 문제 | 변경사항 반영 안 됨 | [ ] `Ctrl+Shift+R` 강력 새로고침 |

### 5.2 Pre-Commit 체크리스트

코드 수정 후 Git 커밋 전:

- [ ] 모든 파일이 Windows 개발 환경에 존재하는지 확인
- [ ] 파일명이 정확한지 확인 (대소문자 포함)
- [ ] Git 상태 확인 (`git status`)
- [ ] 변경사항 로컬에서 테스트
- [ ] 캐시 버전 증가 필요 시 windows-deploy.bat 실행

### 5.3 Pre-Deploy 체크리스트

Raspberry Pi에서 배포 전:

- [ ] 핵심 파일 존재 확인 (`ls -la forms-interface/`)
- [ ] 스크립트 실행 권한 확인 (`ls -la *.sh`)
- [ ] 실행 권한 없으면 부여 (`chmod +x deploy-and-restart.sh`)
- [ ] 네트워크 연결 확인 (`ping github.com`)
- [ ] 웹 서버 상태 확인 (`sudo systemctl status nginx`)
- [ ] Pre-flight 체크리스트 실행

### 5.4 Post-Deploy 체크리스트

배포 완료 후:

- [ ] 심볼릭 링크 확인 (`ls -la /var/www/html/forms`)
- [ ] HTTP 접속 테스트 (`curl -I http://localhost/forms/`)
- [ ] 캐시 버전 확인
- [ ] 파일 권한 확인 (`ls -la forms-interface/`)
- [ ] 브라우저 실제 접속 확인

---

## 6. 롤백 절차 (Rollback Procedures)

### 6.1 자동 롤백

deploy-and-restart.sh에 이미 통합됨:

```bash
trap 'rollback_on_error' ERR

rollback_on_error() {
    echo "Deployment failed. Rolling back..."
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        rm -f "$DEPLOY_LINK"
        ln -sf "$BACKUP_DIR" "$DEPLOY_LINK"
        echo "Rolled back to: $BACKUP_DIR"
    fi
    exit 1
}
```

### 6.2 수동 롤백

배포 실패 시 수동 롤백 절차:

```bash
# 1. 최신 백업 찾기
LATEST_BACKUP=$(ls -dt /var/www/html/forms.backup.* 2>/dev/null | head -1)

# 2. 백업 확인
ls -la "$LATEST_BACKUP"

# 3. 롤백 실행
sudo rm /var/www/html/forms
sudo ln -sf "$LATEST_BACKUP" /var/www/html/forms

# 4. 롤백 확인
ls -la /var/www/html/forms
curl -I http://localhost/forms/index.html
```

---

## 7. 스킬 등록 가이드 (Skill Registration Guide)

### 7.1 등록 추천 스킬

다음 스킬들을 .claude/skills/에 등록하여 재사용성을 높이세요:

#### 스킬 1: Pre-Deployment Validation

**파일:** `.claude/skills/moai-checklist-pre-deployment.md`

**목적:** 배포 전 필수 검증 자동화

**트리거:**
- keywords: ["deploy", "deployment", "배포"]
- phases: ["run"]

#### 스킬 2: Cross-Platform Development

**파일:** `.claude/skills/moai-pattern-cross-platform.md`

**목적:** Windows ↔ Linux 간 파일 시스템 차이 처리

**트리거:**
- keywords: ["windows", "linux", "cross-platform", "filesystem"]
- agents: ["expert-backend", "expert-devops"]

#### 스킬 3: Deployment Troubleshooting

**파일:** `.claude/skills/moai-workflow-deployment-troubleshooting.md`

**목적:** 배포 실패 시 원인 분석 및 해결

**트리거:**
- keywords: ["error", "fail", "troubleshoot", "debug"]
- phases: ["run"]

### 7.2 스킬 등록 절차

```bash
# 1. 스킬 디렉토리 생성
mkdir -p .claude/skills

# 2. 스킬 파일 생성
touch .claude/skills/moai-checklist-pre-deployment.md

# 3. 스킬 등록 (Claude Code가 자동으로 로드)
```

---

## 8. 개선 사항 추적 (Improvement Tracking)

### 8.1 구현된 개선 사항

| 개선 항목 | 구현 상태 | 파일 | 완료일 |
|----------|----------|------|--------|
| Pre-deployment 체크리스트 | ✅ 완료 | docs/PRE_DEPLOYMENT_CHECKLIST.md | 2026-01-28 |
| 문제 해결 기록 문서화 | ✅ 완료 | DEPLOYMENT_GUIDE.md 6.11 | 2026-01-28 |
| 개발 방법론 가이드 | ✅ 완료 | docs/DEVELOPMENT_METHODOLOGY.md | 2026-01-28 |
| Git 워크플로우 개선 | ✅ 완료 | deploy-and-restart.sh | 2026-01-28 |
| 자동 롤백 메커니즘 | ✅ 완료 | deploy-and-restart.sh | 2026-01-28 |
| 파일명 일치 검증 | ✅ 완료 | 전체 코드베이스 | 2026-01-28 |

### 8.2 향후 개선 계획

| 개선 항목 | 우선순위 | 예상 완료일 |
|----------|----------|------------|
| 스킬 등록 | 중간 | TBD |
| CI/CD 파이프라인 | 낮음 | TBD |
| 모니터링 대시보드 | 낮음 | TBD |
| 자화상 testing | 높음 | TBD |

---

## 9. 교훈 및 정리 (Lessons Learned)

### 9.1 주요 교훈

1. **환경 불일치는 치명적이다**
   - Windows와 Linux 간 파일 시스템 차이를 항상 인지해야 함
   - 두 환경 모두에서 검증해야 함

2. **검증 없는 배포는 실패를 부른다**
   - Pre-flight 체크리스트는 필수
   - 자동화된 검증이 안전장치

3. **실패는 자산이다**
   - 모든 실패를 문서화하면 패턴이 보임
   - 문서화된 실패는 재발 방지의 열쇠

4. **방어적 프로그래밍이 필수**
   - 항상 존재 확인 후 조작
   - 명시적 오류 처리
   - 롤백 계획 항상 준비

### 9.2 개발 철학

> **"검증은 배포의 일부가 아니라, 배포 그 자체다."**

> **"실패를 반복하지 않는 것이 진정한 전문가다."**

> **"문서화되지 않은 지식은 존재하지 않는다."**

---

## 10. 참고 자료 (References)

- [PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md) - 배포 전 필수 검증 체크리스트
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - 전체 배포 가이드 (특히 6.11 문제 해결 기록)
- [deploy-and-restart.sh](../deploy-and-restart.sh) - 메인 배포 스크립트
- [windows-deploy.bat](../windows-deploy.bat) - Windows 배포 스크립트

---

## 부록: 빠른 참조 (Quick Reference)

### 자주 사용하는 명령어

```bash
# 파일 존재 확인
ls -la forms-interface/

# 실행 권한 확인
ls -la *.sh

# 실행 권한 부여
chmod +x deploy-and-restart.sh

# Git 상태 확인
git status

# Git stash
git stash push -u -m "message"

# Git reset (충돌 회피)
git fetch origin main
git reset --hard origin/main

# 심볼릭 링크 확인
ls -la /var/www/html/forms

# HTTP 테스트
curl -I http://localhost/forms/index.html

# 캐시 버전 확인
grep -oP 'script\.js\?v=\K[0-9.]+' forms-interface/index.html

# nginx 재시작
sudo systemctl restart nginx

# 로그 확인
tail -f $HOME/mcp-agent-deploy.log
```

---

**문서 버전:** 1.0
**마지막 업데이트:** 2026-01-28
**유지 관리자:** 개발 팀
**다음 리뷰:** 2026-02-28
