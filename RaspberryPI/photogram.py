#!/usr/bin/env python3
import socket, struct, time, io, threading
import RPi.GPIO as GPIO
from picamera2 import Picamera2, Preview

HOST = "0.0.0.0"    # 모든 인터페이스에서 수신
PORT = 5001

# GPIO 설정
BUTTON_PIN = 17
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

# 카메라 설정
cam = Picamera2()
config = cam.create_preview_configuration()
cam.configure(config)
cam.start_preview(Preview.QTGL)  # QTGL 프리뷰 사용
cam.start()

MAX_SHOTS = 4
COUNTDOWN = 10

def handle_client(conn, addr):
    print(f"Flutter 연결 수락: {addr}")
    try:
        while True:
            data = conn.recv(1)
            if not data:
                break
            index = data[0]
            print(f"-> 촬영 요청 #{index}")
           
            # 카운트다운 시작
            for i in range(COUNTDOWN, 0, -1):
                print(f"카운트다운: {i}")
                time.sleep(1)
           
            # 사진 촬영
            print("찰칵!")
            stream = io.BytesIO()
            cam.capture_file(stream, format="jpeg")
            img_bytes = stream.getvalue()
           
            # 이미지 전송
            print(f"이미지 전송 중... ({len(img_bytes)} bytes)")
            conn.sendall(struct.pack(">I", len(img_bytes)) + img_bytes)
            print("이미지 전송 완료")
           
    except Exception as e:
        print(f"클라이언트 처리 중 오류: {e}")
    finally:
        conn.close()
        print(f"Flutter 연결 종료: {addr}")

def socket_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            # 소켓 옵션 설정
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
           
            # 바인딩 시도
            s.bind((HOST, PORT))
            print(f"소켓 바인딩 성공: {HOST}:{PORT}")
           
            # 리스닝 시작
            s.listen(1)
            print(f"대기 중... {HOST}:{PORT}")
           
            while True:
                print("새로운 연결 대기 중...")
                conn, addr = s.accept()
                print(f"Flutter 연결 수락: {addr}")
                threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
        except Exception as e:
            print(f"소켓 서버 오류: {e}")
            raise

if __name__ == "__main__":
    print("=== 포토부스 서버 시작 ===")
   
    # 실제 IP 주소 확인
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        actual_ip = s.getsockname()[0]
        print(f"실제 IP 주소: {actual_ip}")
    except Exception as e:
        print(f"IP 주소 확인 실패: {e}")
    finally:
        s.close()
   
    # 소켓 서버 시작
    server_thread = threading.Thread(target=socket_server, daemon=True)
    server_thread.start()
    print("소켓 서버 스레드 시작됨")
   
    print("서버 실행 중...")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n프로그램 종료")
        GPIO.cleanup()