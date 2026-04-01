@echo off
chcp 65001 >nul
echo Starting ai-enclave...

REM 1. コンテナ起動
docker compose up -d

REM 2. code-server起動待機（ポート8080、最大30秒）
set /a COUNT=0
:WAIT_LOOP
curl -s http://localhost:8080 >nul 2>&1
if %ERRORLEVEL% EQU 0 goto READY
set /a COUNT+=1
if %COUNT% GEQ 30 (
    echo WARNING: code-server did not start in 30 seconds.
    goto OPEN
)
timeout /t 1 /nobreak >nul
goto WAIT_LOOP

:READY
echo code-server is ready.

:OPEN
REM 3. ブラウザを2タブで開く
start "" "file:///%~dp0guide.html"
timeout /t 1 /nobreak >nul
start "" "http://localhost:8080"

REM 4. コンテナbashに接続（以降このウィンドウがコンテナ内ターミナルになる）
echo Connecting to container...
docker exec -it ai-enclave bash
