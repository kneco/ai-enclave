@echo off
chcp 65001 >nul
echo Stopping ai-enclave...
docker compose stop
echo ai-enclave stopped.
pause
