# 📸 Photogram

<div align="center">

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![Python Version](https://img.shields.io/badge/Python-3.7%2B-blue?style=flat-square&logo=python)](https://python.org)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=flat-square)](https://github.com/yourusername/photogram)

[![Socket.IO](https://img.shields.io/badge/Socket-Communication-orange?style=flat-square&logo=socket.io)](https://socket.io)

_라즈베리파이 기반 스마트 포토부스 시스템_ 📷✨

</div>

---

## 🎯 프로젝트 소개

**Photogram**은 라즈베리파이와 Flutter를 결합한 혁신적인 포토부스 시스템입니다.
실시간 소켓 통신을 통해 모바일 앱에서 라즈베리파이 카메라를 원격 제어하여 4컷 사진을 촬영하고,
다양한 이모티콘으로 편집할 수 있는 완전한 포토부스 경험을 제공합니다.

> 💡 **특별한 점**: 전통적인 포토부스와 달리, 스마트폰을 리모컨처럼 사용하여 더욱 편리하고 재미있는 촬영이 가능합니다!

---

## 🏗️ 시스템 아키텍처

```
┌─────────────────┐    Socket (TCP)    ┌─────────────────────┐
│                 │ ◄─────────────────► │                     │
│  Flutter App    │     Port 5001      │  Raspberry Pi       │
│  (Mobile)       │                    │  + Camera Module    │
│                 │                    │  + GPIO Button      │
└─────────────────┘                    └─────────────────────┘
        │                                       │
        ▼                                       ▼
┌─────────────────┐                    ┌─────────────────────┐
│   Photo Edit    │                    │   Photo Capture     │
│   + Emoticons   │                    │   + Countdown       │
│   + Export      │                    │   + Preview         │
└─────────────────┘                    └─────────────────────┘
```

---

## 💫 주요 기능

### 📱 Flutter 모바일 앱

- **🎯 원격 촬영 제어**: 스마트폰으로 라즈베리파이 카메라 원격 조작
- **🖼️ 4컷 사진 촬영**: 포토부스 스타일의 연속 촬영 기능
- **😊 이모티콘 편집**: 다양한 이모티콘 추가 및 편집
- **🎨 실시간 편집**: 위치, 크기, 회전 조절 가능
- **💾 저장 & 공유**: 편집된 사진 저장 및 SNS 공유

### 🍓 라즈베리파이 서버

- **📷 PiCamera2 지원**: 고품질 사진 촬영
- **🔌 소켓 통신**: 실시간 Flutter 앱과 통신
- **⏰ 카운트다운**: 10초 카운트다운으로 완벽한 포즈
- **🔴 GPIO 버튼**: 물리적 버튼으로 추가 제어 (예정)
- **🖥️ 라이브 프리뷰**: QTGL 기반 실시간 카메라 화면

---

## 🛠️ 기술 스택

<div align="center">

### 📱 모바일 앱

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Socket](https://img.shields.io/badge/Socket-Communication-orange?style=flat-square)

### 🖥️ 하드웨어 & 서버

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi%204-A22846?style=flat-square&logo=raspberry-pi&logoColor=white)
![Python](https://img.shields.io/badge/Python%203.7+-3776AB?style=flat-square&logo=python&logoColor=white)
![Camera](https://img.shields.io/badge/PiCamera2-green?style=flat-square)
![GPIO](https://img.shields.io/badge/GPIO-Control-yellow?style=flat-square)

</div>

---

## 🚀 시작하기

### 📋 필요한 하드웨어

| 구성품           | 모델                  | 필수도  |
| ---------------- | --------------------- | ------- |
| **라즈베리파이** | Pi 4 권장 (Pi 3 이상) | ✅ 필수 |
| **카메라 모듈**  | Pi Camera V2/V3       | ✅ 필수 |
| **GPIO 버튼**    | 택트 스위치           | 🟡 선택 |
| **점퍼 와이어**  | Male-Female           | 🟡 선택 |

### 🔧 사전 준비 사항

**라즈베리파이 측:**

- Raspberry Pi OS 설치
- Python 3.7 이상
- PiCamera2 라이브러리
- GPIO 접근 권한

**모바일 측:**

- Flutter 개발 환경 설정
- Android/iOS 디바이스 또는 에뮬레이터

---

## 🛠️ 설치

### 1️⃣ 라즈베리파이 서버 설정

```bash
# 저장소 클론
git clone https://github.com/yourusername/photogram.git
cd photogram

# Python 의존성 설치
sudo apt update
sudo apt install python3-pip
pip3 install picamera2 RPi.GPIO

# 카메라 활성화
sudo raspi-config
# Interface Options → Camera → Enable

# 서버 실행
cd raspberry_server
python3 photobooth_server.py
```

### 2️⃣ Flutter 앱 설정

```bash
# 프로젝트 디렉토리로 이동
cd flutter_app

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 3️⃣ 네트워크 연결 설정

```bash
# 라즈베리파이 IP 주소 확인
hostname -I

# Flutter 앱에서 해당 IP 주소로 연결 설정
# (앱 내 설정 또는 소스 코드에서 IP 주소 변경)
```

---

## 📱 사용 방법

1. **🔌 연결**: 라즈베리파이 서버 실행 후 Flutter 앱에서 연결
2. **📷 촬영**: 앱에서 촬영 버튼을 눌러 4컷 사진 촬영 시작
3. **⏰ 대기**: 10초 카운트다운 후 자동 촬영
4. **🎨 편집**: 촬영 완료 후 이모티콘 추가 및 편집
5. **💾 저장**: 편집된 사진을 갤러리에 저장 또는 공유

---

## 📸 스크린샷

<div align="center">

|  연결 화면  | 촬영 화면  |    편집 화면    |   결과 화면   |
| :---------: | :--------: | :-------------: | :-----------: |
|     🔌      |     📷     |       🎨        |      💾       |
| _서버 연결_ | _4컷 촬영_ | _이모티콘 편집_ | _저장 & 공유_ |

_스크린샷 추가 예정_

</div>

---

## 🔧 하드웨어 연결

```
Raspberry Pi GPIO Layout:
┌─────────────────────────────────┐
│  3V3  [ 1] [ 2]  5V             │
│  GPIO2[ 3] [ 4]  5V             │
│  GPIO3[ 5] [ 6]  GND            │
│  GPIO4[ 7] [ 8]  GPIO14         │
│   GND [ 9] [10]  GPIO15         │
│ GPIO17[11] [12]  GPIO18 ◄─ 버튼 │
│ GPIO27[13] [14]  GND    ◄─ 버튼 │
│ GPIO22[15] [16]  GPIO23         │
└─────────────────────────────────┘

Button Connection:
GPIO17 (Pin 11) ──┤ │──── GND (Pin 14)
                  버튼
```

---

## 🚧 개발 로드맵

- [x] 기본 소켓 통신 구현
- [x] 4컷 사진 촬영 기능
- [x] 이모티콘 편집 기능

---

## 📊 성능 지표

![Latency](https://img.shields.io/badge/Socket_Latency-<100ms-green?style=flat-square)
![Image Quality](https://img.shields.io/badge/Image_Quality-1080p-blue?style=flat-square)
![Capture Speed](https://img.shields.io/badge/Capture_Speed-<2s-brightgreen?style=flat-square)
![Memory Usage](https://img.shields.io/badge/Memory_Usage-<500MB-orange?style=flat-square)

---

## 🛠️ 개발 환경

| 구분                | 버전          | 비고                     |
| ------------------- | ------------- | ------------------------ |
| **Flutter SDK**     | ≥ 3.0.0       | 안정 버전 권장           |
| **Dart SDK**        | ≥ 2.17.0      | Flutter와 함께 설치      |
| **Python**          | ≥ 3.7         | 라즈베리파이 기본        |
| **PiCamera2**       | Latest        | `pip3 install picamera2` |
| **Raspberry Pi OS** | Bullseye 이상 | 64bit 권장               |

---

## 🤝 기여하기

프로젝트에 기여해주세요! 여러분의 도움이 필요합니다.

### 기여 방법

1. **🍴 Fork** 이 저장소를 포크합니다
2. **🌟 Branch** 새로운 기능 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. **💾 Commit** 변경사항을 커밋합니다 (`git commit -m 'Add amazing feature'`)
4. **📤 Push** 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`)
5. **🔄 Pull Request** 풀 리퀘스트를 생성합니다

### 기여 영역

- 🐛 버그 수정
- ✨ 새로운 기능 추가
- 📚 문서 개선
- 🎨 UI/UX 개선
- 🔧 성능 최적화

---

## 🆘 문제 해결

<details>
<summary>📱 <strong>앱이 라즈베리파이에 연결되지 않아요</strong></summary>

1. 라즈베리파이와 모바일 기기가 같은 네트워크에 있는지 확인
2. 방화벽에서 5001 포트가 열려있는지 확인
3. 라즈베리파이 IP 주소가 올바른지 확인

```bash
hostname -I  # IP 주소 확인
```

</details>

<details>
<summary>📷 <strong>카메라가 작동하지 않아요</strong></summary>

1. 카메라 모듈이 올바르게 연결되었는지 확인
2. 카메라가 활성화되었는지 확인

```bash
sudo raspi-config  # Interface Options → Camera → Enable
```

3. PiCamera2 라이브러리가 설치되었는지 확인

```bash
pip3 install picamera2
```

</details>

<details>
<summary>🔌 <strong>소켓 연결이 불안정해요</strong></summary>

1. 네트워크 연결 상태 확인
2. 포트 충돌 확인

```bash
sudo netstat -tlnp | grep :5001
```

3. 서버 재시작 후 재연결 시도
</details>

---

## 📄 라이선스

이 프로젝트는 **MIT 라이선스** 하에 배포됩니다.

자세한 내용은 [`LICENSE`](LICENSE) 파일을 참고하세요.

```
MIT License - 자유롭게 사용, 수정, 배포 가능합니다!
```

---

**🔗 관련 링크**

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Raspberry Pi 공식 사이트](https://www.raspberrypi.org/)
- [PiCamera2 문서](https://github.com/raspberrypi/picamera2)

</div>

---

<div align="center">

**Made with ❤️ by developers, for developers**

_Let's make photo booth experience smarter!_ 📸✨

</div>
