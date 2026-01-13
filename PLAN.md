### **MCP 전체 구축 계획서 (Full Project Plan)**

> **📝 2026-01-13 업데이트:** 번호 재조정 및 Phase 1.5, 2.5 상세 단계 추가 (108단계) `[2026-01-13 재조정]`
> **주요 변경:**
> - 93단계 → 108단계 확장 `[2026-01-13 재조정]`
> - Phase 1-3 번호 중복 제거 (25-30 → 40-45) `[2026-01-13 재조정]`
> - Phase 1.5: DevOps API 연동 8단계 추가 `[2026-01-13 추가]`
> - Phase 2.5: 하드웨어 SSH 연동 7단계 추가 `[2026-01-13 추가]`

---

#### **Phase 0: 인프라 구축 (26단계)** 🆕 `[일부 완료: 2026-01-12]`

**0-1. 기존 완료 항목 (1-11단계)** `[완료: 2026-01-12]`
1.  ✅ `Raspberry Pi 5 OS 설치 및 초기 설정 (Ubuntu/Raspberry Pi OS)` `[완료: 2026-01-12]`
2.  ✅ `Docker 및 Docker Compose 설치` `[완료: 2026-01-12]`
3.  ✅ `n8n Docker 컨테이너 배포 (docker-compose.yml)` `[완료: 2026-01-12]`
4.  ✅ `n8n 초기 설정 및 관리자 계정 생성` `[완료: 2026-01-12]`
5.  ✅ `Cloudflare 계정 설정 및 도메인 준비 (api.abyz-lab.work)` `[완료: 2026-01-12]`
6.  ✅ `cloudflared 설치 및 Tunnel 생성 (abyz-n8n)` `[완료: 2026-01-12]`
7.  ✅ `Cloudflare Tunnel config.yml 설정 (ingress 규칙)` `[완료: 2026-01-12]`
8.  ✅ `Cloudflare DNS CNAME 설정 (api → cfargotunnel.com)` `[완료: 2026-01-12]`
9.  ✅ `cloudflared systemd 서비스 등록 및 자동 시작 설정` `[완료: 2026-01-12]`
10. ✅ `시스템 UDP 버퍼 튜닝 (sysctl.conf)` `[완료: 2026-01-12]`
11. ✅ `n8n 외부 HTTPS 접속 테스트 확인 (https://api.abyz-lab.work)` `[완료: 2026-01-12]`

**0-2. IDE AI 및 네트워크 환경 (12-16단계)** 🆕 `[2026-01-12 추가]`
12. ✅ `Claude Code 구독 활성화 및 VSCode 확장 설치` `[완료: 2026-01-12]`
13. ✅ `GitHub Copilot 구독 활성화 및 IDE 플러그인 설치` `[완료: 2026-01-12]`
14. ✅ `모든 장비에 Tailscale VPN 설치 및 SSH 연결 확인` `[완료: 기존 설치]`
15. ✅ `Synology NAS의 Gitea 접속 확인 (HTTP API 테스트)` `[완료: 기존 설치]`
16. ✅ `Synology NAS의 Redmine 접속 확인 (HTTP API 테스트)` `[완료: 기존 설치]`

**0-3. 로컬 LLM 및 하드웨어 설정 (17-26단계)** 🆕 `[2026-01-12 추가]`
17. ⏳ `ASUS GX10에 GLM 4.7B 모델 설치` `[계획: 미구축]`
18. ⏳ `ASUS GX10에 추론 API 서버 구성 (Flask/FastAPI)` `[계획: 미구축]`
19. ⏳ `n8n에서 ASUS GX10 SSH 연결 테스트 (Execute Command 노드)` `[계획: 미구축]`
20. ⏳ `Jetson Orin Nano 초기 설정 (JetPack 설치, SSH 접속)` `[계획: 미구축]`
21. ⏳ `i.MX8MP + FPGA EVKIT 초기 설정 및 SSH 접속` `[계획: 미구축]`
22. ⏳ `Yocto Build PC 환경 구성 (Ubuntu, Yocto 의존성)` `[계획: 미구축]`
23. ⏳ `FPGA Dev PC 환경 구성 (Vivado, ModelSim/Questa)` `[계획: 미구축]`
24. ⏳ `n8n에서 각 장비로 SSH 명령 실행 테스트 (Execute Command 노드)` `[계획: 미구축]`
25. ⏳ `n8n에서 Gitea API 호출 테스트 (브랜치 생성, 커밋, PR)` `[계획: 미구축]`
26. ⏳ `n8n에서 Redmine API 호출 테스트 (이슈 생성, 상태 업데이트)` `[계획: 미구축]`

