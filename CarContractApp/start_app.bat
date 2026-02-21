@echo off
echo ========================================
echo   Car Contract AI - Full Application
echo ========================================
echo.
echo Starting Backend Server...
start "Backend Server" cmd /k "cd /d \"c:\Users\NITISH\OneDrive\Documents\Infosys Springboard Virtaul Internship 6.0\OCR\CarContractApp\backend\" && python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000"

echo Waiting for backend to initialize...
timeout /t 5 /nobreak > nul

echo Starting Flutter App...
set PATH=C:\Users\NITISH\Downloads\flutter_windows_3.38.9-stable\flutter\bin;%PATH%
cd /d "c:\Users\NITISH\OneDrive\Documents\Infosys Springboard Virtaul Internship 6.0\OCR\CarContractApp\flutter_app"
flutter run -d chrome
pause
