# 배포 시스템 테스트 스위트 (Deployment System Test Suite)

> forms-interface 자동 배포 시스템을 위한 포괄적인 테스트 프레임워크

---

## 개요

이 테스트 스위트는 Windows(개발 환경)와 Raspberry Pi(배포 환경) 간의 자동화된 배포 시스템의 품질을 보장하기 위해 설계되었습니다.

**테스트 커버리지:**
- 단위 테스트 (Unit Tests): 개별 함수 로직 검증
- 통합 테스트 (Integration Tests): 전체 배포 워크플로우 검증
- 엣지 케이스 (Edge Cases): 네트워크 실패, 디스크 공간 부족 등
- 보안 테스트 (Security Tests): 파일 권한, 민감 정보 보호
- 성능 테스트 (Performance Tests): 배포 시간, 자원 사용량

---

## 빠른 시작

### 1. 모든 테스트 실행

```bash
cd tests/deployment
./run-all-tests.sh
```

### 2. 특정 카테고리 테스트 실행

```bash
# 단위 테스트만 실행
./run-unit-tests.sh

# 통합 테스트만 실행
./run-integration-tests.sh

# 엣지 케이스만 실행
./run-edge-case-tests.sh

# 보안 테스트만 실행
./run-security-tests.sh

# 성능 테스트만 실행
./run-performance-tests.sh
```

---

## 디렉토리 구조

```
tests/deployment/
├── README.md                          # 이 파일
├── TEST_STRATEGY.md                   # 테스트 전략 문서
├── TEST_EXECUTION_GUIDE.md            # 테스트 실행 가이드
├── run-all-tests.sh                   # 메인 테스트 러너
├── run-unit-tests.sh                  # 단위 테스트 러너
├── run-integration-tests.sh           # 통합 테스트 러너
├── run-edge-case-tests.sh            # 엣지 케이스 러너
├── run-security-tests.sh             # 보안 테스트 러너
├── run-performance-tests.sh          # 성능 테스트 러너
├── unit/                             # 단위 테스트
│   ├── test_git_conflict_detection.sh
│   ├── test_cache_version_bump.sh
│   ├── test_file_permissions.sh
│   └── test_symbolic_link.sh
├── integration/                       # 통합 테스트
│   └── test_full_deployment_workflow.sh
├── edge_cases/                       # 엣지 케이스
│   ├── test_network_failures.sh
│   └── test_disk_space.sh
├── security/                         # 보안 테스트
│   └── test_file_permissions_security.sh
├── performance/                      # 성능 테스트
│   └── test_deployment_performance.sh
├── results/                          # 테스트 결과 (자동 생성)
│   ├── test-summary-*.txt
│   └── test-summary-*.html
└── logs/                             # 테스트 로그 (자동 생성)
    └── *-*.log
```

---

## 테스트 목록

### 단위 테스트 (Unit Tests)

| 테스트 파일 | 설명 | 테스트 수 | 실행 시간 |
|-----------|------|---------|---------|
| `test_git_conflict_detection.sh` | Git 충돌 감지 및 해결 로직 | 6 | ~10초 |
| `test_cache_version_bump.sh` | 캐시 버전 파싱 및 증가 로직 | 6 | ~5초 |
| `test_file_permissions.sh` | 파일 권한 설정 로직 | 8 | ~5초 |
| `test_symbolic_link.sh` | 심볼릭 링크 생성 및 백업 로직 | 10 | ~5초 |

### 통합 테스트 (Integration Tests)

| 테스트 파일 | 설명 | 테스트 수 | 실행 시간 |
|-----------|------|---------|---------|
| `test_full_deployment_workflow.sh` | Windows → GitHub → Raspberry Pi 전체 워크플로우 | 15 | ~30초 |

### 엣지 케이스 테스트 (Edge Cases)

| 테스트 파일 | 설명 | 테스트 수 | 실행 시간 |
|-----------|------|---------|---------|
| `test_network_failures.sh` | 네트워크 연결 실패 처리 | 10 | ~20초 |
| `test_disk_space.sh` | 디스크 공간 부족 처리 | 10 | ~15초 |

### 보안 테스트 (Security Tests)

| 테스트 파일 | 설명 | 테스트 수 | 실행 시간 |
|-----------|------|---------|---------|
| `test_file_permissions_security.sh` | 파일 권한 보안 검증 | 12 | ~10초 |

### 성능 테스트 (Performance Tests)

| 테스트 파일 | 설명 | 테스트 수 | 실행 시간 |
|-----------|------|---------|---------|
| `test_deployment_performance.sh` | 배포 성능 메트릭 측정 | 12 | ~60초 |

---

## 테스트 실행 방법

### 사전 요구사항