---

#### **Phase 1: n8n 워크플로우 및 AI Agent Server 구축 (15단계)** `[계획: 미구축]` `[2026-01-13 재조정]`

**Phase 1-1: AI Agent Server 환경 구축** `[계획: 미구축]`
27. ⏳ `Raspberry Pi 5에 Node.js 설치 (LTS 버전)` `[계획: 미구축]`
28. ⏳ `Node.js 프로젝트 초기화: 'package.json' 파일 생성` `[계획: 미구축]`
29. ⏳ `TypeScript 및 Node.js 타입 라이브러리 설치` `[계획: 미구축]`
30. ⏳ `TypeScript 컴파일러 설정 파일 'tsconfig.json' 생성` `[계획: 미구축]`
31. ⏳ `Express 웹 프레임워크 및 타입 라이브러리 설치` `[계획: 미구축]`
32. ⏳ `소스 코드 관리를 위한 'src' 디렉토리 생성` `[계획: 미구축]`
33. ⏳ `'src/index.ts' 파일에 기본 Express 서버 코드 작성 (n8n과 통신 가능하도록)` `[계획: 미구축]`
34. ⏳ `'package.json'에 서버 빌드 및 실행 스크립트 추가` `[계획: 미구축]`

**Phase 1-2: n8n과 AI Agent Server 통합** `[계획: 미구축]`
35. ⏳ `n8n에서 Webhook 노드 생성 (사용자 요청 수신용)` `[계획: 미구축]`
36. ⏳ `n8n에서 HTTP Request 노드 생성 (AI Agent Server 호출용)` `[계획: 미구축]`
37. ⏳ `AI Agent Server에 '/webhook' 엔드포인트 구현 (n8n 요청 수신)` `[계획: 미구축]`
38. ⏳ `n8n에서 AI Agent Server로 작업 요청 전달 워크플로우 구성` `[계획: 미구축]`
39. ⏳ `AI Agent Server에서 n8n으로 결과 반환 로직 구현` `[계획: 미구축]`

**Phase 1-3: 핵심 API 및 서비스 구조 설계** `[계획: 미구축]` `[2026-01-13 재조정]`
40. ⏳ `API 요청을 처리할 'src/controllers' 디렉토리 생성` `[계획: 미구축]`
41. ⏳ `비즈니스 로직을 담당할 'src/services' 디렉토리 생성` `[계획: 미구축]`
42. ⏳ `공통 타입을 관리할 'src/types' 디렉토리 생성` `[계획: 미구축]`
43. ⏳ `작업(Task) 상태 관리를 위한 타입 정의 ('src/types/task.d.ts')` `[계획: 미구축]`
44. ⏳ `작업 생성 API 컨트롤러 및 라우트 구현 ('/tasks', POST)` `[계획: 미구축]`
45. ⏳ `작업 상태 조회 API 컨트롤러 및 라우트 구현 ('/tasks/:id', GET)` `[계획: 미구축]`
46. ⏳ `n8n Database 노드를 통한 작업 상태 저장 워크플로우 구성` `[계획: 미구축]`

