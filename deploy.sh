#!/bin/bash

echo "🚀 EverEsports Server Deployment Script"
echo "======================================"

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "✅ Created .env file. Please edit it with your configuration."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Run tests
echo "🧪 Running tests..."
npm test

# Build for production
echo "🔨 Building for production..."
npm run build 2>/dev/null || echo "⚠️  No build script found, skipping..."

# Deploy options
echo ""
echo "Choose deployment option:"
echo "1) Deploy to Vercel"
echo "2) Deploy to Netlify"
echo "3) Deploy to Railway"
echo "4) Local development"
echo "5) Docker deployment"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "🚀 Deploying to Vercel..."
        if command -v vercel &> /dev/null; then
            vercel --prod
        else
            echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
        fi
        ;;
    2)
        echo "🚀 Deploying to Netlify..."
        if command -v netlify &> /dev/null; then
            netlify deploy --prod
        else
            echo "❌ Netlify CLI not found. Install with: npm i -g netlify-cli"
        fi
        ;;
    3)
        echo "🚀 Deploying to Railway..."
        if command -v railway &> /dev/null; then
            railway up
        else
            echo "❌ Railway CLI not found. Install with: npm i -g @railway/cli"
        fi
        ;;
    4)
        echo "🚀 Starting local development server..."
        npm run dev
        ;;
    5)
        echo "🐳 Deploying with Docker..."
        docker-compose up -d
        ;;
    *)
        echo "❌ Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo "✅ Deployment script completed!" 