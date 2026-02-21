@echo off
echo ========================================
echo   Car Contract AI - Starting Backend
echo ========================================
cd /d "c:\Users\NITISH\OneDrive\Documents\Infosys Springboard Virtaul Internship 6.0\OCR\CarContractApp\backend"
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
pause
