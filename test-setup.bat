@echo off
echo ========================================
echo EverEsports Server Setup Test
echo ========================================
echo.

echo Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Node.js is installed
    node --version
) else (
    echo ❌ Node.js not found
    echo Please run install.bat or install.ps1 first
)

echo.
echo Checking npm installation...
npm --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ npm is available
    npm --version
) else (
    echo ❌ npm not found
)

echo.
echo Checking project files...
if exist "server.js" (
    echo ✅ server.js found
) else (
    echo ❌ server.js not found
)

if exist "package.json" (
    echo ✅ package.json found
) else (
    echo ❌ package.json not found
)

if exist "index.html" (
    echo ✅ index.html found
) else (
    echo ❌ index.html not found
)

echo.
echo Checking upload directories...
if exist "uploads" (
    echo ✅ uploads directory found
) else (
    echo ❌ uploads directory not found
)

echo.
echo Checking node_modules...
if exist "node_modules" (
    echo ✅ node_modules found (dependencies installed)
) else (
    echo ❌ node_modules not found (run npm install)
)

echo.
echo ========================================
echo Test Complete
echo ========================================
echo.
echo If all checks passed, you can run:
echo   node server.js
echo.
echo Or use the automatic installer:
echo   install.bat
echo.
pause 