@echo off
title Launcher CLI - Zero Trust USB Security
cls
echo ===========================================
echo    PILIH FUNGSI ZERO TRUST USB (CLI)
echo ===========================================
echo 1. Jalankan Menu Registrasi (FirstRun)
echo 2. Buka Menu Monitoring Utama (Main)
echo 3. Unblock Perangkat
echo 4. Remove dari Whitelist
echo ===========================================
set /p opt="Pilih menu (1-4): "

if "%opt%"=="1" set "flag=-FirstRun"
if "%opt%"=="2" set "flag="
if "%opt%"=="3" set "flag=-Unblock"
if "%opt%"=="4" set "flag=-RemoveWhitelist"

powershell -Command "Start-Process powershell -ArgumentList '-NoExit -ExecutionPolicy Bypass -File \"%~dp0main.ps1\" %flag%' -Verb RunAs"

exit
