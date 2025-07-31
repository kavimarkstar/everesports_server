// GitHub Pages serverless function for health check
export default function handler(req, res) {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    server: 'EverEsports Server',
    version: '1.0.0',
    deployment: 'GitHub Pages',
    uptime: process.uptime ? process.uptime() : 0
  });
} 