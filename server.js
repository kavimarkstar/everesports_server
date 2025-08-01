const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { MongoClient } = require('mongodb');
const mongoose = require('mongoose');
const compression = require('compression');
const morgan = require('morgan');

// Import our modules
const config = require('./config/config');
const logger = require('./utils/logger');
const fileProcessor = require('./utils/fileProcessor');
const {
  generalLimiter,
  uploadLimiter,
  corsOptions,
  validateFileUpload,
  validateUserId,
  validateStory,
  validatePost,
  errorHandler,
  notFoundHandler,
  helmet
} = require('./middleware/security');

const app = express();
let db;

// ==================== MIDDLEWARE SETUP ====================

// Security middleware
app.use(helmet);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(compression());
app.use(morgan('combined', { stream: logger.stream }));

// CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', corsOptions.origin);
  res.header('Access-Control-Allow-Credentials', corsOptions.credentials);
  res.header('Access-Control-Allow-Methods', corsOptions.methods.join(','));
  res.header('Access-Control-Allow-Headers', corsOptions.allowedHeaders.join(','));
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

// Rate limiting
app.use(generalLimiter);

// ==================== MULTER CONFIGURATIONS ====================

const createMulterStorage = (destination) => {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      const uploadPath = path.join(__dirname, destination);
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      cb(null, uniqueSuffix + path.extname(file.originalname));
    }
  });
};

const createMulterUpload = (destination, fileFilter = null) => {
  const storage = createMulterStorage(destination);
  const limits = {
    fileSize: config.getMaxFileSizeBytes(),
    files: config.upload.maxFilesPerRequest
  };

  return multer({
    storage,
    limits,
    fileFilter: fileFilter || ((req, file, cb) => {
      try {
        fileProcessor.validateFile(file);
        cb(null, true);
      } catch (error) {
        cb(new Error(error.message), false);
      }
    })
  });
};

// Upload configurations for different types
const profileUpload = createMulterUpload('uploads/profiles');
const coverUpload = createMulterUpload('uploads/coverphotos');
const postUpload = createMulterUpload('uploads/posts');
const storyUpload = createMulterUpload('uploads/stories');
const weaponUpload = createMulterUpload('uploads/weapon');
const mapsUpload = createMulterUpload('uploads/maps');
const tournamentUpload = createMulterUpload('uploads/tournament');
const bannerUpload = createMulterUpload('uploads/banner');

// ==================== DATABASE MODELS ====================

const storySchema = new mongoose.Schema({
  userId: { type: String, required: true },
  description: { type: String, required: true },
  imagePath: { type: String, required: true },
  view: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Story = mongoose.model('Story', storySchema);

// ==================== UTILITY FUNCTIONS ====================

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const iface of Object.values(interfaces)) {
    for (const config of iface || []) {
      if (config.family === 'IPv4' && !config.internal) return config.address;
    }
  }
  return 'localhost';
}

async function deleteFile(filePath) {
  try {
    const fullPath = path.join(__dirname, filePath.replace(/^\//, ''));
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
      logger.info(`File deleted: ${filePath}`);
      return true;
    }
    return false;
  } catch (error) {
    logger.error(`Error deleting file ${filePath}:`, error);
    return false;
  }
}

// ==================== ROUTES ====================

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    server: 'EverEsports Server',
    version: '2.0.0',
    mongodb: db ? 'connected' : 'disconnected',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    environment: config.nodeEnv
  });
});

// ==================== PROFILE IMAGE UPLOADS ====================

