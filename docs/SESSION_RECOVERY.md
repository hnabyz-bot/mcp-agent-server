# 세션 복구 가이드 (Session Recovery Guide)

> **목적:** Claude Code 세션 컨텍스트 초과로 인한 작업 내용 손실 방지
>
> **마지막 업데이트:** 2026-01-28
>
> **버전:** 1.0

---

## 문제: 세션 컨텍스트 초과

Claude Code를 사용하다 보면 세션이 길어지면 다음과 같은 증상이 발생합니다:

```
Token limit exceeded (200K tokens)
Session needs to be restarted
```

이때 세션을 다시 시작하면 **이전에 작업하던 내용을 모두 잃게 됩니다.**

## 해결: 세션 상태 저장/복구 시스템

이 프로젝트는 세션 상태를 자동으로 저장하고 복구하는 시스템을 갖추고 있습니다.

### 작동 방식

```
┌─────────────────────────────────────────────────────────┐
│ 1. 작업 진행 중                                         │
│    ↓                                                   │
│ 2. 주요 마일스톤 도달 시마다 상태 저장                  │
│    (scripts/session-save.sh save "작업 내용")          │
│    ↓                                                   │
│ 3. 세션 컨텍스트 초과로 세션 재시작 필요               │
│    ↓                                                   │
│ 4. .claude/session_state.json 파일 확인                │
│    ↓                                                   │
│ 5. Claude에게 저장된 상태 알려주기                      │
│    "이전 세션에서 작업하던 내용 복구"                   │
│    ↓                                                   │
│ 6. Claude가 저장된 상태를 읽고 작업 계속                │
└─────────────────────────────────────────────────────────┘
```

---

## 사용 방법

### 1. 세션 상태 저장

작업 중 주요 마일스톤이 있을 때마다 상태를 저장하세요:

```bash
# Git Bash 또는 WSL에서 실행
./scripts/session-save.sh save "작업 내용" "상세 설명"

# 예시:
./scripts/session-save.sh save "배포 자동화 구현" "deploy-and-restart.sh 작성 완료"
./scripts/session-save.sh save "문서화 작업" "DEPLOYMENT_GUIDE.md 6.11 섹션 추가"
```

### 2. 세션 상태 확인

언제든지 저장된 상태를 확인할 수 있습니다:

```bash
# 전체 상태 표시
./scripts/session-save.sh show

# 간단 요약
./scripts/session-save.sh summary
```

### 3. 세션 재시작 후 복구

세션이 재시된된 후, Claude에게 다음과 같이 말씀하세요:

**예시 1: 저장된 상태 확인 요청**
```
"이전 세션에서 작업하던 내용을 .claude/session_state.json에서 읽어서 요약해줘"
```

**예시 2: 작업 계속 요청**
```
"세션 상태 파일(.claude/session_state.json)에 저장된 작업 내용을 기반으로 이어서 작업을 계속해줘"
```

**예시 3: 자동 복구**
```
"Claude, 세션 상태를 자동으로 복구하고 다음 작업을 진행해줘"
```

### 4. 세션 상태 초기화 (선택사항)

모든 작업이 완료되어 상태를 초기화하려면:

```bash
./scripts/session-save.sh clear
```

---

## 세션 상태 파일 구조

`.claude/session_state.json` 파일은 다음 정보를 포함합니다:

```json
{
  "timestamp": "2026-01-28T15:30:00+09:00",
  "last_updated": "2026-01-28 15:30:00",
  "project_dir": "/path/to/project",
  "current_task": "현재 작업 중인 태스크",
  "last_action": "마지막으로 완료한 작업",
  "completed_tasks": ["완료된 작업 목록"],
  "next_steps": ["다음에 해야 할 작업 목록"],
  "key_documents_created": ["생성된 주요 문서들"],
  "notes": ["추가 노트"]
}
```

---

## 자동화된 워크플로우

### 개발자를 위한 권장 작업 흐름

```
1. 작업 시작
   ↓
2. 주요 완료 시마다 상태 저장
   ./scripts/session-save.sh save "완료한 작업" "상세 내용"
   ↓
3. 세션 컨텍스트 50% 이상 사용 시 주의
   ↓
4. 주요 완료 시마다 상태 저장 반복
   ↓
5. 세션 재시작 필요 시
   ↓
6. Claude에게 복구 요청
   ".claude/session_state.json 내용을 읽고 작업 계속"
   ↓
7. 작업 계속
```

---

## Claude가 자동으로 복구하게 하기

### .claude/rules/에 복구 규칙 추가 (선택사항)

