@echo off
cd /d "%~dp0manufacturing_app"
echo Starting Manufacturing ERP app on Chrome (http://localhost:3000)...
call D:\flutter\bin\flutter.bat run -d chrome --web-port=3000
