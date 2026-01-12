### **MCP 전체 구축 계획서 (Full Project Plan)**

> **📝 2026-01-12 업데이트:** 하드웨어 개발 워크플로우 자동화를 위한 상세 계획 (93단계) `[2026-01-12 업데이트]`
> **주요 추가:**
> - Phase 0 확장: 11단계 → 26단계 (Tailscale, Gitea, Redmine, IDE AI 추가) `[2026-01-12 추가]`
> - Phase 1.5 신규: DevOps 통합 및 IDE AI 연계 (9단계) `[2026-01-12 추가]`
> - Phase 2.5 신규: 하드웨어 검증 및 빌드 자동화 (8단계) `[2026-01-12 추가]`

#### **Phase 0: 인프라 구축** 🆕 `[일부 완료: 2026-01-12]` `[2026-01-12 업데이트]`

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

**0-2. IDE AI 및 네트워크 환경** 🆕 `[2026-01-12 추가]`
12. ✅ `Claude Code 구독 활성화 및 VSCode 확장 설치` `[완료: 2026-01-12]`
13. ✅ `GitHub Copilot 구독 활성화 및 IDE 플러그인 설치` `[완료: 2026-01-12]`
14. ✅ `모든 장비에 Tailscale VPN 설치 및 SSH 연결 확인` `[완료: 기존 설치]`
15. ✅ `Synology NAS의 Gitea 접속 확인 (HTTP API 테스트)` `[완료: 기존 설치]`
16. ✅ `Synology NAS의 Redmine 접속 확인 (HTTP API 테스트)` `[완료: 기존 설치]`

**0-3. 로컬 LLM 및 하드웨어 설정** 🆕 `[2026-01-12 추가]`
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

#### **Phase 1-1: AI Agent Server 환경 구축** `[계획: 미구축]`
27. ⏳ `Raspberry Pi 5에 Node.js 설치 (LTS 버전)` `[계획: 미구축]`
28. ⏳ `Node.js 프로젝트 초기화: 'package.json' 파일 생성` `[계획: 미구축]`
29. ⏳ `TypeScript 및 Node.js 타입 라이브러리 설치` `[계획: 미구축]`
30. ⏳ `TypeScript 컴파일러 설정 파일 'tsconfig.json' 생성` `[계획: 미구축]`
31. ⏳ `Express 웹 프레임워크 및 타입 라이브러리 설치` `[계획: 미구축]`
32. ⏳ `소스 코드 관리를 위한 'src' 디렉토리 생성` `[계획: 미구축]`
33. ⏳ `'src/index.ts' 파일에 기본 Express 서버 코드 작성 (n8n과 통신 가능하도록)` `[계획: 미구축]`
34. ⏳ `'package.json'에 서버 빌드 및 실행 스크립트 추가` `[계획: 미구축]`

#### **Phase 1-2: n8n과 AI Agent Server 통합** `[계획: 미구축]`
35. ⏳ `n8n에서 Webhook 노드 생성 (사용자 요청 수신용)` `[계획: 미구축]`
36. ⏳ `n8n에서 HTTP Request 노드 생성 (AI Agent Server 호출용)` `[계획: 미구축]`
37. ⏳ `AI Agent Server에 '/webhook' 엔드포인트 구현 (n8n 요청 수신)` `[계획: 미구축]`
38. ⏳ `n8n에서 AI Agent Server로 작업 요청 전달 워크플로우 구성` `[계획: 미구축]`
39. ⏳ `AI Agent Server에서 n8n으로 결과 반환 로직 구현` `[계획: 미구축]`

#### **Phase 1-3: 핵심 API 및 서비스 구조 설계** `[계획: 미구축]`
25. ⏳ `API 요청을 처리할 'src/controllers' 디렉토리 생성` `[계획: 미구축]`
26. ⏳ `비즈니스 로직을 담당할 'src/services' 디렉토리 생성` `[계획: 미구축]`
27. ⏳ `공통 타입을 관리할 'src/types' 디렉토리 생성` `[계획: 미구축]`
28. ⏳ `작업(Task) 상태 관리를 위한 타입 정의 ('src/types/task.d.ts')` `[계획: 미구축]`
29. ⏳ `작업 생성 API 컨트롤러 및 라우트 구현 ('/tasks', POST)` `[계획: 미구축]`
30. ⏳ `작업 상태 조회 API 컨트롤러 및 라우트 구현 ('/tasks/:id', GET)` `[계획: 미구축]`
31. ⏳ `n8n Database 노드를 통한 작업 상태 저장 워크플로우 구성` `[계획: 미구축]`

