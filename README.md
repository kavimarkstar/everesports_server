# EverEsports Server - Industrial Grade File Upload System

A robust, secure, and scalable file upload server for the EverEsports platform with advanced features like image optimization, video processing, and comprehensive security measures.

## 🚀 Features

### Security
- **Rate Limiting**: Prevents abuse with configurable limits
- **File Validation**: Strict file type and size validation
- **Security Headers**: Helmet.js for comprehensive security
- **Input Validation**: Express-validator for request validation
- **CORS Protection**: Configurable cross-origin resource sharing

### File Processing
- **Image Optimization**: Automatic compression and resizing with Sharp
- **Video Processing**: FFmpeg integration for video optimization
- **Thumbnail Generation**: Automatic thumbnail creation
- **Multiple Formats**: Support for images, videos, and audio files

### Monitoring & Logging
- **Structured Logging**: Winston-based logging with file rotation
- **Health Checks**: Comprehensive health monitoring
- **Error Tracking**: Detailed error logging and handling
- **Performance Monitoring**: Memory and uptime tracking

### Database
- **MongoDB Integration**: Native driver and Mongoose support
- **Connection Pooling**: Optimized database connections
- **Error Handling**: Robust database error management

## 📋 Prerequisites

- Node.js >= 16.0.0
- MongoDB >= 4.4
- FFmpeg (for video processing)
- Git

## 🛠️ Installation & Deployment

### Option 1: GitHub Repository Setup

1. **Fork/Clone the repository**
   ```bash
   git clone https://github.com/kavimarkstar/everesports_server.git
   cd everesports_server
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```env
   PORT=3000
   NODE_ENV=production
   MONGODB_URI=mongodb://username:password@host:port/database
   MONGODB_DB_NAME=everesports
   JWT_SECRET=your-super-secret-jwt-key-here
   CORS_ORIGIN=https://kavimarkstar.github.io
   ```

### Option 2: Deploy to Vercel (Recommended)

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Deploy to Vercel**
   ```bash
   vercel --prod
   ```

3. **Set environment variables in Vercel dashboard**
   - `MONGODB_URI`
   - `JWT_SECRET`
   - `CORS_ORIGIN`

### Option 3: Deploy to Netlify

1. **Connect your GitHub repository to Netlify**
2. **Set environment variables in Netlify dashboard**
3. **Deploy automatically on push to main branch**

### Option 4: Local Development

1. **Install FFmpeg** (for video processing)
   
   **Windows:**
   ```bash
   # Download from https://ffmpeg.org/download.html
   # Add to PATH
   ```
   
   **macOS:**
   ```bash
   brew install ffmpeg
   ```
   
   **Ubuntu/Debian:**
   ```bash
   sudo apt update
   sudo apt install ffmpeg
   ```

2. **Start the server**
   ```bash
   npm run dev
   ```

## 🏃‍♂️ Development

```bash
# Start with nodemon (auto-restart on changes)
npm run dev

# Run tests
npm test

# Lint code
npm run lint

# Format code
npm run format
```

## 📡 API Endpoints

### Health Check
```http
GET /api/health
```

### File Uploads

#### Profile Image
```http
POST /upload/profile
Content-Type: multipart/form-data

Body:
- file: [image file]
- userId: string
- oldImagePath: string (optional)
```

#### Cover Photo
```http
POST /upload/cover
Content-Type: multipart/form-data

Body:
- file: [image file]
- userId: string
- oldCoverPath: string (optional)
```

#### Post Media
```http
POST /upload/post-media
Content-Type: multipart/form-data

Body:
- files: [array of files]
- userId: string
```

#### Stories
```http
POST /api/stories
Content-Type: multipart/form-data

Body:
- image: [image file]
- userId: string
- description: string
```

#### Game Assets
```http
POST /upload/weapon
POST /upload/maps
POST /upload/tournament
POST /upload/banner

Content-Type: multipart/form-data

