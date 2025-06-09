#!/usr/bin/env python3
import socket, struct, time, io, threading
import RPi.GPIO as GPIO
from picamera2 import Picamera2, Preview
from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306
from PIL import ImageFont, ImageDraw

HOST = "0.0.0.0"    # 모든 인터페이스에서 수신
PORT = 5001

# GPIO 설정
# BUTTON_PIN = 17 # 버튼 핀 제거
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
# GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # 버튼 핀 설정 제거
BUZZER_PIN = 23 # 부저 핀 번호를 설정하세요 (예: GPIO 23)
GPIO.setup(BUZZER_PIN, GPIO.OUT) # 부저 핀 출력으로 설정

# PWM 부저 설정 (50% 듀티 사이클로 초기화)
buzzer_pwm = GPIO.PWM(BUZZER_PIN, 1000) # 1000Hz 주파수로 초기화
buzzer_pwm.stop() # 초기에는 부저를 끈 상태로 시작

# OLED 설정
serial = i2c(port=1, address=0x3C) # I2C 포트 1, 주소 0x3C (대부분의 OLED 기본값)
oled = ssd1306(serial) # SSD1306 모델 사용, 다른 모델이면 변경하세요.
font = ImageFont.truetype("DejaVuSans.ttf", 20) # 폰트 경로와 크기 설정

# 카메라 설정
cam = Picamera2()
config = cam.create_preview_configuration()
cam.configure(config)
cam.start_preview(Preview.QTGL)  # QTGL 프리뷰 사용
cam.start()

MAX_SHOTS = 4
COUNTDOWN = 10 # 이 값은 이제 앱에서 전송되므로 사용되지 않음

def play_buzzer(frequency, duration):
    buzzer_pwm.start(50) # 50% 듀티 사이클로 PWM 시작
    buzzer_pwm.ChangeFrequency(frequency) # 주파수 변경
    time.sleep(duration)
    buzzer_pwm.stop()

def play_click_sound():
    # 찰칵 소리 (두 번의 짧은 고음)
    play_buzzer(2000, 0.05) # 높은 음 짧게
    time.sleep(0.05)
    play_buzzer(2500, 0.05) # 더 높은 음 짧게

def update_oled(text):
    with canvas(oled) as draw:
        draw.rectangle(oled.bounding_box, outline="black", fill="black") # 화면 지우기
        w, h = draw.textsize(text, font=font)
        x = (oled.width - w) / 2
        y = (oled.height - h) / 2
        draw.text((x, y), text, font=font, fill="white")

def handle_client(conn, addr):
    print(f"Flutter 연결 수락: {addr}")
    try:
        while True:
            header = conn.recv(1) # 명령 바이트 수신
            if not header:
                break

            command = header[0]

            if command == 0x01: # 사진 촬영 요청
                index_byte = conn.recv(1)
                if not index_byte: break
                index = index_byte[0]
                print(f"-> 촬영 요청 #{index}")
               
                # 사진 촬영
                print("찰칵!")
                update_oled("Cheese!") # OLED에 촬영 메시지 표시
                play_click_sound() # 찰칵 소리
                time.sleep(0.5) # "Cheese!" 메시지 표시 시간
                stream = io.BytesIO()
                cam.capture_file(stream, format="jpeg")
                img_bytes = stream.getvalue()
               
                # 이미지 전송
                print(f"이미지 전송 중... ({len(img_bytes)} bytes)")
                update_oled("Sending...") # OLED에 전송 메시지 표시
                conn.sendall(struct.pack(">I", len(img_bytes)) + img_bytes)
                print("이미지 전송 완료")
                update_oled("Done") # OLED에 완료 메시지 표시
                time.sleep(1) # "Done" 메시지 표시 시간

            elif command == 0x02: # 카운트다운 숫자 전송
                countdown_byte = conn.recv(1)
                if not countdown_byte: break
                seconds = countdown_byte[0]
                print(f"-> 카운트다운: {seconds}")
                if seconds > 0: # 0초일 때는 부저를 울리지 않음
                    update_oled(str(seconds)) # OLED에 카운트다운 숫자 표시
                    play_buzzer(1000, 0.1) # 1000Hz로 짧게 부저 울림
                else: # 0초일 때 (찰칵 직전)
                    update_oled("Ready!")
                    # buzzer_pwm.stop() # 이미 play_buzzer에서 멈추므로 필요 없음
                    time.sleep(0.1)

            elif command == 0x03: # 세션 종료 신호
                print("-> 세션 종료 신호 수신")
                update_oled("Bye!") # OLED에 종료 메시지 표시
                buzzer_pwm.stop() # 부저 소리 끔
                time.sleep(1)
                break # 클라이언트 루프 종료

            else:
                print(f"알 수 없는 명령: {command}")
            
    except Exception as e:
        print(f"클라이언트 처리 중 오류: {e}")
    finally:
        conn.close()
        print(f"Flutter 연결 종료: {addr}")
        buzzer_pwm.stop() # 연결 종료 시 부저 끄기
        update_oled("Idle") # 연결 종료 후 OLED에 Idle 메시지 표시

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
                threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start() # 새로운 연결마다 스레드 시작
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
        update_oled(f"IP:{actual_ip}") # 시작 시 OLED에 IP 주소 표시
        time.sleep(2)
    except Exception as e:
        print(f"IP 주소 확인 실패: {e}")
        update_oled("IP Error")
        time.sleep(2)
    finally:
        s.close()
   
    # 소켓 서버 시작
    server_thread = threading.Thread(target=socket_server, daemon=True)
    server_thread.start()
    print("소켓 서버 스레드 시작됨")
   
    print("서버 실행 중...")
    update_oled("Waiting...") # 서버 시작 후 OLED에 대기 메시지 표시
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n프로그램 종료")
        buzzer_pwm.stop() # PWM 정지
        GPIO.cleanup()
        update_oled("Bye!") # 종료 시 OLED에 메시지 표시
        time.sleep(1)
        oled.cleanup() # OLED 정리