app.post('/upload/profile', uploadLimiter, profileUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    const { userId, oldImagePath } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'User ID is required', code: 'MISSING_USER_ID' });
    }

    // Delete old image if provided
    if (oldImagePath) {
      await deleteFile(oldImagePath);
    }

    const imagePath = path.join('uploads', 'profiles', req.file.filename).replace(/\\/g, '/');

    // Process image if optimization is enabled
    if (config.upload.enableImageOptimization) {
      const processed = await fileProcessor.processImage(req.file.path, {
        quality: config.upload.imageQuality,
        createThumbnail: true
      });
      
      if (processed.processedPath !== req.file.path) {
        const newImagePath = path.join('uploads', 'profiles', path.basename(processed.processedPath)).replace(/\\/g, '/');
        
        // Update database with new image path
        const result = await db.collection('users').updateOne(
          { userId: userId },
          { $set: { profileImageUrl: newImagePath } }
        );

        logger.info(`Profile image uploaded and processed for user ${userId}`);
        return res.json({ 
          imageUrl: newImagePath, 
          thumbnailUrl: processed.thumbnailPath ? path.join('uploads', 'profiles', path.basename(processed.thumbnailPath)).replace(/\\/g, '/') : null,
          updated: result.modifiedCount > 0 
        });
      }
    }

    // Update database
    const result = await db.collection('users').updateOne(
      { userId: userId },
      { $set: { profileImageUrl: imagePath } }
    );

    logger.info(`Profile image uploaded for user ${userId}`);
    res.json({ imageUrl: imagePath, updated: result.modifiedCount > 0 });
  } catch (error) {
    logger.error('Profile upload error:', error);
    res.status(500).json({ error: 'Failed to upload profile image', code: 'UPLOAD_ERROR' });
  }
});

// ==================== COVER PHOTO UPLOADS ====================

app.post('/upload/cover', uploadLimiter, coverUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    const { userId, oldCoverPath } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'User ID is required', code: 'MISSING_USER_ID' });
    }

    // Delete old cover if provided
    if (oldCoverPath) {
      await deleteFile(oldCoverPath);
    }

    const coverPath = path.join('uploads', 'coverphotos', req.file.filename).replace(/\\/g, '/');

    // Process image if optimization is enabled
    if (config.upload.enableImageOptimization) {
      const processed = await fileProcessor.processImage(req.file.path, {
        quality: config.upload.imageQuality,
        createThumbnail: true
      });
      
      if (processed.processedPath !== req.file.path) {
        const newCoverPath = path.join('uploads', 'coverphotos', path.basename(processed.processedPath)).replace(/\\/g, '/');
        
        const result = await db.collection('users').updateOne(
          { userId: userId },
          { $set: { coverImageUrl: newCoverPath } }
        );

        logger.info(`Cover photo uploaded and processed for user ${userId}`);
        return res.json({ 
          imageUrl: newCoverPath, 
          thumbnailUrl: processed.thumbnailPath ? path.join('uploads', 'coverphotos', path.basename(processed.thumbnailPath)).replace(/\\/g, '/') : null,
          updated: result.modifiedCount > 0 
        });
      }
    }

    const result = await db.collection('users').updateOne(
      { userId: userId },
      { $set: { coverImageUrl: coverPath } }
    );

    logger.info(`Cover photo uploaded for user ${userId}`);
    res.json({ imageUrl: coverPath, updated: result.modifiedCount > 0 });
  } catch (error) {
    logger.error('Cover upload error:', error);
    res.status(500).json({ error: 'Failed to upload cover photo', code: 'UPLOAD_ERROR' });
  }
});

// ==================== POST MEDIA UPLOADS ====================

app.post('/upload/post-media', uploadLimiter, postUpload.array('files', 10), validateFileUpload, async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'User ID is required', code: 'MISSING_USER_ID' });
    }

    const filePaths = [];
    const processedFiles = [];

    for (const file of req.files) {
      const type = file.mimetype.startsWith('image') ? 'images' : 'videos';
      const relativePath = path.join('uploads', 'posts', type, file.filename).replace(/\\/g, '/');
      
      // Process file based on type
      if (file.mimetype.startsWith('image') && config.upload.enableImageOptimization) {
        const processed = await fileProcessor.processImage(file.path, {
          quality: config.upload.imageQuality,
          createThumbnail: true
        });
        
        if (processed.processedPath !== file.path) {
          const newPath = path.join('uploads', 'posts', type, path.basename(processed.processedPath)).replace(/\\/g, '/');
          filePaths.push(newPath);
          processedFiles.push({
            originalPath: relativePath,
            processedPath: newPath,
            thumbnailPath: processed.thumbnailPath ? path.join('uploads', 'posts', type, path.basename(processed.thumbnailPath)).replace(/\\/g, '/') : null
          });
        } else {
          filePaths.push(relativePath);
        }
      } else if (file.mimetype.startsWith('video') && config.upload.enableVideoProcessing) {
        const processed = await fileProcessor.processVideo(file.path, {
          quality: 'medium',
          createThumbnail: true
        });
        
        if (processed.processedPath !== file.path) {
          const newPath = path.join('uploads', 'posts', type, path.basename(processed.processedPath)).replace(/\\/g, '/');
          filePaths.push(newPath);
          processedFiles.push({
            originalPath: relativePath,
            processedPath: newPath,
            thumbnailPath: processed.thumbnailPath ? path.join('uploads', 'posts', type, path.basename(processed.thumbnailPath)).replace(/\\/g, '/') : null
          });
        } else {
          filePaths.push(relativePath);
        }
      } else {
        filePaths.push(relativePath);
      }
    }

    logger.info(`Post media uploaded for user ${userId}: ${filePaths.length} files`);
    res.json({ 
      success: true,
      filePaths: filePaths,
      processedFiles: processedFiles,
      message: 'Files uploaded successfully'
    });
  } catch (error) {
    logger.error('Post media upload error:', error);
    res.status(500).json({ error: 'Failed to upload post media', code: 'UPLOAD_ERROR' });
  }
});

