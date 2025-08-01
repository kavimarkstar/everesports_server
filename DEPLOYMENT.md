# 🚀 EverEsports Server - Deployment Guide

This guide will help you deploy your EverEsports server to various hosting platforms.

## 📋 Prerequisites

- Node.js >= 16.0.0
- Git
- MongoDB database (Atlas recommended for cloud hosting)
- GitHub account

## 🎯 Quick Deployment Options

### Option 1: Vercel (Recommended - Easiest)

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Deploy to Vercel**
   ```bash
   vercel --prod
   ```

3. **Set Environment Variables in Vercel Dashboard**
   - Go to your project settings
   - Add these environment variables:
     - `MONGODB_URI` - Your MongoDB connection string
     - `JWT_SECRET` - A secure random string
     - `CORS_ORIGIN` - `https://kavimarkstar.github.io`
     - `NODE_ENV` - `production`

### Option 2: Netlify

1. **Connect GitHub Repository**
   - Go to [Netlify](https://netlify.com)
   - Connect your GitHub repository
   - Set build command: `npm install`
   - Set publish directory: `.`

2. **Set Environment Variables**
   - Go to Site settings > Environment variables
   - Add the same variables as Vercel

### Option 3: Railway

1. **Install Railway CLI**
   ```bash
   npm i -g @railway/cli
   ```

2. **Deploy to Railway**
   ```bash
   railway login
   railway init
   railway up
   ```

3. **Set Environment Variables**
   - Use Railway dashboard or CLI

### Option 4: Render

1. **Connect GitHub Repository**
   - Go to [Render](https://render.com)
   - Create new Web Service
   - Connect your GitHub repository

2. **Configure Service**
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Environment: `Node`

3. **Set Environment Variables**
   - Add in Render dashboard

## 🔧 Environment Configuration

Create a `.env` file with these variables:

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# MongoDB Configuration
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/everesports
MONGODB_DB_NAME=everesports

# Security Configuration
JWT_SECRET=your-super-secret-jwt-key-here
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS Configuration
CORS_ORIGIN=https://kavimarkstar.github.io

# File Upload Configuration
MAX_FILE_SIZE=100MB
ENABLE_IMAGE_OPTIMIZATION=true
ENABLE_VIDEO_PROCESSING=true
```

## 🗄️ Database Setup

### MongoDB Atlas (Recommended)

1. **Create MongoDB Atlas Account**
   - Go to [MongoDB Atlas](https://mongodb.com/atlas)
   - Create free cluster

2. **Get Connection String**
   - Click "Connect"
   - Choose "Connect your application"
   - Copy the connection string

3. **Update Environment Variables**
   - Replace `username`, `password`, and `cluster` in the connection string
   - Add to your hosting platform's environment variables

## 🚀 Deployment Commands

### Using the Deployment Script

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment script
npm run deploy
```

### Manual Deployment

```bash
# Install dependencies
npm install

# Run tests
npm test

# Deploy to Vercel
npm run deploy:vercel

# Deploy to Netlify
npm run deploy:netlify
```

## 🔍 Testing Your Deployment

1. **Health Check**
   ```bash
   curl https://your-app.vercel.app/api/health
   ```

2. **Test File Upload**
   - Use the `client-example.html` file
   - Update the `SERVER_URL` variable
   - Open in browser and test uploads

3. **Monitor Logs**
   - Check your hosting platform's logs
   - Monitor for errors and performance

## 📊 Monitoring & Maintenance

### Health Monitoring

Your server includes built-in health monitoring:

- **Health Endpoint**: `GET /api/health`
- **Automatic Logging**: All requests and errors are logged
- **Performance Metrics**: Memory usage and uptime tracking

### Log Files

Logs are stored in the `logs/` directory:
- `combined.log` - All logs
- `error.log` - Error logs only

### Environment Variables to Monitor

- `NODE_ENV` - Should be `production`
- `MONGODB_URI` - Database connection
- `JWT_SECRET` - Security key
- `CORS_ORIGIN` - Allowed origins

## 🔒 Security Checklist

- [ ] Environment variables are set
- [ ] CORS origin is configured correctly
- [ ] JWT secret is secure and unique
- [ ] MongoDB connection is secure
- [ ] Rate limiting is enabled
- [ ] File upload limits are set
- [ ] HTTPS is enabled (automatic on most platforms)

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check MongoDB URI format
   - Verify network access
   - Check credentials

2. **CORS Errors**
   - Verify `CORS_ORIGIN` is set correctly
   - Check client domain matches

3. **File Upload Fails**
   - Check file size limits
   - Verify file type restrictions
   - Check storage permissions

4. **Rate Limiting**
   - Check request frequency
   - Verify rate limit settings

### Debug Commands

```bash
# Check server status
curl -X GET https://your-app.vercel.app/api/health

# Test file upload
curl -X POST -F "file=@test.jpg" -F "userId=test" https://your-app.vercel.app/upload/profile

# Check logs (if available)
# Use your hosting platform's log viewer
```

## 📈 Performance Optimization

1. **Enable Compression**
   - Already configured in the server

2. **Image Optimization**
   - Set `ENABLE_IMAGE_OPTIMIZATION=true`
   - Adjust `IMAGE_QUALITY` as needed

3. **Video Processing**
   - Set `ENABLE_VIDEO_PROCESSING=true`
   - Configure `VIDEO_MAX_DURATION`

4. **Database Optimization**
   - Use MongoDB Atlas for better performance
   - Configure connection pooling

## 🔄 Updates & Maintenance

### Updating Your Server

1. **Pull Latest Changes**
   ```bash
   git pull origin main
   ```

2. **Update Dependencies**
   ```bash
   npm install
   ```

3. **Redeploy**
   ```bash
   npm run deploy:vercel
   ```

### Backup Strategy

1. **Database Backups**
   - Use MongoDB Atlas automated backups
   - Export data regularly

2. **File Backups**
   - Uploaded files are stored in `uploads/`
   - Consider cloud storage for large files

## 📞 Support

If you encounter issues:

1. Check the logs in your hosting platform
2. Verify environment variables
3. Test with the client example
4. Check the health endpoint
5. Review the README.md for API documentation

## 🎉 Success!

Once deployed, your EverEsports server will be available at:
- **Vercel**: `https://your-app.vercel.app`
- **Netlify**: `https://your-app.netlify.app`
- **Railway**: `https://your-app.railway.app`

Update your client applications to use the new server URL and enjoy your industrial-grade file upload system! 🚀 