const sharp = require('sharp');
const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/config');
const logger = require('./logger');

class FileProcessor {
  constructor() {
    this.ensureDirectories();
  }

  ensureDirectories() {
    const dirs = [
      config.upload.uploadDir,
      path.join(config.upload.uploadDir, 'profiles'),
      path.join(config.upload.uploadDir, 'coverphotos'),
      path.join(config.upload.uploadDir, 'posts'),
      path.join(config.upload.uploadDir, 'posts/images'),
      path.join(config.upload.uploadDir, 'posts/videos'),
      path.join(config.upload.uploadDir, 'stories'),
      path.join(config.upload.uploadDir, 'weapon'),
      path.join(config.upload.uploadDir, 'maps'),
      path.join(config.upload.uploadDir, 'tournament'),
      path.join(config.upload.uploadDir, 'banner'),
      path.join(config.upload.uploadDir, 'thumbnails')
    ];

    dirs.forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });
  }

  async processImage(filePath, options = {}) {
    try {
      const {
        quality = config.upload.imageQuality,
        width,
        height,
        format = 'jpeg',
        createThumbnail = true
      } = options;

      const filename = path.basename(filePath);
      const dir = path.dirname(filePath);
      const nameWithoutExt = path.parse(filename).name;
      const ext = path.extname(filename);

      let processedImage = sharp(filePath);

      // Resize if dimensions provided
      if (width || height) {
        processedImage = processedImage.resize(width, height, {
          fit: 'inside',
          withoutEnlargement: true
        });
      }

      // Optimize image
      if (config.upload.enableImageOptimization) {
        processedImage = processedImage[format]({ quality });
      }

      const outputPath = path.join(dir, `${nameWithoutExt}_processed.${format}`);
      await processedImage.toFile(outputPath);

      // Create thumbnail if requested
      let thumbnailPath = null;
      if (createThumbnail) {
        thumbnailPath = await this.createThumbnail(filePath, dir, nameWithoutExt);
      }

      // Clean up original if it's different from output
      if (outputPath !== filePath) {
        fs.unlinkSync(filePath);
      }

      logger.info(`Image processed successfully: ${outputPath}`);
      return {
        originalPath: filePath,
        processedPath: outputPath,
        thumbnailPath,
        size: fs.statSync(outputPath).size
      };
    } catch (error) {
      logger.error('Image processing error:', error);
      throw new Error(`Failed to process image: ${error.message}`);
    }
  }

  async createThumbnail(filePath, outputDir, baseName) {
    try {
      const thumbnailPath = path.join(outputDir, `${baseName}_thumb.jpg`);
      
      await sharp(filePath)
        .resize(config.upload.thumbnailSize, config.upload.thumbnailSize, {
          fit: 'cover',
          position: 'center'
        })
        .jpeg({ quality: 80 })
        .toFile(thumbnailPath);

      logger.info(`Thumbnail created: ${thumbnailPath}`);
      return thumbnailPath;
    } catch (error) {
      logger.error('Thumbnail creation error:', error);
      return null;
    }
  }

  async processVideo(filePath, options = {}) {
    try {
      const {
        format = 'mp4',
        quality = 'medium',
        createThumbnail = true
      } = options;

      const filename = path.basename(filePath);
      const dir = path.dirname(filePath);
      const nameWithoutExt = path.parse(filename).name;

      return new Promise((resolve, reject) => {
        const outputPath = path.join(dir, `${nameWithoutExt}_processed.${format}`);
        let thumbnailPath = null;

        const command = ffmpeg(filePath)
          .outputOptions([
            '-c:v libx264',
            '-c:a aac',
            '-preset medium',
            '-crf 23',
            '-movflags +faststart'
          ])
          .output(outputPath)
          .on('end', async () => {
            try {
              if (createThumbnail) {
                thumbnailPath = await this.createVideoThumbnail(filePath, dir, nameWithoutExt);
              }

              const result = {
                originalPath: filePath,
                processedPath: outputPath,
                thumbnailPath,
                size: fs.statSync(outputPath).size
              };

              // Clean up original if different from output
              if (outputPath !== filePath) {
                fs.unlinkSync(filePath);
              }

              logger.info(`Video processed successfully: ${outputPath}`);
              resolve(result);
            } catch (error) {
              reject(error);
            }
          })
          .on('error', (error) => {
            logger.error('Video processing error:', error);
            reject(new Error(`Failed to process video: ${error.message}`));
          });

        command.run();
      });
    } catch (error) {
      logger.error('Video processing error:', error);
      throw new Error(`Failed to process video: ${error.message}`);
    }
  }

  async createVideoThumbnail(filePath, outputDir, baseName) {
    try {
      const thumbnailPath = path.join(outputDir, `${baseName}_thumb.jpg`);

      return new Promise((resolve, reject) => {
        ffmpeg(filePath)
          .screenshots({
            timestamps: ['50%'],
            filename: path.basename(thumbnailPath),
            folder: outputDir,
            size: `${config.upload.thumbnailSize}x${config.upload.thumbnailSize}`
          })
          .on('end', () => {
            logger.info(`Video thumbnail created: ${thumbnailPath}`);
            resolve(thumbnailPath);
          })
          .on('error', (error) => {
            logger.error('Video thumbnail creation error:', error);
            resolve(null);
          });
      });
    } catch (error) {
      logger.error('Video thumbnail creation error:', error);
      return null;
    }
  }

  validateFile(file) {
    const allowedTypes = config.getAllowedFileTypes();
    const maxSize = config.getMaxFileSizeBytes();

    // Check file type
    if (!allowedTypes.includes(file.mimetype)) {
      throw new Error(`Invalid file type: ${file.mimetype}`);
    }

    // Check file size
    if (file.size > maxSize) {
      throw new Error(`File too large: ${file.size} bytes (max: ${maxSize})`);
    }

    // Check for dangerous extensions
    const dangerousExtensions = ['.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs'];
    const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
    if (dangerousExtensions.includes(fileExtension)) {
      throw new Error(`Dangerous file type not allowed: ${fileExtension}`);
    }

    return true;
  }

  generateUniqueFilename(originalName, directory) {
    const ext = path.extname(originalName);
    const uniqueId = uuidv4();
    const timestamp = Date.now();
    return path.join(directory, `${timestamp}-${uniqueId}${ext}`);
  }

  async cleanupFile(filePath) {
    try {
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        logger.info(`File cleaned up: ${filePath}`);
      }
    } catch (error) {
      logger.error(`Failed to cleanup file ${filePath}:`, error);
    }
  }

  getFileInfo(filePath) {
    try {
      const stats = fs.statSync(filePath);
      return {
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime,
        isFile: stats.isFile(),
        isDirectory: stats.isDirectory()
      };
    } catch (error) {
      logger.error(`Failed to get file info for ${filePath}:`, error);
      return null;
    }
  }

  async compressFile(filePath, quality = 0.8) {
    try {
      const ext = path.extname(filePath).toLowerCase();
      const isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
      const isVideo = ['.mp4', '.avi', '.mov', '.wmv'].includes(ext);

      if (isImage) {
        return await this.processImage(filePath, { quality: Math.floor(quality * 100) });
      } else if (isVideo && config.upload.enableVideoProcessing) {
        return await this.processVideo(filePath, { quality: quality > 0.5 ? 'high' : 'medium' });
      }

      return { originalPath: filePath, processedPath: filePath };
    } catch (error) {
      logger.error('File compression error:', error);
      throw error;
    }
  }
}

module.exports = new FileProcessor(); 