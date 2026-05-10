@echo off
title Launcher CLI - Zero Trust USB
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0main.ps1""' -Verb RunAs"