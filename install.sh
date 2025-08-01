#!/bin/bash

# EverEsports Server Auto-Installation Script
# Linux/Mac Version

echo "========================================"
echo "EverEsports Server Auto-Installation"
echo "========================================"
echo ""

# Function to check if Node.js is installed
check_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        echo "✅ Node.js is already installed (Version: $NODE_VERSION)"
        return 0
    else
        echo "❌ Node.js not found. Installing..."
        return 1
    fi
}

# Function to install Node.js
install_nodejs() {
    echo ""
    echo "📥 Installing Node.js..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo yum install -y nodejs
        else
            echo "❌ Unsupported Linux distribution. Please install Node.js manually."
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install node
        else
            echo "❌ Homebrew not found. Please install Homebrew first or install Node.js manually."
            return 1
        fi
    else
        echo "❌ Unsupported operating system. Please install Node.js manually."
        return 1
    fi
    
    if command -v node &> /dev/null; then
        echo "✅ Node.js installation completed!"
        return 0
    else
        echo "❌ Node.js installation failed."
        return 1
    fi
}

# Function to check npm
check_npm() {
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        echo "✅ npm is available (Version: $NPM_VERSION)"
        return 0
    else
        echo "❌ npm not found."
        return 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo ""
    echo "📦 Installing project dependencies..."
    
    if npm install; then
        echo "✅ All dependencies installed successfully!"
        return 0
    else
        echo "❌ Failed to install dependencies"
        return 1
    fi
}

# Function to start server
start_server() {
    echo ""
    echo "🚀 Starting EverEsports Server..."
    echo ""
    echo "========================================"
    echo "Server will be available at:"
    echo "http://localhost:3000"
    echo "========================================"
    echo ""
    
    # Start the server
    node server.js
}

# Main execution
main() {
    # Check if Node.js is installed
    if ! check_nodejs; then
        if ! install_nodejs; then
            echo "Press Enter to exit"
            read
            exit 1
        fi
    fi
    
    # Check npm
    if ! check_npm; then
        echo "❌ npm not found. Please restart your terminal and try again."
        echo "Press Enter to exit"
        read
        exit 1
    fi
    
    # Install dependencies
    if ! install_dependencies; then
        echo "Press Enter to exit"
        read
        exit 1
    fi
    
    # Start server
    start_server
}

# Run main function
main 