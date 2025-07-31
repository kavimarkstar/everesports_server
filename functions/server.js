const express = require('express');
const serverless = require('serverless-http');

// Import your main server logic
const app = express();

// Add CORS for GitHub Pages
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    server: 'EverEsports Server',
    version: '1.0.0',
    deployment: 'Netlify Functions',
    uptime: process.uptime()
  });
});

// Graceful shutdown endpoint
app.post('/api/shutdown', (req, res) => {
  res.json({ message: 'Server shutting down gracefully' });
});

// Export the serverless handler
module.exports.handler = serverless(app); 