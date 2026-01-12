# n8n + Cloudflare Tunnel 구축 기록 (라즈베리파이 기준)

작성일: 2026-01-12

---

## 1. 환경 준비

- 라즈베리파이 OS 최신 업데이트
- Docker & Docker Compose 설치
- Cloudflare 계정 및 도메인 준비 (api.abyz-lab.work)
- cloudflared 설치

---

## 2. n8n Docker 컨테이너 설정

### docker-compose.yml 예제

```yaml
version: "3.8"

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - WEBHOOK_URL=https://api.abyz-lab.work
      - TZ=Asia/Seoul
      - N8N_SECURE_COOKIE=false
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=abyz@0809
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_ENCRYPTION_KEY=~!duck5625
    volumes:
      - ./n8n_data:/home/node/.n8n
```

### 컨테이너 실행

```bash
docker compose up -d
docker ps | grep n8n
```

---

## 3. Cloudflare Tunnel 설정

### 1. 터널 생성

```bash
cloudflared tunnel create abyz-n8n
```

### 2. config.yml 생성 (~/.cloudflared/config.yml)

```yaml
tunnel: abyz-n8n
credentials-file: /home/raspi/.cloudflared/7be6cf9a-dc35-4add-815c-da4810d9e0c5.json

ingress:
  - hostname: api.abyz-lab.work
    service: http://localhost:5678
  - service: http_status:404
```

### 3. DNS CNAME 설정 (Cloudflare 대시보드)

- **호스트:** api
- **값:** 7be6cf9a-dc35-4add-815c-da4810d9e0c5.cfargotunnel.com
- **프록시:** 활성화 (주황 구름)

### 4. cloudflared 서비스 등록 및 자동 시작

```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

---

## 4. 시스템 튜닝 (QUIC/UDP 버퍼 문제)

### /etc/sysctl.conf 수정

```bash
net.core.rmem_max=8388608
net.core.wmem_max=8388608
```

### 적용

```bash
sudo sysctl -p
sudo systemctl restart cloudflared
```

---

## 5. 최종 확인

### 1. n8n 컨테이너 상태 확인

```bash
docker ps | grep n8n
```

### 2. Cloudflare Tunnel 상태 확인

```bash
sudo systemctl status cloudflared
cloudflared tunnel list
cloudflared tunnel info abyz-n8n
```

### 3. 브라우저 접속

```
https://api.abyz-lab.work
```

---

## 6. 자동 실행 보장

- **Docker 컨테이너:** restart: unless-stopped
- **Cloudflared 서비스:** systemctl enable cloudflared
- **재부팅 후에도 자동 실행 확인 완료**

---

## 7. 로그 및 디버깅

### n8n 로그

```bash
docker-compose logs -f n8n
```

### cloudflared 로그

```bash
journalctl -u cloudflared -f
```

### UDP 버퍼 에러 예시

```
failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB)
```

→ sysctl.conf 수정으로 해결

---

## 8. 작업 요약

1. Docker에서 n8n 컨테이너 배포
2. Cloudflare Tunnel 생성 후 ingress 설정
3. DNS CNAME 연결
4. QUIC/UDP 버퍼 문제 sysctl로 수정
5. cloudflared systemd 서비스 등록
6. 브라우저에서 https://api.abyz-lab.work 정상 접속 확인

**→ 모든 단계 완료, 라즈베리파이 재부팅 후에도 n8n + Cloudflare Tunnel 자동 실행.**
