MCP 서버 구축 절차서
1. 하드웨어 준비
1.1 기본 서버 / 워크스테이션
항목	권장 사양
CPU	AMD Ryzen 9 7950X / Intel Core i9-14900K
RAM	DDR5 64GB 이상 (FPGA 병렬 시뮬레이션 시 128GB 권장)
저장장치	NVMe SSD 2TB (OS용) / SATA SSD 4TB (빌드 캐시) / HDD 8TB
GPU	NVIDIA RTX 4080 이상 (CUDA 12.2+)
네트워크	10GbE LAN 포트 이상 권장
1.2 FPGA 전용 머신 (옵션)
보드: Xilinx Alveo U250 또는 Intel Stratix 10 GX

슬롯: PCIe 4.0 x16

전원: 800W 이상 PSU

2. OS 및 가상화 환경 설정
2.1 WSL2 활성화 (Windows 11 Pro)
PowerShell(관리자)에서 실행:

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2

2.2 Ubuntu 22.04 LTS 설치 및 기본 패키지
wsl --install -d Ubuntu-22.04

sudo apt update
sudo apt install -y build-essential cmake python3-pip libboost-all-dev git

2.3 Docker 기반 빌드 컨테이너 예시 (docker-compose.yml)
version: '3'
services:
  mcp-builder:
    image: ubuntu:22.04
    volumes:
      - ./src:/mnt/src
    command: /mnt/src/build.sh

3. 개발 도구 설치
3.1 C++ (GCC 12)
sudo apt install -y gcc-12 g++-12
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100

3.2 C# (.NET SDK 8)
winget install Microsoft.DotNet.SDK.8

3.3 Python (pyenv + poetry)
curl https://pyenv.run | bash

(셸 재시작 후)

pyenv install 3.11.5
pyenv global 3.11.5

pip install --upgrade pip
pip install poetry

poetry new mcp-project

3.4 FPGA 툴 (Vivado 예시)
./xsetup --agree XilinxEULA,3rdPartyEULA --batch Install

3.5 IDE 통합 (VS Code, .vscode/extensions.json)
{
  "recommendations": [
    "ms-vscode.cpptools",
    "ms-dotnettools.csharp",
    "ms-python.python",
    "platformio.platformio-ide"
  ]
}

4. 빌드 자동화 설정
4.1 Jenkins 파이프라인 (Jenkinsfile)
pipeline {
  agent any
  stages {
    stage('Build C++') {
      steps {
        sh 'rm -rf build'
        sh 'cmake -B build -S .'
        sh 'cmake --build build'
      }
    }
    stage('Run Unit Tests') {
      steps {
        sh './build/runTests'
      }
    }
    stage('FPGA Synthesis') {
      steps {
        sh 'vivado -mode batch -source synthesis.tcl'
      }
    }
  }
}

4.2 GitHub Actions CI (.github/workflows/mcp-build.yml)
name: MCP CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential cmake

      - name: Configure
        run: cmake -S . -B build

      - name: Build
        run: cmake --build build -j 4

      - name: Run C++ tests
        run: ctest --test-dir build

5. 테스트 및 시뮬레이션
5.1 C++ 유닛 테스트 (CMakeLists.txt 일부)
enable_testing()

find_package(GTest REQUIRED)

add_executable(runTests
    tests/test_main.cpp
    tests/test_sample.cpp
)

target_link_libraries(runTests
    PRIVATE
        GTest::GTest
        GTest::Main
)

add_test(NAME AllTests COMMAND runTests)

5.2 Python 테스트 (pyproject.toml 일부)
[tool.pytest.ini_options]
minversion = "7.0"
addopts = "-v --cov=src"
testpaths = ["tests"]

5.3 FPGA 시뮬레이션 (simulate.tcl)
vlib work
vlog -sv design.sv testbench.sv
vsim -c testbench
run -all
quit -sim

6. 문서화 자동화
6.1 Doxygen (Doxyfile 핵심)
EXTRACT_ALL = YES
INPUT = src/
OUTPUT_DIRECTORY = docs/
GENERATE_LATEX = NO
GENERATE_HTML = YES

6.2 MkDocs (mkdocs.yml)
site_name: MCP Documentation
theme:
  name: material

nav:
  - Home: index.md
  - Build:
      - Overview: build/overview.md
  - API Reference:
      - C++: api/cpp.md
      - C#: api/csharp.md
      - Python: api/python.md
      - FPGA: api/fpga.md

7. MCP용 Python 환경 예시
pyenv install 3.11.5
pyenv virtualenv 3.11.5 mcp-env
pyenv activate mcp-env

pip install poetry
poetry init

8. 검증 및 모니터링
8.1 리소스 확인
htop
nvidia-smi

8.2 통합 테스트 스크립트 (run_all_tests.sh 예시)
#!/usr/bin/env bash
set -e

echo " C++ 단위 테스트"
​
ctest --test-dir build

echo " Python 테스트"
​
pytest

echo " FPGA 시뮬레이션"
​
vsim -c -do simulate.tcl

echo "모든 테스트 통과"

9. 구축 완료 체크리스트
C++/C#/Python 빌드 및 테스트가 CI에서 자동 수행되는지

FPGA 합성 및 시뮬레이션 스크립트가 비대화식으로 동작하는지

Doxygen + MkDocs 기반 문서가 자동 생성 및 배포되는지

MCP 관련 Python 서비스가 지정 포트에서 정상 동작하는지

CPU/GPU/메모리/디스크 사용량이 안정적인지
