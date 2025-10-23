# 🌀 Bambu AutoFan for H2D, H2S Only

이 프로젝트는 뱀부랩 프린터(H2D, H2S Only)에서 사용가능한 자동 환기 프로그램 입니다.

### 필요한 것들
- IKEA DIRIGERA Hub https://www.ikea.com/kr/ko/p/dirigera-hub-for-smart-products-white-smart-70503413/
- IKEA OUTLET https://www.ikea.com/kr/ko/p/tretakt-plug-smart-70556524/
- 220v 로 연결해서 동작 시킬 수 있는 환기 팬
- docker 를 실행 할 수 있는 환경

### 프로젝트 실행하기
```
git clone https://github.com/rubyon/bambu_autofan.git
```
```
cp docker-compose.yaml.sample docker-compose.yaml
```

docker-compose.yaml 파일을 수정합니다
```
services:
  bambu:
    build: .
    container_name: bambu-autofan
    restart: always
    environment:
      TZ: Asia/Seoul
      PRINTER_IP: "192.168.10.1" #프린터의 IP
      ACCESS_CODE: "acces_scode"       #프린터의 ACCESS_CODE
      SERIAL: "serial"                 #프린터의 Serial
      DEBOUNCE: "3"                    #VENT On/Off 상태 감지 지속시간
      DIRIGERA_IP: "192.168.10.2"      #이케아 DIRIGERA의 IP
      DIRIGERA_TOKEN: "dirigera_token" #이케아 DIRIGERA의 TOKEN
      OUTLET_NAME: "outlet_name"       #이케아 OUTLET의 이름
```

ACCESS_CODE 는 프린터 모니터에서 설정 > LAN 전용 으로 들어가시면 보실 수 있습니다

SERIAL 은 설정 > 기기 및 일련 번호 로 들어가시면 보실 수 있습니다

DIRIGERA_IP 는 직접 확인해 주셔야 합니다

DIRIGERA_TOKEN 은 `npx dirigera authenticate` 명령어를 실행한 후 시키는 대로 하면 얻으실 수 있습니다

OUTLET_NAME 은 DIGIGERA 에 연동된 OUTLET 의 이름 입니다

모든 설정이 끝났으면

```
docker compose up --build -d
```

로 실행하시면 바로 사용이 가능 합니다

만약 제가 빌드한 이미지로 바로 실행하고 싶으시면

```
services:
  bambu:
    image: hub.rubyon.co.kr/bambu-autofan
    container_name: bambu-autofan
    restart: always
    environment:
      TZ: Asia/Seoul
      PRINTER_IP: "192.168.10.1" #프린터의 IP
      ACCESS_CODE: "acces_scode"       #프린터의 ACCESS_CODE
      SERIAL: "serial"                 #프린터의 Serial
      DEBOUNCE: "3"                    #VENT On/Off 상태 감지 지속시간
      DIRIGERA_IP: "192.168.10.2"      #이케아 DIRIGERA의 IP
      DIRIGERA_TOKEN: "dirigera_token" #이케아 DIRIGERA의 TOKEN
      OUTLET_NAME: "outlet_name"       #이케아 OUTLET의 이름
```

위의 docker-compose.yaml 파일을 만들고

```
docker compose up --build -d
```

로 실행하시면 바로 사용이 가능 합니다

ABS 같은 경우 출력중에는 환기팬이 돌지 않습니다

그래서 편법으로 출력이 끝나면 환기를 시키는 방법을 택했습니다

뱀부 스튜디오에서 프린터 설정에 들어가면

장치 G-코드 라고 있는데

여기에 장치 종료 G-코드가 있습니다

맨마지막에 아래 코드를 추가해주세요

```
;=====add by rubyon=====
M106 P3 S255; 환기용 배기팬 최대속
G4 S60; 60초(1분) 대기
M106 P3 S0; 배기팬 끄기
```

60초는 환기를 시킬 시간만큼 지정해주시면 됩니다

최대 속도는 1~255 까지이며 (16진수 FF) 255은 100% 입니다