**Phase 1-4: 첫 번째 AI 에이전트 및 파일 시스템 연동** `[계획: 미구축]`
47. ⏳ `외부 API 연동을 위한 'axios' 라이브러리 설치` `[계획: 미구축]`
48. ⏳ `API 키 등 비밀 정보 관리를 위한 'dotenv' 라이브러리 설치 및 '.env' 파일 생성` `[계획: 미구축]`
49. ⏳ `.gitignore 파일에 '.env' 및 'dist' 폴더 추가` `[계획: 미구축]`
50. ⏳ `Claude 에이전트 로직을 구현할 'src/services/claudeAgent.ts' 파일 생성` `[계획: 미구축]`
51. ⏳ `Gemini 에이전트 로직을 구현할 'src/services/geminiAgent.ts' 파일 생성` `[계획: 미구축]`
52. ⏳ `파일 시스템 제어를 위한 'src/services/fileService.ts' 파일 생성` `[계획: 미구축]`
53. ⏳ `n8n에서 AI 에이전트 API 호출 워크플로우 구성 (HTTP Request 노드 활용)` `[계획: 미구축]`
54. ⏳ `작업 실행 시 에이전트 호출 및 파일 쓰기를 연동하는 메인 서비스 로직 구현` `[계획: 미구축]`

---

#### **Phase 1.5: DevOps API 연동 (n8n 워크플로우) (8단계)** 🆕 `[2026-01-13 추가]`

> **우선순위:** Phase 1보다 먼저 구축 권장 (단순하고 즉시 활용 가능)

**Phase 1.5-1: Gitea API 연동**
55. ⏳ `n8n에서 Gitea API Token Credential 등록 (HTTP Header Auth)` `[계획: 미구축]`
56. ⏳ `Gitea 브랜치 생성 워크플로우 구성 (HTTP Request 노드)` `[계획: 미구축]`
57. ⏳ `Gitea 파일 커밋 워크플로우 구성 (Base64 인코딩 포함)` `[계획: 미구축]`
58. ⏳ `Gitea PR 생성 워크플로우 구성` `[계획: 미구축]`

**Phase 1.5-2: Redmine API 연동**
59. ⏳ `n8n에서 Redmine API Key Credential 등록 (HTTP Header Auth)` `[계획: 미구축]`
60. ⏳ `Redmine 이슈 생성 워크플로우 구성 (HTTP Request 노드)` `[계획: 미구축]`
61. ⏳ `Redmine 이슈 상태 업데이트 워크플로우 구성` `[계획: 미구축]`

**Phase 1.5-3: 통합 워크플로우**
62. ⏳ `전체 통합 워크플로우: Webhook → Redmine 이슈 생성 → Gitea 브랜치 → 커밋 → PR → Redmine 업데이트` `[계획: 미구축]`

---

#### **Phase 2: 멀티 에이전트 확장 (17단계)** `[계획: 미구축]` `[2026-01-13 재조정]`

**Phase 2-1: 멀티 에이전트 어댑터 추가** `[계획: 미구축]`
63. ⏳ `AI 에이전트 인터페이스 정의 ('src/types/agent.d.ts')` `[계획: 미구축]`
64. ⏳ `Perplexity 에이전트 로직을 구현할 'src/services/perplexityAgent.ts' 파일 생성` `[계획: 미구축]`
65. ⏳ `OpenAI 에이전트 로직을 구현할 'src/services/openaiAgent.ts' 파일 생성` `[계획: 미구축]`
66. ⏳ `각 에이전트가 AI 에이전트 인터페이스를 따르도록 리팩토링` `[계획: 미구축]`
67. ⏳ `n8n에서 각 AI 에이전트 API 호출 노드 추가 (HTTP Request 노드)` `[계획: 미구축]`

**Phase 2-2: n8n 기반 에이전트 라우팅 및 워크스페이스** `[계획: 미구축]`
68. ⏳ `n8n에서 Switch 노드를 활용한 작업 유형별 라우팅 워크플로우 구성` `[계획: 미구축]`
69. ⏳ `작업 유형 분류: 코드 생성, 디버깅, 문서 작성, 코드 리뷰` `[계획: 미구축]`
70. ⏳ `각 작업 유형에 최적화된 AI 에이전트 자동 선택 로직 (n8n Switch 노드)` `[계획: 미구축]`
71. ⏳ `에이전트를 동적으로 선택하는 '에이전트 팩토리' 구현 ('src/services/agentFactory.ts')` `[계획: 미구축]`
72. ⏳ `AI Agent Server에 '/agent/:type' 엔드포인트 추가 (에이전트 선택용)` `[계획: 미구축]`
73. ⏳ `작업별 고유 워크스페이스(임시 디렉토리) 생성/삭제 로직을 'fileService'에 추가` `[계획: 미구축]`
74. ⏳ `n8n을 통한 워크스페이스 상태 공유 및 충돌 방지 로직 구현` `[계획: 미구축]`