Body:
- file: [file]
- gameName: string (optional)
```

### Data Retrieval

#### Get Stories
```http
GET /api/stories
```

### File Management

#### Delete File
```http
DELETE /delete?path=uploads/profiles/filename.jpg
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3000 | Server port |
| `NODE_ENV` | development | Environment mode |
| `MONGODB_URI` | mongodb://localhost:27017/everesports | MongoDB connection string |
| `MONGODB_DB_NAME` | everesports | Database name |
| `MAX_FILE_SIZE` | 100MB | Maximum file size |
| `ALLOWED_IMAGE_TYPES` | image/jpeg,image/png,image/gif,image/webp | Allowed image MIME types |
| `ALLOWED_VIDEO_TYPES` | video/mp4,video/avi,video/mov,video/wmv | Allowed video MIME types |
| `ALLOWED_AUDIO_TYPES` | audio/mp3,audio/wav,audio/aac | Allowed audio MIME types |
| `JWT_SECRET` | your-super-secret-jwt-key-here | JWT secret key |
| `RATE_LIMIT_WINDOW_MS` | 900000 | Rate limit window (15 minutes) |
| `RATE_LIMIT_MAX_REQUESTS` | 100 | Maximum requests per window |
| `ENABLE_IMAGE_OPTIMIZATION` | true | Enable image optimization |
| `IMAGE_QUALITY` | 80 | Image quality (1-100) |
| `THUMBNAIL_SIZE` | 300 | Thumbnail size in pixels |
| `ENABLE_VIDEO_PROCESSING` | true | Enable video processing |
| `VIDEO_MAX_DURATION` | 300 | Maximum video duration (seconds) |

## 🛡️ Security Features

### Rate Limiting
- General requests: 100 requests per 15 minutes
- File uploads: 10 uploads per 15 minutes

### File Validation
- File type validation
- File size limits
- Dangerous file extension blocking
- MIME type verification

### Security Headers
- Content Security Policy (CSP)
- HTTP Strict Transport Security (HSTS)
- XSS Protection
- Content Type Options

## 📊 Monitoring

### Health Check Response
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "server": "EverEsports Server",
  "version": "2.0.0",
  "mongodb": "connected",
  "uptime": 3600,
  "memory": {
    "rss": 12345678,
    "heapTotal": 9876543,
    "heapUsed": 5432109,
    "external": 1234567
  },
  "environment": "development"
}
```

### Logging
Logs are stored in the `logs/` directory:
- `combined.log`: All logs
- `error.log`: Error logs only

## 🚨 Error Handling

All endpoints return consistent error responses:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": "Additional information"
}
```

Common error codes:
- `MISSING_USER_ID`: User ID is required
- `NO_FILE`: No file uploaded
- `INVALID_FILE_TYPE`: File type not allowed
- `FILE_TOO_LARGE`: File exceeds size limit
- `DANGEROUS_FILE_TYPE`: Dangerous file extension
- `UPLOAD_ERROR`: File upload failed
- `DATABASE_ERROR`: Database operation failed

## 📁 File Structure

```
everesports_server/
├── config/
│   └── config.js          # Configuration management
├── middleware/
│   └── security.js        # Security middleware
├── utils/
│   ├── logger.js          # Logging utility
│   └── fileProcessor.js   # File processing utility
├── uploads/               # Uploaded files
│   ├── profiles/          # Profile images
│   ├── coverphotos/       # Cover photos
│   ├── posts/             # Post media
│   ├── stories/           # Story images
│   ├── weapon/            # Weapon images
│   ├── maps/              # Map images
│   ├── tournament/        # Tournament images
│   └── banner/            # Banner images
├── logs/                  # Application logs
├── server.js              # Main server file
├── package.json           # Dependencies
├── env.example            # Environment template
└── README.md             # This file
```

## 🔄 Migration from Old System

If you're migrating from the old `index.js`:

1. **Backup your data**
2. **Update your environment variables**
3. **Test the new endpoints**
4. **Update your client applications**

The new system maintains backward compatibility while adding significant improvements.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For support, please open an issue on GitHub or contact the development team.

---

**Version**: 2.0.0  
**Last Updated**: January 2024  
**Maintainer**: kavimarkstar 