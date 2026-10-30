import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectToMongo, DB_NAME } from './config/db.js';
import apiRoutes from './routes/index.js';
import { errorHandler } from './middlewares/errorHandler.js';
import { tenantMiddleware } from './middlewares/tenant.js';
import { createRateLimiter, corsMiddleware } from './middlewares/validation.js';
import { logger, logApiRequest, logApiResponse } from './utils/logger.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Request logging middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  const ip = req.ip || req.connection?.remoteAddress || 'unknown';
  const userAgent = req.get('user-agent') || 'unknown';
  
  logApiRequest(req.method, req.originalUrl, ip, userAgent);
  
  res.on('finish', () => {
    const durationMs = Date.now() - startTime;
    logApiResponse(req.method, req.originalUrl, res.statusCode, durationMs);
  });
  
  next();
});

// CORS Configuration
const corsOrigins = process.env.CORS_ORIGINS?.split(',').map(o => o.trim()) || [
  'http://localhost:8081',
  'http://192.168.1.53:8081',
  'exp://192.168.1.53:8081',
];
app.use(corsMiddleware(corsOrigins));

// Body parsing with size limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Global Rate Limiting
const isDev = process.env.NODE_ENV !== 'production';
const rateLimitWindowMs = parseInt(process.env.RATE_LIMIT_WINDOW_MS) || (isDev ? 60 * 1000 : 15 * 60 * 1000); // 1 min dev, 15 min prod
const rateLimitMaxRequests = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || (isDev ? 1000 : 100); // 1000 dev, 100 prod
app.use(createRateLimiter(rateLimitWindowMs, rateLimitMaxRequests));

// Tenant extraction
app.use(tenantMiddleware);

// API Version Prefix
app.use('/api/v1', apiRoutes);

// Legacy /api routes (redirect to v1)
app.use('/api', (req, res) => {
  res.redirect(301, `/api/v1${req.originalUrl.replace('/api', '')}`);
});

// Root Welcome & Health Check
app.get('/', (req, res) => {
  res.json({
    name: 'Manufacturing ERP Backend API',
    status: 'running',
    version: '2.0.0',
    documentation: '/api/v1/health',
    apiVersions: ['v1'],
  });
});

// Health check (no auth required)
app.get('/health', async (req, res) => {
  try {
    const { connectToMongo: connect, DB_NAME } = await import('./config/db.js');
    const db = await connect();
    const cols = await db.listCollections().toArray();
    res.json({
      status: 'ok',
      database: DB_NAME,
      collectionsCount: cols.length,
      version: '2.0.0',
      timestamp: Date.now(),
    });
  } catch (err) {
    res.status(503).json({ status: 'error', error: err.message });
  }
});

// Global Error Handler
app.use(errorHandler);

/**
 * Start the HTTP server - only call this when running directly, not when imported
 */
export async function startServer(port = PORT) {
  return new Promise((resolve) => {
    const server = app.listen(port, '0.0.0.0', async () => {
      if (process.env.NODE_ENV !== 'production') {
        logger.info('Server starting', { 
          port, 
          db: DB_NAME,
          auth: process.env.API_KEY && process.env.API_KEY !== 'your-secure-api-key-here-min-32-chars' ? 'enabled' : 'disabled (dev mode)',
          env: process.env.NODE_ENV,
        });
      }
      try {
        await connectToMongo();
      } catch (err) {
        logger.error('Failed to connect to MongoDB on startup', { error: err.message });
      }
      resolve(server);
    });
  });
}

export default app;

export async function createApp() {
  return app;
}

// Only auto-start when run directly (not imported)
// Avoid import.meta.url which isn't available in Jest test environment
// Use process.argv[1] to check if this file was run directly
const isMainModule = process.argv[1] && process.argv[1].endsWith('server.js');

if (isMainModule) {
  startServer(PORT).catch(err => {
    logger.error('Failed to start server', { error: err.message });
    process.exit(1);
  });
}