// ==================== STORY UPLOADS ====================

app.post('/api/stories', uploadLimiter, storyUpload.single('image'), validateFileUpload, validateStory, async (req, res) => {
  try {
    const { userId, description } = req.body;

    const relativeImagePath = path.join('uploads', 'stories', req.file.filename).replace(/\\/g, '/');

    // Process image if optimization is enabled
    let finalImagePath = relativeImagePath;
    if (config.upload.enableImageOptimization) {
      const processed = await fileProcessor.processImage(req.file.path, {
        quality: config.upload.imageQuality,
        createThumbnail: true
      });
      
      if (processed.processedPath !== req.file.path) {
        finalImagePath = path.join('uploads', 'stories', path.basename(processed.processedPath)).replace(/\\/g, '/');
      }
    }

    const story = new Story({
      userId,
      description,
      imagePath: finalImagePath,
      view: false
    });

    await story.save();

    logger.info(`Story uploaded for user ${userId}`);
    res.status(201).json({
      success: true,
      data: {
        id: story._id,
        userId: story.userId,
        description: story.description,
        imageUrl: `/${finalImagePath}`,
        view: false,
        createdAt: story.createdAt
      }
    });
  } catch (error) {
    logger.error('Story upload error:', error);
    if (req.file) {
      await fileProcessor.cleanupFile(req.file.path);
    }
    res.status(500).json({ 
      success: false,
      message: 'Internal server error',
      code: 'UPLOAD_ERROR'
    });
  }
});

// ==================== GAME-RELATED UPLOADS ====================

app.post('/upload/weapon', uploadLimiter, weaponUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    const { gameName } = req.body;
    const imagePath = `/uploads/weapon/${req.file.filename}`;

    if (gameName) {
      const result = await db.collection('games').insertOne({ gameName, imagePath });
      res.json({ id: result.insertedId, gameName, imagePath });
    } else {
      res.json({ imagePath });
    }
  } catch (error) {
    logger.error('Weapon upload error:', error);
    res.status(500).json({ message: 'Database error', code: 'DATABASE_ERROR' });
  }
});

app.post('/upload/maps', uploadLimiter, mapsUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    const { gameName } = req.body;
    const imagePath = `/uploads/maps/${req.file.filename}`;

    if (gameName) {
      const result = await db.collection('games').insertOne({ gameName, imagePath });
      res.json({ id: result.insertedId, gameName, imagePath });
    } else {
      res.json({ imagePath });
    }
  } catch (error) {
    logger.error('Maps upload error:', error);
    res.status(500).json({ message: 'Database error', code: 'DATABASE_ERROR' });
  }
});

app.post('/upload/tournament', uploadLimiter, tournamentUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    const { gameName } = req.body;
    const imagePath = `/uploads/tournament/${req.file.filename}`;

    if (gameName) {
      const result = await db.collection('games').insertOne({ gameName, imagePath });
      res.json({ id: result.insertedId, gameName, imagePath });
    } else {
      res.json({ imagePath });
    }
  } catch (error) {
    logger.error('Tournament upload error:', error);
    res.status(500).json({ message: 'Database error', code: 'DATABASE_ERROR' });
  }
});

