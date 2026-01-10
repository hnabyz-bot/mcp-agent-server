### **MCP 전체 구축 계획서 (Full Project Plan)**

#### **Phase 1-1: Node.js & Express 서버 환경 구축**
1.  `Node.js 프로젝트 초기화: 'package.json' 파일 생성`
2.  `TypeScript 및 Node.js 타입 라이브러리 설치`
3.  `TypeScript 컴파일러 설정 파일 'tsconfig.json' 생성`
4.  `Express 웹 프레임워크 및 타입 라이브러리 설치`
5.  `소스 코드 관리를 위한 'src' 디렉토리 생성`
6.  `'src/index.ts' 파일에 기본 Express 서버 코드 작성`
7.  `'package.json'에 서버 빌드 및 실행 스크립트 추가`

#### **Phase 1-2: 핵심 API 및 서비스 구조 설계**
8.  `API 요청을 처리할 'src/controllers' 디렉토리 생성`
9.  `비즈니스 로직을 담당할 'src/services' 디렉토리 생성`
10. `공통 타입을 관리할 'src/types' 디렉토리 생성`
11. `작업(Task) 상태 관리를 위한 타입 정의 ('src/types/task.d.ts')`
12. `메모리 기반의 임시 데이터베이스 서비스 구현 ('src/services/taskStore.ts')`
13. `작업 생성 API 컨트롤러 및 라우트 구현 ('/tasks', POST)`
14. `작업 상태 조회 API 컨트롤러 및 라우트 구현 ('/tasks/:id', GET)`

#### **Phase 1-3: 첫 번째 AI 에이전트 및 파일 시스템 연동**
15. `외부 API 연동을 위한 'axios' 라이브러리 설치`
16. `API 키 등 비밀 정보 관리를 위한 'dotenv' 라이브러리 설치 및 '.env' 파일 생성`
17. `.gitignore 파일에 '.env' 및 'dist' 폴더 추가`
18. `Gemini 에이전트 로직을 구현할 'src/services/geminiAgent.ts' 파일 생성`
19. `파일 시스템 제어를 위한 'src/services/fileService.ts' 파일 생성`
20. `작업 실행 시 에이전트 호출 및 파일 쓰기를 연동하는 메인 서비스 로직 구현`

#### **Phase 2-1: 멀티 에이전트 어댑터 추가**
21. `AI 에이전트 인터페이스 정의 ('src/types/agent.d.ts')`
22. `Claude 에이전트 로직을 구현할 'src/services/claudeAgent.ts' 파일 생성`
23. `Perplexity 에이전트 로직을 구현할 'src/services/perplexityAgent.ts' 파일 생성`
24. `각 에이전트가 AI 에이전트 인터페이스를 따르도록 리팩토링`

#### **Phase 2-2: 에이전트 라우팅 및 워크스페이스**
25. `에이전트를 동적으로 선택하는 '에이전트 팩토리' 구현 ('src/services/agentFactory.ts')`
26. `작업 생성 API('/tasks', POST) 요청 본문에 'agent' 선택 필드 추가`
27. `요청된 'agent'에 따라 팩토리에서 적절한 에이전트 인스턴스를 반환하도록 로직 수정`
28. `작업별 고유 워크스페이스(임시 디렉토리) 생성/삭제 로직을 'fileService'에 추가`

#### **Phase 3-1: CLI (Command-Line Interface) 개발**
29. `CLI 개발용 라이브러리 'commander' 및 'inquirer' 설치`
30. `CLI 애플리케이션 진입점 파일 'src/cli.ts' 생성`
31. `CLI에서 '신규 개발 작업 생성'을 처리하는 명령어 구현`
32. `CLI에서 '작업 진행 상태 조회'를 처리하는 명령어 구현`
33. `CLI에서 AI가 제안한 '코드 변경사항(diff) 확인' 기능 구현`
34. `CLI에서 '변경사항 승인/반려'를 처리하는 기능 구현`
35. `package.json에 CLI 실행 스크립트 추가`

#### **Phase 4-1: 자동 작업 분해 (Task Decomposition)**
36. `상위 작업을 하위 작업으로 분해하는 '분해 에이전트(Decomposition Agent)' 역할 정의 및 프롬프트 설계`
37. `'복합 작업(Complex Task)' 요청을 처리하는 신규 API 엔드포인트('/complex-tasks', POST) 구현`
38. `해당 API에서 '분해 에이전트'를 호출하여 하위 작업 목록을 생성하고, 각 하위 작업을 순차적으로 실행하는 로직 구현`

#### **Phase 4-2: 에이전트간 협업 (Inter-Agent Collaboration)**
39. `'코드 작성', '코드 리뷰', '테스트 작성' 등 에이전트 역할을 `src/types/roles.d.ts`에 정의`
40. `하위 작업 목록을 역할 기반으로 에이전트에게 순차 할당하는 '워크플로우 엔진' 서비스('src/services/workflowEngine.ts') 구현`
41. `'리뷰 에이전트'의 피드백을 '작성 에이전트'에게 다시 전달하여 코드를 수정하게 하는 로직 구현`
42. `구현된 워크플로우 엔진을 '복합 작업' API에 최종 통합`

---

#### **Phase 5: 배포 및 외부 접근 설정 (Deployment & External Access)**
43. `서버 프로세스 관리를 위한 'pm2' 설치 및 실행 스크립트 설정`
44. `(방법 A: 개발/테스트용) 'ngrok'을 활용하여 로컬 서버를 외부로 노출`
45. `(방법 B: 프로덕션용) Nginx 등 리버스 프록시 서버 설정 가이드 작성`
46. `(방법 B 적용 시) Let's Encrypt를 이용한 무료 SSL/TLS 인증서 설정 가이드 작성`
