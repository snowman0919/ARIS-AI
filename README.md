# ARIS-AI

Autonomous Recognization Integration Steering-system AI.

DGX Spark GB10/aarch64 장비에서 ARIS의 AI 연구, 물리 시뮬레이션, 자율주행/로보틱스 시뮬레이션을 분리해서 운영하기 위한 로컬 워크스페이스입니다.

## 현재 장비 상태

- OS: Ubuntu 24.04.4 LTS, aarch64
- GPU: NVIDIA GB10
- Driver/CUDA: 580.159.03 / CUDA 13.0
- RAM: 약 119 GiB unified memory
- Docker/NVIDIA Container Toolkit: 설치됨
- 현재 제한: `sbeen` 계정이 `docker` 그룹에 없어 Docker 소켓 접근이 막혀 있습니다.

## 권장 구조

- 호스트 Python: 가벼운 분석, 노트북, MuJoCo/Gymnasium 기반 물리 실험
- NVIDIA PyTorch 컨테이너: CUDA 13/GB10 GPU 학습 및 추론
- Isaac Sim 컨테이너: PhysX, RTX 센서, 로봇/자율주행 시뮬레이션
- ROS 2 Jazzy 컨테이너: ROS 노드, bridge 테스트, 자율주행 소프트웨어 통합

## 1. 호스트 Python 환경

```bash
cd ~/dgx-spark-ai-lab
./scripts/bootstrap_host_env.sh all
source .venv/bin/activate
jupyter lab
```

검증만 다시 실행:

```bash
source ~/aris/dgx-spark-ai-lab/.venv/bin/activate
python ~/aris/dgx-spark-ai-lab/scripts/verify_host_env.py
```

## 2. Docker 권한 한 번 설정

현재 계정에서 Docker를 바로 실행하려면 관리자 터미널에서 아래 명령을 한 번 실행한 뒤 로그아웃/로그인해야 합니다.

```bash
sudo usermod -aG docker $USER
```

권한과 GPU 컨테이너 상태 확인:

```bash
cd ~/dgx-spark-ai-lab
./scripts/docker_preflight.sh
```

## 3. AI GPU 컨테이너

```bash
cd ~/dgx-spark-ai-lab
./scripts/run_ai_container.sh
```

기본 이미지는 `nvcr.io/nvidia/pytorch:26.04-py3`입니다. 다른 NGC 태그를 쓰려면:

```bash
DGX_PYTORCH_IMAGE=nvcr.io/nvidia/pytorch:26.04-py3 ./scripts/run_ai_container.sh
```

JupyterLab은 기본적으로 `http://localhost:8888`에서 열리고 토큰은 `dgx-spark`입니다.

## 4. Isaac Sim 호환성 검사

```bash
cd ~/dgx-spark-ai-lab
./scripts/run_isaac_compat.sh
```

기본 이미지는 `nvcr.io/nvidia/isaac-sim:5.1.0`입니다. Isaac Sim 5.1의 aarch64 빌드는 DGX Spark에서 지원되며, 해당 컨테이너는 Linux x86_64/aarch64 멀티 아키텍처 태그입니다.

## 5. ROS 2 Jazzy 컨테이너

```bash
cd ~/dgx-spark-ai-lab
./scripts/run_ros_jazzy_container.sh
```

워크스페이스는 `~/dgx-spark-ai-lab/workspaces/ros2_ws`에 마운트됩니다.

## 6. Docker Compose 대안

```bash
cd ~/dgx-spark-ai-lab
docker compose --profile ai up
docker compose --profile sim run --rm isaac-sim-compat
docker compose --profile ros run --rm ros-jazzy
```

## 공식 문서 기준

- DGX OS는 DGX 시스템용 Ubuntu 기반 최적화 OS이며 드라이버와 시스템 설정을 포함합니다.
- 2026-06-15 기준 DGX OS 7 소프트웨어 스택의 current version은 GPU Driver 580.159.04, CUDA Toolkit 13.0 Update 3, NVIDIA Container Toolkit 1.19.1입니다.
- Isaac Sim 5.1 요구사항은 aarch64의 경우 DGX Spark, DGX OS 7.2.3, 테스트 드라이버 580.95.05입니다. 현재 장비 드라이버는 이보다 최신입니다.
- Isaac Sim 5.1 on DGX Spark 제한: livestreaming, Hub Workstation Cache, OBJ import, Application Template, cuRobo/cuMotion, App Selector는 지원되지 않습니다.
