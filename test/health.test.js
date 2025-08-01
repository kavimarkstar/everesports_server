const request = require('supertest');
const express = require('express');
const { MongoClient } = require('mongodb');

// Mock the config for testing
jest.mock('../config/config', () => ({
  port: 3000,
  nodeEnv: 'test',
  mongodb: {
    uri: 'mongodb://localhost:27017/test',
    dbName: 'test',
    options: {}
  },
  upload: {
    maxFileSize: '10MB',
    allowedImageTypes: ['image/jpeg', 'image/png'],
    allowedVideoTypes: ['video/mp4'],
    allowedAudioTypes: ['audio/mp3'],
    maxFilesPerRequest: 5,
    uploadDir: 'uploads',
    enableImageOptimization: true,
    imageQuality: 80,
    thumbnailSize: 300,
    enableVideoProcessing: true,
    videoMaxDuration: 300
  },
  security: {
    jwtSecret: 'test-secret',
    rateLimitWindowMs: 900000,
    rateLimitMaxRequests: 100,
    corsOrigin: ['https://kavimarkstar.github.io']
  },
  logging: {
    level: 'error',
    file: 'logs/test.log'
  },
  health: {
    endpoint: '/api/health'
  },
  getMaxFileSizeBytes: () => 10 * 1024 * 1024,
  getAllowedFileTypes: () => ['image/jpeg', 'image/png', 'video/mp4', 'audio/mp3']
}));

// Mock the logger
jest.mock('../utils/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  stream: {
    write: jest.fn()
  }
}));

// Mock the file processor
jest.mock('../utils/fileProcessor', () => ({
  validateFile: jest.fn(),
  processImage: jest.fn(),
  processVideo: jest.fn(),
  cleanupFile: jest.fn(),
  generateUniqueFilename: jest.fn(),
  getFileInfo: jest.fn(),
  compressFile: jest.fn()
}));

// Mock the security middleware
jest.mock('../middleware/security', () => ({
  generalLimiter: (req, res, next) => next(),
  uploadLimiter: (req, res, next) => next(),
  corsOptions: {
    origin: ['https://kavimarkstar.github.io'],
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
  },
  validateFileUpload: (req, res, next) => next(),
  validateUserId: [(req, res, next) => next()],
  validateStory: [(req, res, next) => next()],
  validatePost: [(req, res, next) => next()],
  errorHandler: (err, req, res, next) => {
    res.status(500).json({ error: err.message });
  },
  notFoundHandler: (req, res) => {
    res.status(404).json({ error: 'Not found' });
  },
  helmet: (req, res, next) => next()
}));

describe('EverEsports Server Health Check', () => {
  let app;
  let server;

  beforeAll(async () => {
    // Import the app after mocking
    const serverModule = require('../server');
    app = serverModule.app;
    
    // Start server on test port
    server = app.listen(3001);
  });

  afterAll(async () => {
    if (server) {
      await new Promise((resolve) => server.close(resolve));
    }
  });

  test('Health check endpoint should return 200', async () => {
    const response = await request(app)
      .get('/api/health')
      .expect(200);

    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('server', 'EverEsports Server');
    expect(response.body).toHaveProperty('version', '2.0.0');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('uptime');
    expect(response.body).toHaveProperty('environment');
  });

  test('404 handler should work for unknown routes', async () => {
    const response = await request(app)
      .get('/unknown-route')
      .expect(404);

    expect(response.body).toHaveProperty('error', 'Endpoint not found');
    expect(response.body).toHaveProperty('code', 'NOT_FOUND');
  });

  test('CORS headers should be set', async () => {
    const response = await request(app)
      .options('/api/health')
      .expect(200);

    expect(response.headers).toHaveProperty('access-control-allow-origin');
    expect(response.headers).toHaveProperty('access-control-allow-methods');
    expect(response.headers).toHaveProperty('access-control-allow-headers');
  });
}); 