**Raspberry Pi (Linux):**
```bash
# Bash shell (기본 설치됨)
# bc 계산기 (숫자 연산에 필요)
sudo apt-get install bc

# Git (이미 설치되어 있음)
# nginx 또는 apache2 (이미 설치되어 있음)
```

**Windows:**
```powershell
# Git for Windows
# PowerShell 5.0 이상
```

### 실행 권한 설정

```bash
chmod +x tests/deployment/*.sh
chmod +x tests/deployment/unit/*.sh
chmod +x tests/deployment/integration/*.sh
chmod +x tests/deployment/edge_cases/*.sh
chmod +x tests/deployment/security/*.sh
chmod +x tests/deployment/performance/*.sh
```

### 테스트 실행

**모든 테스트 실행:**
```bash
cd tests/deployment
./run-all-tests.sh
```

**개별 테스트 실행:**
```bash
./unit/test_git_conflict_detection.sh
```

**백그라운드 실행:**
```bash
nohup ./run-all-tests.sh > logs/background-run.log 2>&1 &
```

---

## 결과 확인

### 결과 파일 위치

```
tests/deployment/results/
├── test-summary-20260127_143022.txt    # 텍스트 요약
└── test-summary-20260127_143022.html   # HTML 보고서
```

### 결과 보고서

**텍스트 보고서:**
- 전체 테스트 결과 요약
- 통과/실패 테스트 목록
- 로그 파일 위치

**HTML 보고서:**
- 대화형 웹 인터페이스
- 색상 코딩된 결과
- 성능 메트릭 차트

---

## 테스트 기준

### 성공 기준

| 테스트 유형 | 최소 커버리지 | 통과 기준 |
|-----------|-------------|---------|
| 단위 테스트 | 80% | 100% 통과 |
| 통합 테스트 | 70% | 100% 통과 |
| 엣지 케이스 | 60% | 90% 통과 |
| 보안 테스트 | 100% | 100% 통과 |
| 성능 테스트 | N/A | 모든 기준 충족 |

### 성능 기준

- **Windows 배포:** < 30초
- **Raspberry Pi 배포:** < 60초
- **전체 워크플로우:** < 2분
- **메모리 사용:** < 100MB
- **CPU 사용:** < 80%

---

## CI/CD 통합

### GitHub Actions

```yaml
name: Deployment Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          chmod +x tests/deployment/run-all-tests.sh
          ./tests/deployment/run-all-tests.sh
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: tests/deployment/results/
```

### GitLab CI

```yaml
test:
  script:
    - chmod +x tests/deployment/run-all-tests.sh
    - ./tests/deployment/run-all-tests.sh
  artifacts:
    paths:
      - tests/deployment/results/
```

---

## 문제 해결

### 일반적인 문제

**문제:** `Permission denied`
```bash
# 해결: 실행 권한 부여
chmod +x tests/deployment/*.sh
chmod +x tests/deployment/unit/*.sh
```

**문제:** `command not found: bc`
```bash
# 해결: bc 설치
sudo apt-get install bc  # Ubuntu/Debian
sudo yum install bc      # CentOS/RHEL
```

**문제:** `fatal: not a git repository`
```bash
# 해결: Git 저장소 확인
cd /path/to/mcp-agent-server
git status
```

### 로그 확인

```bash
# 최근 테스트 로그 확인
tail -f tests/deployment/logs/*.log

# 특정 테스트 로그 확인
cat tests/deployment/logs/test_git_conflict_detection-*.log
```

---

## 기여

### 새로운 테스트 추가

1. 테스트 파일 생성
```bash
# 단위 테스트 예시
cat > tests/deployment/unit/test_new_feature.sh << 'EOF'
#!/bin/bash
# Unit Test: New Feature
# Tests new feature logic

ASSERT_PASS=0
ASSERT_FAIL=0

# ... 테스트 코드 ...

echo "Passed: $ASSERT_PASS"
echo "Failed: $ASSERT_FAIL"
EOF

chmod +x tests/deployment/unit/test_new_feature.sh
```

2. 테스트 실행
```bash
./unit/test_new_feature.sh
```

3. 결과 확인
```bash
cat tests/deployment/logs/test_new_feature-*.log
```

---

## 참고 자료

- [테스트 전략 문서](TEST_STRATEGY.md)
- [테스트 실행 가이드](TEST_EXECUTION_GUIDE.md)
- [배포 가이드](../../DEPLOYMENT_GUIDE.md)

---

## 라이선스

이 테스트 스위트는 메인 프로젝트와 동일한 라이선스를 따릅니다.

---

## 버전

- **현재 버전:** 1.0.0
- **마지막 수정:** 2026-01-27
- **유지 관리자:** MoAI Testing Team