#### **Phase 1-4: 첫 번째 AI 에이전트 및 파일 시스템 연동** `[계획: 미구축]`
32. ⏳ `외부 API 연동을 위한 'axios' 라이브러리 설치` `[계획: 미구축]`
33. ⏳ `API 키 등 비밀 정보 관리를 위한 'dotenv' 라이브러리 설치 및 '.env' 파일 생성` `[계획: 미구축]`
34. ⏳ `.gitignore 파일에 '.env' 및 'dist' 폴더 추가` `[계획: 미구축]`
35. ⏳ `Claude 에이전트 로직을 구현할 'src/services/claudeAgent.ts' 파일 생성` `[계획: 미구축]`
36. ⏳ `Gemini 에이전트 로직을 구현할 'src/services/geminiAgent.ts' 파일 생성` `[계획: 미구축]`
37. ⏳ `파일 시스템 제어를 위한 'src/services/fileService.ts' 파일 생성` `[계획: 미구축]`
38. ⏳ `n8n에서 AI 에이전트 API 호출 워크플로우 구성 (HTTP Request 노드 활용)` `[계획: 미구축]`
39. ⏳ `작업 실행 시 에이전트 호출 및 파일 쓰기를 연동하는 메인 서비스 로직 구현` `[계획: 미구축]`

#### **Phase 2-1: 멀티 에이전트 어댑터 추가** `[계획: 미구축]`
40. ⏳ `AI 에이전트 인터페이스 정의 ('src/types/agent.d.ts')` `[계획: 미구축]`
41. ⏳ `Perplexity 에이전트 로직을 구현할 'src/services/perplexityAgent.ts' 파일 생성` `[계획: 미구축]`
42. ⏳ `OpenAI 에이전트 로직을 구현할 'src/services/openaiAgent.ts' 파일 생성` `[계획: 미구축]`
43. ⏳ `각 에이전트가 AI 에이전트 인터페이스를 따르도록 리팩토링` `[계획: 미구축]`
44. ⏳ `n8n에서 각 AI 에이전트 API 호출 노드 추가 (HTTP Request 노드)` `[계획: 미구축]`

#### **Phase 2-2: n8n 기반 에이전트 라우팅 및 워크스페이스** `[계획: 미구축]`
45. ⏳ `n8n에서 Switch 노드를 활용한 작업 유형별 라우팅 워크플로우 구성` `[계획: 미구축]`
46. ⏳ `작업 유형 분류: 코드 생성, 디버깅, 문서 작성, 코드 리뷰` `[계획: 미구축]`
47. ⏳ `각 작업 유형에 최적화된 AI 에이전트 자동 선택 로직 (n8n Switch 노드)` `[계획: 미구축]`
48. ⏳ `에이전트를 동적으로 선택하는 '에이전트 팩토리' 구현 ('src/services/agentFactory.ts')` `[계획: 미구축]`
49. ⏳ `AI Agent Server에 '/agent/:type' 엔드포인트 추가 (에이전트 선택용)` `[계획: 미구축]`
50. ⏳ `작업별 고유 워크스페이스(임시 디렉토리) 생성/삭제 로직을 'fileService'에 추가` `[계획: 미구축]`
51. ⏳ `n8n을 통한 워크스페이스 상태 공유 및 충돌 방지 로직 구현` `[계획: 미구축]`