`.claude/rules/session-recovery.md` 파일을 생성하여 Claude가 세션 시작 시 자동으로 상태를 확인하도록 할 수 있습니다:

```markdown
---
path: .claude/session_state.json
---

# Session Recovery Rule

When a new session starts:
1. Check if .claude/session_state.json exists
2. If exists, read and display the saved session state
3. Ask user if they want to continue from where they left off
4. Load context from saved state if user confirms
```

---

## 예시: 실제 사용 시나리오

### 시나리오 1: 배포 작업 중 세션 초과

```bash
# 1. 배포 스크립트 작성 완료
./scripts/session-save.sh save "배포 스크립트 작성" "deploy-and-restart.sh 완료, Git 충돌 자동 해결 구현"

# 2. 테스트 실행 중 세션 초과 발생

# 3. 세션 재시작

# 4. Claude에게 말하기:
"./scripts/session-save.sh show 실행 결과를 읽고 작업을 계속해줘"

# 5. Claude가 상태를 읽고 자동으로 작업 계속
```

### 시나리오 2: 문서화 작업 중 세션 초과

```bash
# 1. 문서 작성 중간 저장
./scripts/session-save.sh save "문서화 작업 진행 중" "DEVELOPMENT_METHODOLOGY.md 50% 완료"

# 2. 계속 작업

# 3. 또 다른 중간 저장
./scripts/session-save.sh save "문서화 작업 완료" "DEVELOPMENT_METHODOLOGY.md, PRE_DEPLOYMENT_CHECKLIST.md 작성 완료"

# 4. 세션 재시작 후 복구
```

---

## 모범 사례 (Best Practices)

### ✅ 권장사항

1. **주요 마일스톤마다 저장**
   - 큰 기능 구현 완료 시
   - 문서 작성 완료 시
   - 버그 수정 완료 시
   - 배포 완료 시

2. **상세한 설명 포함**
   ```bash
   # 좋은 예
   ./scripts/session-save.sh save "배포 자동화" "Git stash+reset 방식으로 머지 충돌 해결, 읽기 전용 보호 구현"

   # 나쁜 예
   ./scripts/session-save.sh save "작업 완료"
   ```

3. **정기적으로 저장**
   - 컨텍스트 30% 사용 시 저장 권장
   - 컨텍스트 50% 사용 시 필수 저장
   - 컨텍스트 70% 사용 시 즉시 저장 후 세션 정리

4. **다음 작업 포함**
   ```bash
   ./scripts/session-save.sh save "현재 작업" "완료. 다음: 테스트 작성"
   ```

### ❌ 피해야 할 것

1. **너무 자주 저장**: 매 파일 수정마다 저장은 과함
2. **모호한 설명**: "작업 중", "진행 중" 같은 모호한 설명 피하기
3. **초기화 남용**: 작업 완료 전에 상태 초기화하지 않기

---

## 문제 해결

### 문제 1: session_state.json 파일이 없음

**원인:** 아직 상태를 저장한 적이 없음

**해결:** 첫 상태 저장
```bash
./scripts/session-save.sh save "프로젝트 시작" "초기 설정 완료"
```

### 문제 2: 파일이 깨져서 읽을 수 없음

**해결:** JSON 유효성 검사
```bash
# JSON 유효성 확인
cat .claude/session_state.json | jq .

# 깨진 경우 복구
git checkout .claude/session_state.json
```

### 문제 3: Claude가 파일을 읽지 못함

**해결:** 파일 경로 명시
```
"프로젝트 루트의 .claude/session_state.json 파일을 읽어줘"
```

---

## 추가 도구

### Memory MCP 통합 (고급)

MoAI-ADK는 Memory MCP와 통합되어 있습니다. Memory MCP를 사용하여 세션 간 상태를 저장할 수도 있습니다:

```python
# Memory MCP 사용 예시 (Claude가 자동으로 처리)
mcp__memory__store(
    key="session_current_task",
    value="배포 자동화 구현"
)

# 복구时
mcp__memory__retrieve(key="session_current_task")
```

---

## 참고 자료

- [session-persistence.py](../.claude/hooks/session/session-persistence.py) - Python 훅
- [session-save.sh](../scripts/session-save.sh) - Bash 저장 스크립트
- [DEVELOPMENT_METHODOLOGY.md](DEVELOPMENT_METHODOLOGY.md) - 개발 방법론
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - 배포 가이드

---

**마지막 업데이트:** 2026-01-28
**유지 관리자:** 개발 팀
**버전:** 1.0