---

#### **Phase 2.5: 하드웨어 SSH 연동 (n8n 워크플로우) (7단계)** 🆕 `[2026-01-13 추가]`

> **목적:** 하드웨어 장비를 n8n에서 SSH로 제어하는 기본 워크플로우 구축

**Phase 2.5-1: SSH 연결 테스트**
75. ⏳ `n8n에서 ASUS GX10 SSH Credential 등록 (Private Key 방식)` `[계획: 미구축]`
76. ⏳ `n8n Execute Command 노드로 ASUS GX10 GLM 4.7B 추론 테스트` `[계획: 미구축]`
77. ⏳ `n8n Execute Command 노드로 Jetson Orin Nano AI 모델 테스트` `[계획: 미구축]`
78. ⏳ `n8n Execute Command 노드로 Yocto Build PC 빌드 테스트` `[계획: 미구축]`
79. ⏳ `n8n Execute Command 노드로 FPGA Dev PC 합성 테스트` `[계획: 미구축]`

**Phase 2.5-2: 통합 워크플로우**
80. ⏳ `전체 하드웨어 상태 체크 워크플로우: SSH로 모든 장비 ping 및 상태 확인` `[계획: 미구축]`
81. ⏳ `n8n Error Trigger를 활용한 SSH 연결 실패 시 재시도 로직` `[계획: 미구축]`

---

#### **Phase 3: 사용자 인터페이스 및 상호작용 (14단계)** `[계획: 미구축]` `[2026-01-13 재조정]`

**Phase 3-1: CLI (Command-Line Interface) 개발** `[계획: 미구축]`
82. ⏳ `CLI 개발용 라이브러리 'commander' 및 'inquirer' 설치` `[계획: 미구축]`
83. ⏳ `CLI 애플리케이션 진입점 파일 'src/cli.ts' 생성` `[계획: 미구축]`
84. ⏳ `CLI에서 n8n Webhook을 호출하여 '신규 개발 작업 생성' 명령어 구현` `[계획: 미구축]`
85. ⏳ `CLI에서 n8n API를 통해 '작업 진행 상태 조회' 명령어 구현` `[계획: 미구축]`
86. ⏳ `CLI에서 AI가 제안한 '코드 변경사항(diff) 확인' 기능 구현` `[계획: 미구축]`
87. ⏳ `CLI에서 n8n Webhook을 통한 '변경사항 승인/반려' 기능 구현` `[계획: 미구축]`
88. ⏳ `package.json에 CLI 실행 스크립트 추가` `[계획: 미구축]`

**Phase 3-2: n8n 인터랙티브 워크플로우 구성** `[계획: 미구축]`
89. ⏳ `n8n Form 노드를 활용한 사용자 입력 수집 워크플로우 구성` `[계획: 미구축]`
90. ⏳ `n8n에서 코드 변경사항(diff) 표시 및 승인/반려 워크플로우 구현` `[계획: 미구축]`
91. ⏳ `n8n Manual Trigger 또는 Wait 노드를 활용한 사용자 승인 대기 로직 구현` `[계획: 미구축]`
92. ⏳ `Cloudflare Access를 통한 외부 접근 보안 설정 (선택사항)` `[계획: 미구축]`

---

#### **Phase 4: 자동화 및 고도화 (13단계)** `[계획: 미구축]` `[2026-01-13 재조정]`

**Phase 4-1: n8n 기반 자동 작업 분해 (Task Decomposition)** `[계획: 미구축]`
93. ⏳ `n8n에서 AI 에이전트를 활용한 작업 분해 워크플로우 구성` `[계획: 미구축]`
94. ⏳ `'분해 에이전트(Decomposition Agent)' 프롬프트 설계 및 n8n에 적용` `[계획: 미구축]`
95. ⏳ `n8n에서 '복합 작업(Complex Task)' Webhook 엔드포인트 생성` `[계획: 미구축]`
96. ⏳ `n8n Loop 노드를 활용하여 분해된 하위 작업을 순차적으로 실행하는 워크플로우 구현` `[계획: 미구축]`
97. ⏳ `AI Agent Server에 '/decompose' 엔드포인트 추가 (작업 분해 로직)` `[계획: 미구축]`

