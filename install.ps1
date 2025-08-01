# EverEsports Server Auto-Installation Script
# PowerShell Version

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EverEsports Server Auto-Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if Node.js is installed
function Test-NodeJS {
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Host "✅ Node.js is already installed (Version: $nodeVersion)" -ForegroundColor Green
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to install Node.js
function Install-NodeJS {
    Write-Host "❌ Node.js not found. Installing..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📥 Downloading Node.js installer..." -ForegroundColor Blue
    
    try {
        # Download Node.js installer
        $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
        $installerPath = "$env:TEMP\nodejs_installer.msi"
        
        Write-Host "Downloading from: $nodeUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "🔧 Installing Node.js..." -ForegroundColor Blue
        Start-Process msiexec.exe -Wait -ArgumentList "/i $installerPath /quiet /norestart"
        
        # Clean up installer
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "✅ Node.js installation completed!" -ForegroundColor Green
        
        # Test installation
        Start-Sleep -Seconds 3
        if (Test-NodeJS) {
            return $true
        } else {
            Write-Host "⚠️ Node.js installed but not detected. Please restart your computer and try again." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "❌ Failed to install Node.js: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please download Node.js manually from https://nodejs.org/" -ForegroundColor Yellow
        return $false
    }
}

# Function to check npm
function Test-NPM {
    try {
        $npmVersion = npm --version 2>$null
        if ($npmVersion) {
            Write-Host "✅ npm is available (Version: $npmVersion)" -ForegroundColor Green
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to install dependencies
function Install-Dependencies {
    Write-Host ""
    Write-Host "📦 Installing project dependencies..." -ForegroundColor Blue
    
    try {
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ All dependencies installed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error installing dependencies: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to start server
function Start-Server {
    Write-Host ""
    Write-Host "🚀 Starting EverEsports Server..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Server will be available at:" -ForegroundColor White
    Write-Host "http://localhost:3000" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Start the server
    node server.js
}

# Main execution
try {
    # Check if Node.js is installed
    if (-not (Test-NodeJS)) {
        if (-not (Install-NodeJS)) {
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    
    # Check npm
    if (-not (Test-NPM)) {
        Write-Host "❌ npm not found. Please restart your computer and try again." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Install dependencies
    if (-not (Install-Dependencies)) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Start server
    Start-Server
}
catch {
    Write-Host "❌ An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
} 