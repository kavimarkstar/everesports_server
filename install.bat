@echo off
echo ========================================
echo EverEsports Server Auto-Installation
echo ========================================
echo.

:: Check if Node.js is already installed
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Node.js is already installed
    goto :check_npm
) else (
    echo ❌ Node.js not found. Installing...
    goto :install_nodejs
)

:install_nodejs
echo.
echo 📥 Downloading Node.js installer...
echo Please wait while we download and install Node.js...

:: Download Node.js installer (LTS version)
powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi' -OutFile 'nodejs_installer.msi'}"

if %errorlevel% neq 0 (
    echo ❌ Failed to download Node.js installer
    echo Please download Node.js manually from https://nodejs.org/
    pause
    exit /b 1
)

echo.
echo 🔧 Installing Node.js...
msiexec /i nodejs_installer.msi /quiet /norestart

:: Wait for installation to complete
timeout /t 10 /nobreak >nul

:: Clean up installer
del nodejs_installer.msi

:: Refresh environment variables
call refreshenv.cmd 2>nul
if %errorlevel% neq 0 (
    echo Refreshing PATH...
    set PATH=%PATH%;C:\Program Files\nodejs\
)

:check_npm
echo.
echo 🔍 Checking npm installation...
npm --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ npm is available
) else (
    echo ❌ npm not found. Please restart your computer and try again.
    pause
    exit /b 1
)

echo.
echo 📦 Installing project dependencies...
npm install

if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ✅ All dependencies installed successfully!

echo.
echo 🚀 Starting EverEsports Server...
echo.
echo ========================================
echo Server will be available at:
echo http://localhost:3000
echo ========================================
echo.

:: Start the server
node server.js

pause 