# MCP-Agent-Server: AI 협업 개발 환경

`mcp-agent-server`는 Claude, Copilot, Gemini, Perplexity 등 여러 AI 모델을 개발 에이전트로 활용하여, 복잡한 소프트웨어 개발 과제를 협업을 통해 해결하는 것을 목표로 하는 프로젝트입니다.

---

## 📚 프로젝트 문서 구조 `[2026-01-13 추가]`

| 문서 | 설명 | 상태 |
|:---|:---|:---|
| **[README.md](README.md)** | 프로젝트 개요 및 시작 가이드 | 프로젝트 진입점 |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | 시스템 아키텍처 및 설계 | 시스템 설계 이해 |
| **[PLAN.md](PLAN.md)** | 108단계 구축 계획 | 실행 계획 및 진행 추적 |
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | 배포, 네트워크, 구축 가이드 | 실제 구축 방법 |
| **[DEVOPS_INTEGRATION.md](DEVOPS_INTEGRATION.md)** | Gitea/Redmine API 연동 가이드 | DevOps 자동화 |
| **[issue-register-prd.md](issue-register-prd.md)** | 외부 이슈 등록 시스템 PRD | ✅ 보완 완료 (v1.1.0) |
| **[mcp-server-prd.md](mcp-server-prd.md)** | 하드웨어 개발 워크플로우 자동화 시스템 PRD | ✅ 재구성 완료 (v2.0.0) |
| **[PRD-INTEGRATION-GUIDE.md](PRD-INTEGRATION-GUIDE.md)** | 두 PRD 간 통합 포인트 정리 | ✅ 작성 완료 |

**문서 통합 이력 (2026-01-13):**
- ~~NETWORK_TOPOLOGY.md~~ → DEPLOYMENT_GUIDE.md에 통합
- ~~n8n_cloudflare_tunnel_setup.md~~ → DEPLOYMENT_GUIDE.md에 통합
- ~~PROJECT_ANALYSIS_REPORT.md~~ → 삭제 (일회성 분석)
- ~~claude-review_report.md~~ → 삭제 (중복 분석)

## 📝 문서 변경 이력

**2026-01-12: 하드웨어 개발 워크플로우 자동화 아키텍처로 확장** `[2026-01-12 업데이트]`
- 기존 클라우드 AI 중심에서 로컬 LLM + IDE AI + 하드웨어 검증 통합 아키텍처로 변경 `[2026-01-12 추가]`
- Claude Code, GitHub Copilot 구독 활성 (1년) `[2026-01-12 추가]`
- Tailscale VPN 기반 네트워크 통합 (모든 장비 SSH 연결) `[2026-01-12 추가]`
- Synology NAS의 Gitea + Redmine DevOps 통합 `[2026-01-12 추가]`
- Cloudflare Tunnel 도입으로 포트 포워딩/DDNS 불필요
- Raspberry Pi 5를 물리적 호스팅 서버로 결정
- 모든 Phase에 n8n 워크플로우 통합 (계획)

