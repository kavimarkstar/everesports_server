# 🚀 EverEsports Server Startup Guide

## Quick Start Options

### Option 1: Automatic Installation (Recommended)

#### Windows Users:
1. **Double-click** `install.bat` or `install.ps1`
2. The script will automatically:
   - Check if Node.js is installed
   - Download and install Node.js if needed
   - Install project dependencies
   - Start the server

#### Linux/Mac Users:
1. **Open terminal** in the project directory
2. **Run**: `./install.sh` or `bash install.sh`
3. The script will automatically handle everything

### Option 2: Manual Installation

#### Prerequisites:
- Node.js (v16 or higher)
- npm (comes with Node.js)
- Git

#### Steps:
1. **Install Node.js** from [https://nodejs.org/](https://nodejs.org/)
2. **Open terminal/command prompt** in the project directory
3. **Install dependencies**: `npm install`
4. **Start server**: `node server.js`

## 🎯 What You Get

After running any of the above methods, you'll have:

- ✅ **Node.js** automatically installed (if not present)
- ✅ **All dependencies** installed
- ✅ **Server running** on `http://localhost:3000`
- ✅ **Beautiful landing page** at the root URL
- ✅ **API endpoints** ready for your gaming platform

## 📱 Access Your Server

Once the server is running:

- **Main Page**: http://localhost:3000
- **API Health Check**: http://localhost:3000/health
- **File Uploads**: http://localhost:3000/uploads

## 🔧 Server Features

Your server includes:

### File Upload System
- Profile images: `POST /upload`
- Cover photos: `POST /upload-cover`
- Post media: `POST /upload-post-media`
- Stories: `POST /api/stories`
- Gaming content: `POST /upload/weapon`, `POST /upload/maps`
- Tournament images: `POST /upload/tournament`
- Banner images: `POST /uploads/banner`

### Social Media Features
- Create posts: `POST /create-post`
- Get stories: `GET /api/stories`
- Update tournament presets: `PUT /tournament-preset/:id`

### File Management
- Delete files: `DELETE /delete`
- Update records: `PUT /update/:id`

## 🛠️ Troubleshooting

### Common Issues:

#### "Node.js not found"
- **Solution**: Run the automatic installation script
- **Manual**: Download from [https://nodejs.org/](https://nodejs.org/)

#### "npm not found"
- **Solution**: Restart your terminal/command prompt
- **Alternative**: Reinstall Node.js

#### "Port 3000 already in use"
- **Solution**: Change the port in `server.js` or kill the process using port 3000
- **Windows**: `netstat -ano | findstr :3000` then `taskkill /PID <PID>`
- **Linux/Mac**: `lsof -ti:3000 | xargs kill -9`

#### "MongoDB connection failed"
- **Solution**: Make sure MongoDB is running and accessible
- **Check**: Update the `MONGODB_URI` in your environment variables

## 📁 Project Structure

```
everesports_server/
├── server.js              # Main server file
├── index.html             # Landing page
├── install.bat            # Windows auto-install
├── install.ps1            # PowerShell auto-install
├── install.sh             # Linux/Mac auto-install
├── package.json           # Dependencies
├── uploads/               # Uploaded files
│   ├── profiles/          # Profile images
│   ├── coverphotos/       # Cover photos
│   ├── posts/             # Post media
│   ├── stories/           # Story images
│   ├── weapon/            # Weapon images
│   ├── maps/              # Map images
│   ├── tournament/        # Tournament images
│   └── banner/            # Banner images
└── .github/workflows/     # CI/CD configuration
    └── deploy.yml         # Deployment workflow
```

## 🚀 Deployment

### GitHub Actions (Automatic)
- Push to `main` branch triggers deployment
- Supports multiple hosting platforms:
  - Vercel
  - Railway
  - Render
  - Heroku

### Manual Deployment
1. **Clone repository** on your server
2. **Run installation script**: `./install.sh` or `install.bat`
3. **Set environment variables** (MongoDB URI, etc.)
4. **Start server**: `node server.js`

### Using PM2 (Production)
```bash
npm install -g pm2
pm2 start server.js --name "everesports-server"
pm2 save
pm2 startup
```

## 📞 Support

If you encounter any issues:

1. **Check the console output** for error messages
2. **Verify Node.js version**: `node --version`
3. **Check npm version**: `npm --version`
4. **Ensure MongoDB is running** and accessible
5. **Review the troubleshooting section** above

## 🎮 Ready to Go!

Your EverEsports server is now ready to handle:
- File uploads for gaming content
- Social media features
- Tournament management
- User profile management
- Media streaming

Visit `http://localhost:3000` to see your server in action! 