require('dotenv').config();

const config = {
  // Server Configuration
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // MongoDB Configuration
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/everesports',
    dbName: process.env.MONGODB_DB_NAME || 'everesports',
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    }
  },

  // File Upload Configuration
  upload: {
    maxFileSize: process.env.MAX_FILE_SIZE || '100MB',
    allowedImageTypes: (process.env.ALLOWED_IMAGE_TYPES || 'image/jpeg,image/png,image/gif,image/webp').split(','),
    allowedVideoTypes: (process.env.ALLOWED_VIDEO_TYPES || 'video/mp4,video/avi,video/mov,video/wmv').split(','),
    allowedAudioTypes: (process.env.ALLOWED_AUDIO_TYPES || 'audio/mp3,audio/wav,audio/aac').split(','),
    maxFilesPerRequest: parseInt(process.env.MAX_FILES_PER_REQUEST) || 10,
    uploadDir: process.env.UPLOAD_DIR || 'uploads',
    enableImageOptimization: process.env.ENABLE_IMAGE_OPTIMIZATION === 'true',
    imageQuality: parseInt(process.env.IMAGE_QUALITY) || 80,
    thumbnailSize: parseInt(process.env.THUMBNAIL_SIZE) || 300,
    enableVideoProcessing: process.env.ENABLE_VIDEO_PROCESSING === 'true',
    videoMaxDuration: parseInt(process.env.VIDEO_MAX_DURATION) || 300,
  },

  // Security Configuration
  security: {
    jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-here',
    rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
    rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    corsOrigin: (process.env.CORS_ORIGIN || 'https://kavimarkstar.github.io').split(','),
  },

  // Logging Configuration
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || 'logs/app.log',
  },

  // Health Check Configuration
  health: {
    endpoint: process.env.HEALTH_CHECK_ENDPOINT || '/api/health',
  },

  // File size limits in bytes
  getMaxFileSizeBytes() {
    const size = this.upload.maxFileSize;
    const units = { 'B': 1, 'KB': 1024, 'MB': 1024*1024, 'GB': 1024*1024*1024 };
    const match = size.match(/^(\d+)([BKMGT]?B)$/);
    if (match) {
      const [, value, unit] = match;
      return parseInt(value) * (units[unit] || 1);
    }
    return 100 * 1024 * 1024; // Default 100MB
  },

  // Allowed file types
  getAllowedFileTypes() {
    return [
      ...this.upload.allowedImageTypes,
      ...this.upload.allowedVideoTypes,
      ...this.upload.allowedAudioTypes
    ];
  }
};

module.exports = config; 