**현재 구축 상태 (2026-01-26 기준):**
- ✅ Raspberry Pi 5 서버 구축 완료
- ✅ n8n Docker 컨테이너 배포 완료
- ✅ Cloudflare Tunnel 구축 완료 (api.abyz-lab.work, forms.abyz-lab.work) `[2026-01-26 추가]`
- ✅ 외부 HTTPS 접속 가능 (https://api.abyz-lab.work, https://forms.abyz-lab.work) `[2026-01-26 추가]`
- ✅ Forms 시스템 배포 완료 (이슈 제출 폼 + 이메일 알림) `[2026-01-26 추가]`
- ✅ Gmail SMTP 통합 완료 (hnabyz2023@gmail.com → drake.lee@abyzr.com 자동 전달) `[2026-01-26 추가]`
- ✅ Claude Code, GitHub Copilot 구독 활성 (1년) `[2026-01-12 추가]`
- ✅ Tailscale VPN 네트워크 구축 완료 (모든 장비 SSH 연결) `[2026-01-12 추가]`
- ✅ Synology NAS (Gitea + Redmine) 구축 완료 `[2026-01-12 추가]`
- ⏳ ASUS GX10 + GLM 4.7B 설정 예정 `[2026-01-12 추가]`
- ⏳ 하드웨어 검증 레이어 (Jetson, i.MX8MP+FPGA) 연동 예정 `[2026-01-12 추가]`
- ⏳ 빌드 자동화 (Yocto, Vivado) 연동 예정 `[2026-01-12 추가]`

---

## 시스템 인프라 구성

> **🆕 2026-01-12 업데이트:** 하드웨어 개발 워크플로우 자동화 아키텍처
>
> **핵심 특징:** n8n + 로컬 LLM + IDE AI + 하드웨어 검증 + DevOps 통합

**현재 구축 환경 (2026-01-12 기준):**
- **워크플로우 엔진:** n8n Docker 컨테이너 (Raspberry Pi 5, Port 5678) `[완료: 2026-01-12]`
- **외부 접속:** Cloudflare DNS + Tunnel (api.abyz-lab.work) `[완료: 2026-01-12]`
- **네트워크:** Tailscale VPN (모든 장비 SSH 연결 가능) `[완료: 2026-01-12]` `[2026-01-12 추가]`
- **DevOps:** Synology NAS (Gitea + Redmine) `[완료: 2026-01-12]` `[2026-01-12 추가]`

**3계층 AI 에이전트 + DevOps 통합:** `[2026-01-12 추가]`
1. **IDE 통합 AI:** Claude Code, GitHub Copilot (실시간 코딩) `[구독 활성: 2026-01-12]`
2. **로컬 LLM:** ASUS GX10 GLM 4.7B (반복 작업, 로그 분석) `[계획: 미구축]`
3. **클라우드 AI:** Claude/Gemini/OpenAI API (복잡한 작업 백업) `[계획: 미구축]`
4. **Git 저장소:** Gitea (Synology NAS, 셀프 호스팅) `[완료: 기존 설치]`
5. **이슈 관리:** Redmine (Synology NAS) `[완료: 기존 설치]`
6. **하드웨어 검증:** Jetson Orin Nano, i.MX8MP+FPGA (SSH 원격 테스트) `[계획: 미구축]`
7. **빌드 자동화:** Yocto Build PC, FPGA Dev PC (Vivado/Questa, SSH 원격 빌드) `[계획: 미구축]`

## 개발 로드맵 (Development Roadmap)

프로젝트는 총 4단계의 점진적인 개발 계획을 따릅니다.

---

### **Phase 1: 핵심 기반 구축 (Core Foundation)** `[2026-01-12 수정]`

> **🔄 변경사항:** 기존 Express 서버 단독 구성에서 n8n + AI Agent Server 통합 구성으로 변경
>
> **진행 상황:** 1단계 인프라 완료 (Raspberry Pi 5 + n8n + Cloudflare Tunnel 구축)

시스템의 기본 골격을 만들고, n8n과 단일 AI 에이전트를 연동하여 최소 기능의 워크플로우를 구현합니다.

*   **1. n8n 워크플로우 엔진 구축** `[완료: 2026-01-12]`
    *   ✅ Raspberry Pi 5에 Docker 및 n8n 컨테이너 배포 `[완료: 2026-01-12]`
    *   ✅ Cloudflare Tunnel 생성 및 ingress 설정 `[완료: 2026-01-12]`
    *   ✅ Cloudflare DNS CNAME 설정 (api.abyz-lab.work) `[완료: 2026-01-12]`
    *   ✅ HTTPS 외부 접속 확인 완료 `[완료: 2026-01-12]`

*   **2. AI 에이전트 서버 구축** `[계획: 미구축]`
    *   ⏳ `Node.js (Express)` + `TypeScript` 기반 백엔드 서버 설정 `[계획: 미구축]`
    *   ⏳ n8n Webhook을 통해 작업 요청을 수신하는 API 엔드포인트 구현 `[계획: 미구축]`
    *   ⏳ 작업 상태를 추적하고 결과를 n8n으로 반환하는 로직 구현 `[계획: 미구축]`

*   **3. 첫 번째 AI 에이전트 연동 (First Agent Integration)** `[계획: 미구축]`
    *   ⏳ 주력으로 사용할 AI 모델 (예: Gemini Pro, Claude)의 API 어댑터 개발 `[계획: 미구축]`
    *   ⏳ n8n을 통한 AI API 호출 워크플로우 구성 `[계획: 미구축]`
    *   ⏳ 어댑터는 `(인증) -> (요청 형식 표준화) -> (API 호출) -> (응답 파싱)`의 역할을 수행 `[계획: 미구축]`

*   **4. 파일 시스템 제어 (File System Control)** `[계획: 미구축]`
    *   ⏳ AI 에이전트가 지정된 워크스페이스 내의 파일을 읽고, 수정하며, 생성할 수 있는 기능 구현 `[계획: 미구축]`
    *   ⏳ n8n을 통한 파일 작업 결과 모니터링 `[계획: 미구축]`

---

### **Phase 2: 멀티 에이전트 확장 (Multi-Agent Expansion)** `[계획: 미구축]`

여러 종류의 AI 에이전트를 추가하고, n8n 워크플로우를 통해 작업 성격에 따라 최적의 에이전트를 선택하는 기능을 구현합니다.

*   **1. AI 에이전트 어댑터 추가 (Additional Agent Adapters)** `[계획: 미구축]`
    *   ⏳ `Claude`, `Gemini`, `Perplexity`, `OpenAI` 등 다양한 AI 모델 어댑터 구현 `[계획: 미구축]`
    *   ⏳ 각 어댑터를 n8n HTTP Request 노드로 통합 `[계획: 미구축]`

*   **2. n8n 기반 에이전트 라우팅 로직** `[계획: 미구축]`
    *   ⏳ n8n Switch/IF 노드를 활용한 작업 유형별 라우팅 워크플로우 구현 `[계획: 미구축]`
    *   ⏳ 작업 유형: `코드 생성`, `디버깅`, `문서 작성`, `코드 리뷰` 등 `[계획: 미구축]`
    *   ⏳ 각 유형에 최적화된 AI 에이전트 자동 선택 `[계획: 미구축]`

*   **3. 공유 워크스페이스 (Shared Workspace)** `[계획: 미구축]`
    *   ⏳ 모든 에이전트가 동일한 파일 상태를 공유하는 워크스페이스 관리 `[계획: 미구축]`
    *   ⏳ n8n을 통한 파일 동기화 및 충돌 방지 로직 구현 `[계획: 미구축]`

---

### **Phase 3: 사용자 인터페이스 및 상호작용 (UI & Interaction)** `[계획: 미구축]`

사용자가 AI의 개발 과정을 모니터링하고, 결과를 검토하며, 직접 제어할 수 있는 인터페이스를 제공합니다.

*   **1. 사용자 인터페이스 개발 (UI Development)** `[계획: 미구축]`
    *   ⏳ **n8n 기본 UI:** n8n 내장 Form/Webhook 노드를 활용한 기본 인터페이스 `[계획: 미구축]`
    *   ⏳ **초기:** `CLI (명령줄 인터페이스)` 구현 (n8n Webhook 호출) `[계획: 미구축]`
    *   ⏳ **장기:** `웹 기반 대시보드 (React/Vue)` 구축 및 n8n API 연동 `[계획: 미구축]`

*   **2. 인터랙티브 워크플로우 (Interactive Workflow)** `[계획: 미구축]`
    *   ⏳ 사용자가 `개발 목표`를 입력하면, n8n 워크플로우가 작업을 해석하여 AI 에이전트에게 할당 `[계획: 미구축]`
    *   ⏳ n8n의 실시간 로그 및 대시보드를 통한 작업 진행 상황 모니터링 `[계획: 미구축]`
    *   ⏳ AI가 제안한 코드 변경사항(`diff`)을 n8n 승인 노드를 통해 `승인(Apply)` 또는 `반려(Reject)` `[계획: 미구축]`
    *   ⏳ Cloudflare를 통한 외부 접근 시 보안 인증 및 접근 제어 `[계획: 미구축]`

---

### **Phase 4: 개발 자동화 및 고도화 (Automation & Advanced Features)** `[계획: 미구축]`

복잡한 개발 과제를 AI가 스스로 하위 작업으로 나누고, n8n 워크플로우를 통한 에이전트 간 협업으로 해결하도록 시스템을 고도화합니다.

*   **1. n8n 기반 자동 작업 분해 (Automatic Task Decomposition)** `[계획: 미구축]`
    *   ⏳ "로그인 기능 개발"과 같은 복잡한 요청을 n8n 워크플로우가 자동으로 하위 작업으로 분해 `[계획: 미구축]`
    *   ⏳ 분해 로직: `(요구사항 분석) -> (API 설계) -> (코드 작성) -> (테스트 작성) -> (문서화)` `[계획: 미구축]`
    *   ⏳ 각 단계마다 적절한 AI 에이전트 자동 할당 `[계획: 미구축]`

*   **2. n8n 워크플로우 기반 에이전트 협업 (Inter-Agent Collaboration)** `[계획: 미구축]`
    *   ⏳ n8n의 복잡한 워크플로우를 통한 멀티 에이전트 오케스트레이션 `[계획: 미구축]`
    *   ⏳ 예시 워크플로우: `코딩 에이전트` → `리뷰 에이전트` → `테스트 에이전트` → `문서화 에이전트` `[계획: 미구축]`
    *   ⏳ 각 단계의 결과를 다음 에이전트에게 자동 전달 `[계획: 미구축]`

*   **3. 자동 피드백 루프 (Automated Feedback Loop)** `[계획: 미구축]`
    *   ⏳ n8n Error Workflow를 활용한 자동 오류 감지 및 재처리 `[계획: 미구축]`
    *   ⏳ `테스트 실패`, `린트 오류`, `빌드 실패` 시 자동으로 해당 에이전트에게 피드백 `[계획: 미구축]`
    *   ⏳ 최대 재시도 횟수 설정 및 실패 시 사용자 알림 `[계획: 미구축]`