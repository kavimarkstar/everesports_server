const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const { body, validationResult } = require('express-validator');
const config = require('../config/config');
const logger = require('../utils/logger');

// Rate limiting middleware
const createRateLimiter = (windowMs, max, message = 'Too many requests') => {
  return rateLimit({
    windowMs,
    max,
    message: {
      error: message,
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
      res.status(429).json({
        error: message,
        retryAfter: Math.ceil(windowMs / 1000)
      });
    }
  });
};

// General rate limiter
const generalLimiter = createRateLimiter(
  config.security.rateLimitWindowMs,
  config.security.rateLimitMaxRequests,
  'Too many requests from this IP'
);

// Stricter rate limiter for file uploads
const uploadLimiter = createRateLimiter(
  15 * 60 * 1000, // 15 minutes
  10, // 10 uploads per 15 minutes
  'Too many file uploads from this IP'
);

// CORS configuration
const corsOptions = {
  origin: config.security.corsOrigin,
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

// File validation middleware
const validateFileUpload = (req, res, next) => {
  if (!req.file && !req.files) {
    return res.status(400).json({
      error: 'No file uploaded',
      code: 'NO_FILE'
    });
  }

  const files = req.files || [req.file];
  const allowedTypes = config.getAllowedFileTypes();
  const maxSize = config.getMaxFileSizeBytes();

  for (const file of files) {
    if (!file) continue;

    // Check file type
    if (!allowedTypes.includes(file.mimetype)) {
      logger.warn(`Invalid file type uploaded: ${file.mimetype} by IP: ${req.ip}`);
      return res.status(400).json({
        error: 'Invalid file type',
        code: 'INVALID_FILE_TYPE',
        allowedTypes: allowedTypes
      });
    }

    // Check file size
    if (file.size > maxSize) {
      logger.warn(`File too large: ${file.size} bytes by IP: ${req.ip}`);
      return res.status(400).json({
        error: 'File too large',
        code: 'FILE_TOO_LARGE',
        maxSize: maxSize
      });
    }

    // Check for malicious file extensions
    const dangerousExtensions = ['.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs'];
    const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
    if (dangerousExtensions.includes(fileExtension)) {
      logger.warn(`Dangerous file extension detected: ${fileExtension} by IP: ${req.ip}`);
      return res.status(400).json({
        error: 'File type not allowed for security reasons',
        code: 'DANGEROUS_FILE_TYPE'
      });
    }
  }

  next();
};

// Input validation middleware
const validateInput = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    logger.warn(`Validation errors: ${JSON.stringify(errors.array())} by IP: ${req.ip}`);
    return res.status(400).json({
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: errors.array()
    });
  }
  next();
};

// User ID validation
const validateUserId = [
  body('userId')
    .notEmpty()
    .withMessage('User ID is required')
    .isString()
    .withMessage('User ID must be a string')
    .isLength({ min: 1, max: 100 })
    .withMessage('User ID must be between 1 and 100 characters'),
  validateInput
];

// Story validation
const validateStory = [
  body('userId')
    .notEmpty()
    .withMessage('User ID is required'),
  body('description')
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 1, max: 500 })
    .withMessage('Description must be between 1 and 500 characters'),
  validateInput
];

// Post validation
const validatePost = [
  body('userId')
    .notEmpty()
    .withMessage('User ID is required'),
  body('title')
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ min: 1, max: 200 })
    .withMessage('Title must be between 1 and 200 characters'),
  body('description')
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 1, max: 2000 })
    .withMessage('Description must be between 1 and 2000 characters'),
  body('filePaths')
    .isArray({ min: 1 })
    .withMessage('At least one file path is required'),
  validateInput
];

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  logger.error('Unhandled error:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  // Don't leak error details in production
  const isDevelopment = config.nodeEnv === 'development';
  
  res.status(err.status || 500).json({
    error: isDevelopment ? err.message : 'Internal server error',
    code: err.code || 'INTERNAL_ERROR',
    ...(isDevelopment && { stack: err.stack })
  });
};

// 404 handler
const notFoundHandler = (req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.url} from IP: ${req.ip}`);
  res.status(404).json({
    error: 'Endpoint not found',
    code: 'NOT_FOUND',
    path: req.url
  });
};

module.exports = {
  generalLimiter,
  uploadLimiter,
  corsOptions,
  validateFileUpload,
  validateUserId,
  validateStory,
  validatePost,
  errorHandler,
  notFoundHandler,
  helmet: helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  })
}; 