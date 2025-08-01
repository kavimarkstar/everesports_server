#!/usr/bin/env node

const cluster = require('cluster');
const os = require('os');
const logger = require('./utils/logger');

// Check if this is the master process
if (cluster.isMaster) {
  const numCPUs = os.cpus().length;
  
  console.log(`🚀 Starting EverEsports Server with ${numCPUs} workers...`);
  
  // Fork workers
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }
  
  cluster.on('exit', (worker, code, signal) => {
    console.log(`⚠️  Worker ${worker.process.pid} died. Restarting...`);
    cluster.fork();
  });
  
  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('🛑 Master received SIGTERM, shutting down workers...');
    for (const id in cluster.workers) {
      cluster.workers[id].kill();
    }
    process.exit(0);
  });
  
  process.on('SIGINT', () => {
    console.log('🛑 Master received SIGINT, shutting down workers...');
    for (const id in cluster.workers) {
      cluster.workers[id].kill();
    }
    process.exit(0);
  });
  
} else {
  // Worker process
  try {
    require('./server');
    console.log(`✅ Worker ${process.pid} started`);
  } catch (error) {
    console.error(`❌ Worker ${process.pid} failed to start:`, error);
    process.exit(1);
  }
} 