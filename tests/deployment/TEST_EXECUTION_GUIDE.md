# Deployment Test Execution Guide

> **버전:** 1.0.0
> **작성일:** 2026-01-27
> **적용 대상:** forms-interface 배포 시스템

---

## 목차

1. [빠른 시작](#1-빠른-시작)
2. [테스트 환경 설정](#2-테스트-환경-설정)
3. [테스트 실행 방법](#3-테스트-실행-방법)
4. [개별 테스트 실행](#4-개별-테스트-실행)
5. [테스트 결과 확인](#5-테스트-결과-확인)
6. [CI/CD 통합](#6-cicd-통합)
7. [문제 해결](#7-문제-해결)

---

## 1. 빠른 시작

### 1.1 모든 테스트 실행

```bash
# 테스트 디렉토리로 이동
cd tests/deployment

# 모든 테스트 실행
./run-all-tests.sh
```

### 1.2 특정 카테고리 테스트 실행

```bash
# 단위 테스트만 실행
./run-unit-tests.sh

# 통합 테스트만 실행
./run-integration-tests.sh

# 엣지 케이스 테스트만 실행
./run-edge-case-tests.sh

# 보안 테스트만 실행
./run-security-tests.sh

# 성능 테스트만 실행
./run-performance-tests.sh
```

---

## 2. 테스트 환경 설정

### 2.1 Windows 환경 (개발)

**필수 조건:**
- Git for Windows 설치
- PowerShell 5.0 이상
- GitHub 인증 설정 (SSH 또는 PAT)

**설정:**
```powershell
# PowerShell에서 실행
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2.2 Raspberry Pi 환경 (배포)

**필수 조건:**
- Raspberry Pi OS 최신 버전
- Bash shell
- Git, nginx/apache2 설치

**설정:**
```bash
# 테스트 실행 권한 부여
chmod +x tests/deployment/*.sh
chmod +x tests/deployment/unit/*.sh
chmod +x tests/deployment/integration/*.sh
chmod +x tests/deployment/edge_cases/*.sh
chmod +x tests/deployment/security/*.sh
chmod +x tests/deployment/performance/*.sh
```

### 2.3 테스트 결과 디렉토리 생성

```bash
# 결과 저장 디렉토리 생성
mkdir -p tests/deployment/results

# 로그 디렉토리 생성
mkdir -p tests/deployment/logs
```

---

## 3. 테스트 실행 방법

### 3.1 자동 실행 (권장)

**모든 테스트 한 번에 실행:**
```bash
cd tests/deployment
./run-all-tests.sh
```

**출력 예시:**
```
========================================
Deployment Test Suite
========================================
Running all tests...

[1/7] Running unit tests...
[2/7] Running integration tests...
[3/7] Running edge case tests...
[4/7] Running security tests...
[5/7] Running performance tests...
[6/7] Generating report...
[7/7] Cleanup completed.

========================================
Test Suite Summary
========================================
Total Tests: 42
Passed: 40
Failed: 2
Duration: 3m 15s
Result: tests/deployment/results/test-summary-20260127_143022.html
```

### 3.2 수동 실행

**개별 테스트 스크립트 실행:**
```bash
# 단위 테스트: Git 충돌 감지
./tests/deployment/unit/test_git_conflict_detection.sh

# 단위 테스트: 캐시 버전 증가
./tests/deployment/unit/test_cache_version_bump.sh

# 통합 테스트: 전체 배포 워크플로우
./tests/deployment/integration/test_full_deployment_workflow.sh
```

### 3.3 백그라운드 실행

```bash
# nohup으로 백그라운드 실행
nohup ./tests/deployment/run-all-tests.sh > tests/deployment/logs/test-run.log 2>&1 &

# 프로세스 ID 저장
echo $! > tests/deployment/logs/test.pid

# 로그 실시간 확인
tail -f tests/deployment/logs/test-run.log
```

---

## 4. 개별 테스트 실행

### 4.1 단위 테스트

**Git 충돌 감지:**
```bash
./unit/test_git_conflict_detection.sh
```
- 테스트 항목: 6개
- 예상 실행 시간: 10초
- 목적: Git stash, reset 로직 검증

**캐시 버전 증가:**
```bash
./unit/test_cache_version_bump.sh
```
- 테스트 항목: 6개
- 예상 실행 시간: 5초
- 목적: 버전 파싱 및 증가 로직 검증

**파일 권한:**
```bash
./unit/test_file_permissions.sh
```
- 테스트 항목: 8개
- 예상 실행 시간: 5초
- 목적: chmod, chown 로직 검증

**심볼릭 링크:**
```bash
./unit/test_symbolic_link.sh
```
- 테스트 항목: 10개
- 예상 실행 시간: 5초
- 목적: ln -s, 백업 로직 검증

### 4.2 통합 테스트

**전체 배포 워크플로우:**
```bash
./integration/test_full_deployment_workflow.sh
```
- 테스트 항목: 15개
- 예상 실행 시간: 30초
- 목적: Windows → GitHub → Raspberry Pi 전체 흐름 검증

### 4.3 엣지 케이스 테스트

**네트워크 실패:**
```bash
./edge_cases/test_network_failures.sh
```
- 테스트 항목: 10개
- 예상 실행 시간: 20초
- 목적: 연결 타임아웃, DNS 실패 검증

**디스크 공간 부족:**
```bash
./edge_cases/test_disk_space.sh
```
- 테스트 항목: 10개
- 예상 실행 시간: 15초
- 목적: 디스크 공간 확인 및 백업 검증

### 4.4 보안 테스트

**파일 권한 보안:**
```bash
./security/test_file_permissions_security.sh
```
- 테스트 항목: 12개
- 예상 실행 시간: 10초
- 목적: 권한 설정, 민감 정보 보호 검증

### 4.5 성능 테스트

**배포 성능:**
```bash
./performance/test_deployment_performance.sh
```
- 테스트 항목: 12개
- 예상 실행 시간: 60초
- 목적: 배포 시간, 자원 사용량 측정

---

## 5. 테스트 결과 확인

### 5.1 결과 파일 위치

```
tests/deployment/results/
├── unit-test-results.log
├── integration-test-results.log
├── edge-case-results.log
├── security-test-results.log
├── performance-test-results.log
├── test-summary-YYYYMMDD_HHMMSS.html
└── performance-metrics.txt
```

### 5.2 결과 보고서 형식

**텍스트 로그 예시:**
```
========================================
Unit Test: Git Conflict Detection
========================================

Test 1: Detect local changes with git diff --quiet
✓ PASS: Detect local changes with git diff --quiet

Test 2: Stash creation with timestamp message
✓ PASS: Stash created with timestamp message

...

========================================
Test Summary
========================================
Passed: 6
Failed: 0
Total: 6

All tests passed!
```

**HTML 보고서 예시:**
- 녹색: 통과한 테스트
- 빨간색: 실패한 테스트
- 노란색: 경고
- 실행 시간, 메모리 사용량 등 메트릭 포함

### 5.3 성능 메트릭 확인

```bash
# 성능 메트릭 보기
cat tests/deployment/results/performance-metrics.txt
```

**출력 예시:**
```
git_status_time=0.15s
copy_time=0.82s
chmod_time=0.05s
link_time=0.001s
deploy_time=8.45s
io_speed=125.50MB/s
concurrent_time=2.30s
large_file_speed=45.20MB/s
```

### 5.4 테스트 커버리지 확인

```bash
# 커버리지 리포트 생성
./tests/deployment/scripts/generate-coverage.sh
```

---

## 6. CI/CD 통합

### 6.1 GitHub Actions

**`.github/workflows/deployment-tests.yml`:**
```yaml
name: Deployment Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Setup test environment
      run: |
        chmod +x tests/deployment/*.sh
        chmod +x tests/deployment/unit/*.sh
        chmod +x tests/deployment/integration/*.sh
        chmod +x tests/deployment/edge_cases/*.sh
        chmod +x tests/deployment/security/*.sh
        chmod +x tests/deployment/performance/*.sh

    - name: Run unit tests
      run: ./tests/deployment/run-unit-tests.sh

    - name: Run integration tests
      run: ./tests/deployment/run-integration-tests.sh

    - name: Run security tests
      run: ./tests/deployment/run-security-tests.sh

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: tests/deployment/results/
```

### 6.2 GitLab CI

**`.gitlab-ci.yml`:**
```yaml
stages:
  - test

deployment-tests:
  stage: test
  script:
    - chmod +x tests/deployment/*.sh
    - chmod +x tests/deployment/unit/*.sh
    - ./tests/deployment/run-all-tests.sh
  artifacts:
    paths:
      - tests/deployment/results/
    expire_in: 1 week
  only:
    - main
    - develop
    - merge_requests
```

### 6.3 Jenkins Pipeline

**`Jenkinsfile`:**
```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh 'chmod +x tests/deployment/*.sh'
                sh 'chmod +x tests/deployment/unit/*.sh'
            }
        }

        stage('Unit Tests') {
            steps {
                sh './tests/deployment/run-unit-tests.sh'
            }
        }

        stage('Integration Tests') {
            steps {
                sh './tests/deployment/run-integration-tests.sh'
            }
        }

        stage('Security Tests') {
            steps {
                sh './tests/deployment/run-security-tests.sh'
            }
        }

        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'tests/deployment/results/**'
            }
        }
    }

    post {
        always {
            junit 'tests/deployment/results/*.xml'
        }
    }
}
```

---

## 7. 문제 해결

### 7.1 테스트 실행 실패

**문제:** `Permission denied` 에러
**해결:**
```bash
chmod +x tests/deployment/*.sh
chmod +x tests/deployment/unit/*.sh
chmod +x tests/deployment/integration/*.sh
```

### 7.2 Git 관련 에러

**문제:** `fatal: not a git repository`
**해결:**
```bash
cd /path/to/mcp-agent-server
git status
```

### 7.3 의존성 누락

**문제:** `command not found: bc`
**해결:**
```bash
# Ubuntu/Debian
sudo apt-get install bc

# CentOS/RHEL
sudo yum install bc

# macOS
brew install bc
```

### 7.4 디스크 공간 부족

**문제:** 테스트 실행 중 `No space left on device`
**해결:**
```bash
# 디스크 공간 확인
df -h

# 테스트 임시 파일 정리
rm -rf /tmp/test-*
rm -rf tests/deployment/results/*
```

### 7.5 네트워크 관련 에러

**문제:** 네트워크 테스트에서 연결 실패
**해결:**
```bash
# 인터넷 연결 확인
ping -c 3 github.com

# 네트워크 테스트는 네트워크가 없어도 부분적으로 통과할 수 있음
# 이는 정상적인 동작임
```

---

## 8. 테스트 최적화

### 8.1 병렬 실행

```bash
# 단위 테스트 병렬 실행
./unit/test_git_conflict_detection.sh &
./unit/test_cache_version_bump.sh &
./unit/test_file_permissions.sh &
./unit/test_symbolic_link.sh &

wait
echo "All unit tests completed"
```

### 8.2 테스트 필터링

```bash
# 특정 키워드가 포함된 테스트만 실행
grep -r "Test 3:" tests/deployment/unit/*.sh | cut -d: -f1 | sort -u
```

### 8.3 빠른 테스트 실행

```bash
# 단위 테스트만 실행 (가장 빠름)
./run-unit-tests.sh

# 핵심 테스트만 실행 (빠른 피드백)
./unit/test_git_conflict_detection.sh
./unit/test_cache_version_bump.sh
```

---

## 9. 정기 테스트

### 9.1 사전 배포 테스트 체크리스트

- [ ] 단위 테스트 통과 (100%)
- [ ] 통합 테스트 통과 (100%)
- [ ] 보안 테스트 통과 (100%)
- [ ] 성능 테스트 기준 충족
- [ ] 엣지 케이스 테스트 통과 (90% 이상)

### 9.2 주간 테스트 스케줄

**매주:**
- 전체 테스트 스위트 실행
- 성능 메트릭 기록
- 트렌드 분석

**매월:**
- 테스트 커버리지 검토
- 새로운 엣지 케이스 추가
- 테스트 스크립트 최적화

---

## 10. 참고 자료

- [테스트 전략 문서](TEST_STRATEGY.md)
- [배포 가이드](../../DEPLOYMENT_GUIDE.md)
- [Bash 테스팅最佳实践](https://github.com/sstephenson/bats)
- [CI/CD 통합 가이드](../../docs/CI_CD_INTEGRATION.md)
