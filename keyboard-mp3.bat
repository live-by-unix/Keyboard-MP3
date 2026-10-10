
@echo off
setlocal EnableExtensions

set "VERSION=1.0.0"
set "APPDIR=%LOCALAPPDATA%\keyboard-mp3"
set "PYTHON=%APPDIR%\venv\Scripts\python.exe"
set "HELPER=%APPDIR%\listener.py"
set "CONFIG=%APPDIR%\sound-path.txt"
set "PIDFILE=%APPDIR%\listener.pid"
set "LOG=%APPDIR%\listener.log"

if not exist "%APPDIR%" mkdir "%APPDIR%" >nul 2>&1

if /i "%~1"=="on" goto on
if /i "%~1"=="off" goto off
if /i "%~1"=="status" goto status
if /i "%~1"=="change" goto change
if /i "%~1"=="help" goto help
if /i "%~1"=="-h" goto help
if /i "%~1"=="--help" goto help
if /i "%~1"=="-v" goto version
if /i "%~1"=="--version" goto version
if /i "%~1"=="version" goto version
goto help

:help
echo keyboard-mp3 %VERSION%
echo.
echo Usage:
echo   keyboard-mp3.bat on
echo   keyboard-mp3.bat off
echo   keyboard-mp3.bat status
echo   keyboard-mp3.bat change "C:\path\to\keyboard.mp3"
echo   keyboard-mp3.bat help
echo   keyboard-mp3.bat --help
echo   keyboard-mp3.bat --version
echo.
echo Commands:
echo   on       Start the keyboard sound listener.
echo   off      Stop the listener.
echo   status   Check listener status.
echo   change   Change the MP3 file.
echo   help     Display this help.
exit /b 0

:version
echo keyboard-mp3 %VERSION%
exit /b 0

:on
if not exist "%PYTHON%" (
    echo Python environment not found: "%PYTHON%"
    exit /b 1
)
if not exist "%HELPER%" (
    echo Missing listener.py: "%HELPER%"
    exit /b 1
)
if not exist "%CONFIG%" (
    echo No sound configured.
    echo Run: keyboard-mp3.bat change "C:\path\to\keyboard.mp3"
    exit /b 1
)
set /p "SOUND="<"%CONFIG%"
if not exist "%SOUND%" (
    echo MP3 not found: "%SOUND%"
    exit /b 1
)

call :checkrunning
if not errorlevel 1 (
    echo Keyboard sound is already running.
    exit /b 0
)

set "KM_PYTHON=%PYTHON%"
set "KM_HELPER=%HELPER%"
set "KM_SOUND=%SOUND%"
set "KM_LOG=%LOG%"
set "KM_PIDFILE=%PIDFILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath $env:KM_PYTHON -ArgumentList @($env:KM_HELPER, $env:KM_SOUND) -WindowStyle Hidden -RedirectStandardOutput $env:KM_LOG -RedirectStandardError $env:KM_LOG -PassThru; Set-Content -Path $env:KM_PIDFILE -Value $p.Id"

if errorlevel 1 (
    echo Failed to start listener. Check "%LOG%".
    exit /b 1
)

echo Keyboard sound started.
exit /b 0

:off
call :checkrunning
if errorlevel 1 (
    del "%PIDFILE%" >nul 2>&1
    echo Keyboard sound is already off.
    exit /b 0
)
taskkill /PID %PID% /T /F >nul 2>&1
del "%PIDFILE%" >nul 2>&1
echo Keyboard sound stopped.
exit /b 0

:status
call :checkrunning
if errorlevel 1 (
    echo Keyboard sound is off.
) else (
    echo Keyboard sound is running. PID %PID%.
)
if exist "%CONFIG%" (
    set /p "SOUND="<"%CONFIG%"
    echo MP3: "%SOUND%"
)
exit /b 0

:change
if "%~2"=="" (
    echo Usage: keyboard-mp3.bat change "C:\path\to\keyboard.mp3"
    exit /b 2
)
set "NEW_SOUND=%~2"
if not exist "%NEW_SOUND%" (
    echo File not found: "%NEW_SOUND%"
    exit /b 1
)

set "WAS_RUNNING=0"
call :checkrunning
if not errorlevel 1 (
    set "WAS_RUNNING=1"
    call :off
)

>"%CONFIG%" echo %NEW_SOUND%
echo Sound file changed to "%NEW_SOUND%".

if "%WAS_RUNNING%"=="1" call :on
exit /b 0

:checkrunning
if not exist "%PIDFILE%" exit /b 1
set "PID="
set /p "PID="<"%PIDFILE%"
if not defined PID exit /b 1
tasklist /FI "PID eq %PID%" /NH 2>nul | findstr /C:"%PID%" >nul
if errorlevel 1 exit /b 1
exit /b 0