app.post('/upload/banner', uploadLimiter, bannerUpload.single('file'), validateFileUpload, async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded', code: 'NO_FILE' });
    }
    
    const imagePath = `uploads/banner/${req.file.filename}`;
    res.json({ imagePath });
  } catch (error) {
    logger.error('Banner upload error:', error);
    res.status(500).json({ error: 'Upload failed', code: 'UPLOAD_ERROR' });
  }
});

// ==================== DATA ENDPOINTS ====================

app.get('/api/stories', async (req, res) => {
  try {
    const stories = await Story.find().sort({ createdAt: -1 }).limit(20);
    res.json({
      success: true,
      data: stories.map(story => ({
        id: story._id,
        userId: story.userId,
        description: story.description,
        imageUrl: `/${story.imagePath}`,
        view: story.view,
        createdAt: story.createdAt
      }))
    });
  } catch (error) {
    logger.error('Error fetching stories:', error);
    res.status(500).json({ 
      success: false,
      message: 'Internal server error',
      code: 'DATABASE_ERROR'
    });
  }
});

// ==================== FILE MANAGEMENT ====================

app.delete('/delete', async (req, res) => {
  try {
    const relativePath = req.query.path;
    if (!relativePath) {
      return res.status(400).json({ message: 'No path specified', code: 'MISSING_PATH' });
    }

    const success = await deleteFile(relativePath);
    if (success) {
      res.json({ message: 'File deleted' });
    } else {
      res.status(404).json({ message: 'File not found', code: 'FILE_NOT_FOUND' });
    }
  } catch (error) {
    logger.error('File deletion error:', error);
    res.status(500).json({ message: 'Error deleting file', code: 'DELETE_ERROR' });
  }
});

// ==================== STATIC FILE SERVING ====================

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Video streaming endpoint
app.get('/uploads/posts/videos/:filename', (req, res) => {
  const videoPath = path.join(__dirname, 'uploads/posts/videos', req.params.filename);
  
  if (!fs.existsSync(videoPath)) {
    return res.status(404).json({ error: 'Video not found', code: 'FILE_NOT_FOUND' });
  }

  const stat = fs.statSync(videoPath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    
    if (start >= fileSize || end >= fileSize) {
      res.status(416).json({ error: 'Requested range not satisfiable', code: 'RANGE_NOT_SATISFIABLE' });
      return;
    }
    
    const chunkSize = (end - start) + 1;
    const file = fs.createReadStream(videoPath, { start, end });

    res.writeHead(206, {
      "Content-Range": `bytes ${start}-${end}/${fileSize}`,
      "Accept-Ranges": "bytes",
      "Content-Length": chunkSize,
      "Content-Type": "video/mp4"
    });

    file.pipe(res);
  } else {
    res.writeHead(200, {
      "Content-Length": fileSize,
      "Content-Type": "video/mp4"
    });
    fs.createReadStream(videoPath).pipe(res);
  }
});

// ==================== ERROR HANDLING ====================

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// ==================== SERVER STARTUP ====================

async function startServer() {
  try {
    // Connect to MongoDB
    const client = await MongoClient.connect(config.mongodb.uri, config.mongodb.options);
    db = client.db(config.mongodb.dbName);
    logger.info('✅ Connected to MongoDB (native driver)');

    // Connect Mongoose
    await mongoose.connect(config.mongodb.uri, config.mongodb.options);
    logger.info('✅ Connected to MongoDB (Mongoose)');

    // Start server
const LOCAL_IP = getLocalIp();
const server = app.listen(config.port, () => {
  logger.info(`✅ Server running at: http://${LOCAL_IP}:${config.port}`);
  logger.info(`✅ Environment: ${config.nodeEnv}`);
  logger.info(`✅ Health check: http://${LOCAL_IP}:${config.port}/api/health`);
  
  // For serverless environments (Vercel, Netlify, etc.)
  if (process.env.VERCEL || process.env.NETLIFY) {
    logger.info('🚀 Deployed to serverless platform');
  }
});

// Export for serverless environments
module.exports = app;

  } catch (error) {
    logger.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('🛑 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('🛑 SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Start the server
startServer(); 