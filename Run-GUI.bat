@echo off
title Launcher GUI - Zero Trust USB
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File ""%~dp0gui.ps1""' -Verb RunAs"