#### **Phase 3-1: CLI (Command-Line Interface) 개발** `[계획: 미구축]`
52. ⏳ `CLI 개발용 라이브러리 'commander' 및 'inquirer' 설치` `[계획: 미구축]`
53. ⏳ `CLI 애플리케이션 진입점 파일 'src/cli.ts' 생성` `[계획: 미구축]`
54. ⏳ `CLI에서 n8n Webhook을 호출하여 '신규 개발 작업 생성' 명령어 구현` `[계획: 미구축]`
55. ⏳ `CLI에서 n8n API를 통해 '작업 진행 상태 조회' 명령어 구현` `[계획: 미구축]`
56. ⏳ `CLI에서 AI가 제안한 '코드 변경사항(diff) 확인' 기능 구현` `[계획: 미구축]`
57. ⏳ `CLI에서 n8n Webhook을 통한 '변경사항 승인/반려' 기능 구현` `[계획: 미구축]`
58. ⏳ `package.json에 CLI 실행 스크립트 추가` `[계획: 미구축]`

#### **Phase 3-2: n8n 인터랙티브 워크플로우 구성** `[계획: 미구축]`
59. ⏳ `n8n Form 노드를 활용한 사용자 입력 수집 워크플로우 구성` `[계획: 미구축]`
60. ⏳ `n8n에서 코드 변경사항(diff) 표시 및 승인/반려 워크플로우 구현` `[계획: 미구축]`
61. ⏳ `n8n Manual Trigger 또는 Wait 노드를 활용한 사용자 승인 대기 로직 구현` `[계획: 미구축]`
62. ⏳ `Cloudflare Access를 통한 외부 접근 보안 설정 (선택사항)` `[계획: 미구축]`

#### **Phase 4-1: n8n 기반 자동 작업 분해 (Task Decomposition)** `[계획: 미구축]`
63. ⏳ `n8n에서 AI 에이전트를 활용한 작업 분해 워크플로우 구성` `[계획: 미구축]`
64. ⏳ `'분해 에이전트(Decomposition Agent)' 프롬프트 설계 및 n8n에 적용` `[계획: 미구축]`
65. ⏳ `n8n에서 '복합 작업(Complex Task)' Webhook 엔드포인트 생성` `[계획: 미구축]`
66. ⏳ `n8n Loop 노드를 활용하여 분해된 하위 작업을 순차적으로 실행하는 워크플로우 구현` `[계획: 미구축]`
67. ⏳ `AI Agent Server에 '/decompose' 엔드포인트 추가 (작업 분해 로직)` `[계획: 미구축]`

#### **Phase 4-2: n8n 워크플로우 기반 에이전트 협업 (Inter-Agent Collaboration)** `[계획: 미구축]`
68. ⏳ `'코드 작성', '코드 리뷰', '테스트 작성' 등 에이전트 역할을 'src/types/roles.d.ts'에 정의` `[계획: 미구축]`
69. ⏳ `n8n에서 멀티 에이전트 협업 워크플로우 구성 (순차 또는 병렬 실행)` `[계획: 미구축]`
70. ⏳ `예시 워크플로우: Webhook → 작성 에이전트 → 리뷰 에이전트 → 테스트 에이전트 → 결과 반환` `[계획: 미구축]`
71. ⏳ `n8n Error Trigger를 활용한 자동 피드백 루프 구현` `[계획: 미구축]`
72. ⏳ `테스트 실패 시 작성 에이전트로 자동 재작업 요청 워크플로우 구현` `[계획: 미구축]`

---

#### **Phase 5: 프로덕션 배포 및 최적화 (Production Deployment)** `[일부 완료]`
73. ⏳ `Raspberry Pi 5에 PM2 설치 및 AI Agent Server 프로세스 관리 설정` `[계획: 미구축]`
74. ✅ `n8n Docker 컨테이너 자동 재시작 설정 (restart: unless-stopped)` `[완료: 2026-01-12]`
75. ✅ `cloudflared systemd 서비스 자동 시작 설정 (systemctl enable)` `[완료: 2026-01-12]`
76. ⏳ `Cloudflare Zero Trust를 활용한 접근 제어 및 인증 설정 (선택사항)` `[계획: 미구축]`
77. ⏳ `n8n 워크플로우 백업 및 버전 관리 설정` `[계획: 미구축]`
78. ✅ `로그 수집 설정 (docker-compose logs, journalctl)` `[완료: 2026-01-12]`
79. ✅ `시스템 UDP 버퍼 성능 튜닝 (sysctl.conf)` `[완료: 2026-01-12]`
