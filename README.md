# 🚀 EverEsports Server - GitHub Pages Deployment

This repository contains the EverEsports server with automatic deployment to GitHub Pages and serverless functions.

## 🌐 Live Demo

Visit: [https://kavimarkstar.github.io/everesports_server/](https://kavimarkstar.github.io/everesports_server/)

## 📋 Features

- **GitHub Pages Deployment**: Automatic deployment on push to main branch
- **Serverless Functions**: API endpoints via Netlify/Vercel functions
- **Real-time Monitoring**: Web-based server control panel
- **File Upload Testing**: Test uploads directly from the web interface
- **API Testing**: Test server endpoints through the web interface

## 🛠️ Deployment Options

### Option 1: GitHub Pages (Static)
- ✅ **Pros**: Free, fast, reliable
- ❌ **Cons**: No server-side functionality (static only)
- 🔗 **URL**: https://kavimarkstar.github.io/everesports_server/

### Option 2: Netlify (Serverless)
- ✅ **Pros**: Free serverless functions, full Node.js support
- ✅ **Cons**: Slightly slower cold starts
- 🔗 **Setup**: Connect GitHub repo to Netlify

### Option 3: Vercel (Serverless)
- ✅ **Pros**: Excellent performance, full Node.js support
- ✅ **Cons**: Free tier limits
- 🔗 **Setup**: Connect GitHub repo to Vercel

## 🚀 Quick Start

### For GitHub Pages (Current Setup)

1. **Fork/Clone** this repository
2. **Push to main branch** - automatic deployment
3. **Visit**: https://kavimarkstar.github.io/everesports_server/

### For Netlify Deployment

1. **Connect to Netlify**:
   - Go to [netlify.com](https://netlify.com)
   - Connect your GitHub repository
   - Deploy automatically

2. **Environment Variables** (if needed):
   ```
   MONGODB_URI=your_mongodb_connection_string
   ```

### For Vercel Deployment

1. **Connect to Vercel**:
   - Go to [vercel.com](https://vercel.com)
   - Import your GitHub repository
   - Deploy automatically

## 📁 File Structure

```
everesports_server/
├── index.html              # Main control panel
├── server.js               # Main server file
├── package.json            # Dependencies
├── vercel.json            # Vercel configuration
├── netlify.toml           # Netlify configuration
├── functions/
│   └── server.js          # Netlify serverless function
├── .github/
│   └── workflows/
│       └── deploy.yml     # GitHub Actions workflow
└── README.md              # This file
```

## 🔧 API Endpoints

### Health Check
- **GET** `/api/health` - Server status and info

### File Uploads
- **POST** `/upload` - Profile image upload
- **POST** `/upload-cover` - Cover photo upload
- **POST** `/upload-post-media` - Post media upload
- **POST** `/api/stories` - Story upload

### Server Management
- **POST** `/api/shutdown` - Graceful server shutdown

## 🎯 Usage

### Web Interface
1. Open the deployed URL
2. Click "🔍 Check Server" to verify status
3. Use "📁 File Upload Testing" to test uploads
4. Use "🔧 API Testing" to test endpoints

### Local Development
```bash
# Install dependencies
npm install

# Start local server
npm start

# Or run directly
node server.js
```

## 🔍 Troubleshooting

### GitHub Pages Issues
- **Static Limitation**: GitHub Pages only serves static files
- **Solution**: Use Netlify/Vercel for full server functionality

### CORS Issues
- **Problem**: Cross-origin requests blocked
- **Solution**: CORS headers are configured in serverless functions

### MongoDB Connection
- **Problem**: Database connection fails
- **Solution**: Set environment variables in deployment platform

## 📊 Monitoring

The web interface provides:
- ✅ **Real-time server status**
- 📊 **Server logs and monitoring**
- 🔧 **API endpoint testing**
- 📁 **File upload testing**
- 📈 **Performance metrics**

## 🔒 Security

- **CORS**: Configured for cross-origin requests
- **File Uploads**: Size limits and type validation
- **Environment Variables**: Secure credential management
- **HTTPS**: All deployments use HTTPS

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

## 📞 Support

- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check this README first
- **Live Demo**: Test the current deployment

---

**Happy Deploying! 🚀**

Visit: [https://kavimarkstar.github.io/everesports_server/](https://kavimarkstar.github.io/everesports_server/) 