@echo off
echo Starting RAG-Enhanced Medical Chatbot Server...
echo.

REM Change to the correct directory
cd /d "d:\Uomna\semester 7\Flutter\grad\lib"

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

REM Check if required packages are installed
echo Checking dependencies...
python -c "import flask, pandas, sklearn, pyarabic" >nul 2>&1
if errorlevel 1 (
    echo Installing required packages...
    pip install -r requirements_rag.txt
    if errorlevel 1 (
        echo ERROR: Failed to install packages
        pause
        exit /b 1
    )
)

REM Check if train.csv exists
if not exist "..\RAG\train.csv" (
    echo WARNING: train.csv not found in RAG directory
    echo The server will use fallback data
    echo.
)

echo.
echo ================================
echo   RAG Medical Chatbot Server    
echo ================================
echo Starting server on http://0.0.0.0:5000
echo Press Ctrl+C to stop the server
echo.

REM Start the RAG server
python chatbot_rag.py

pause
