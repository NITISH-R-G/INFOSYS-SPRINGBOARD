@echo off
cd /d "%~dp0"
echo Starting Car Contract App Backend...
echo Docs will be available at: http://127.0.0.1:8000/docs

REM Try local venv first
if exist ".venv\Scripts\python.exe" (
    echo Using local backend .venv...
    ".venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
) else if exist "..\.venv\Scripts\python.exe" (
    echo Using parent .venv...
    "..\.venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
) else if exist "..\..\.venv\Scripts\python.exe" (
    echo Using root .venv...
    "..\..\.venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
) else (
    echo Using system Python...
    python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
)
pause
