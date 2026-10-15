@echo off
chcp 65001 >nul
rem Запуск сервера API приложения «Маршрут» на Windows.
rem Двойной щелчок по этому файлу открывает окно сервера. База данных
rem хранится в этой же папке (файл marshrut_server.sqlite).
rem Окно не закрывайте, пока работаете с приложением; остановка — Ctrl+C.
title Marshrut API server
cd /d "%~dp0"
bin\marshrut_server.exe --port 8080 --db "%~dp0marshrut_server.sqlite"
pause