**Phase 4-2: n8n 워크플로우 기반 에이전트 협업 (Inter-Agent Collaboration)** `[계획: 미구축]`
98. ⏳ `'코드 작성', '코드 리뷰', '테스트 작성' 등 에이전트 역할을 'src/types/roles.d.ts'에 정의` `[계획: 미구축]`
99. ⏳ `n8n에서 멀티 에이전트 협업 워크플로우 구성 (순차 또는 병렬 실행)` `[계획: 미구축]`
100. ⏳ `예시 워크플로우: Webhook → 작성 에이전트 → 리뷰 에이전트 → 테스트 에이전트 → 결과 반환` `[계획: 미구축]`
101. ⏳ `n8n Error Trigger를 활용한 자동 피드백 루프 구현` `[계획: 미구축]`
102. ⏳ `테스트 실패 시 작성 에이전트로 자동 재작업 요청 워크플로우 구현` `[계획: 미구축]`

---

#### **Phase 5: 프로덕션 배포 및 최적화 (8단계)** `[일부 완료]` `[2026-01-13 재조정]`

103. ⏳ `Raspberry Pi 5에 PM2 설치 및 AI Agent Server 프로세스 관리 설정` `[계획: 미구축]`
104. ✅ `n8n Docker 컨테이너 자동 재시작 설정 (restart: unless-stopped)` `[완료: 2026-01-12]`
105. ✅ `cloudflared systemd 서비스 자동 시작 설정 (systemctl enable)` `[완료: 2026-01-12]`
106. ⏳ `Cloudflare Zero Trust를 활용한 접근 제어 및 인증 설정 (선택사항)` `[계획: 미구축]`
107. ⏳ `n8n 워크플로우 백업 및 버전 관리 설정 (Gitea 연동)` `[계획: 미구축]`
108. ✅ `로그 수집 설정 (docker-compose logs, journalctl)` `[완료: 2026-01-12]`

---

## 📊 전체 진행 상황 요약

| Phase | 단계 수 | 완료 | 진행률 | 비고 |
|:---|:---:|:---:|:---:|:---|
| **Phase 0** | 26 | 16 | **62%** | 인프라 구축 중 |
| **Phase 1** | 28 | 0 | **0%** | AI Agent Server 구축 |
| **Phase 1.5** | 8 | 0 | **0%** | DevOps API 연동 🆕 |
| **Phase 2** | 19 | 0 | **0%** | 멀티 에이전트 확장 |
| **Phase 2.5** | 7 | 0 | **0%** | 하드웨어 SSH 연동 🆕 |
| **Phase 3** | 14 | 0 | **0%** | UI 및 상호작용 |
| **Phase 4** | 13 | 0 | **0%** | 자동화 고도화 |
| **Phase 5** | 8 | 3 | **38%** | 배포 및 최적화 |
| **총계** | **108** | **19** | **약 18%** |  |

---

## 📌 권장 구축 순서 `[2026-01-13 추가]`

```
Phase 0 완료 (26단계)
    ↓
Phase 1.5 (DevOps 통합, 8단계) ← 우선 구축 권장
    ↓
Phase 1 (AI Agent Server, 28단계)
    ↓
Phase 2.5 (하드웨어 SSH, 7단계)
    ↓
Phase 2 (멀티 에이전트, 19단계)
    ↓
Phase 3, 4, 5
```

**이유:** Phase 1.5는 구현이 단순하고 즉시 활용 가능하며, 다른 Phase의 작업도 자동으로 이슈 추적 가능

---

## 📚 관련 문서

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 시스템 아키텍처 및 설계
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 배포, 네트워크, 구축 가이드
- **[DEVOPS_INTEGRATION.md](DEVOPS_INTEGRATION.md)** - Gitea/Redmine API 연동 가이드
- **[README.md](README.md)** - 프로젝트 개요 및 시작 가이드
