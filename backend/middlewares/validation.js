import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';

/**
 * CORS middleware
 */
export const corsMiddleware = (allowedOrigins) => {
  return cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, curl, etc.)
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      if (process.env.NODE_ENV !== 'production') {
        // In development, allow localhost variants
        if (origin.match(/^https?:\/\/localhost(:\d+)?$/)) return callback(null, true);
        if (origin.match(/^https?:\/\/192\.168\.\d+\.\d+(:\d+)?$/)) return callback(null, true);
        if (origin.match(/^exp:\/\/.*$/)) return callback(null, true);
      }
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key', 'x-company-id', 'x-tenant-id'],
  });
};

/**
 * Rate limiting configuration
 */
export const createRateLimiter = (windowMs = 15 * 60 * 1000, max = 100) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      error: 'Too many requests from this IP, please try again later.',
      retryAfter: Math.ceil(windowMs / 1000),
    },
    standardHeaders: true,
    legacyHeaders: false,
    // Skip rate limiting for health checks
    skip: (req) => req.path === '/health' || req.path === '/api/v1/health',
  });
};

/**
 * Stricter rate limiter for destructive operations
 */
export const destructiveRateLimiter = createRateLimiter(60 * 60 * 1000, 10); // 10 per hour

/**
 * Validation schemas for common query parameters
 */
export const paginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(500).default(50),
  skip: z.coerce.number().int().min(0).default(0),
  sort: z.string().optional(),
  order: z.enum(['asc', 'desc']).default('desc'),
});

export const dateRangeSchema = z.object({
  start: z.coerce.number().int().positive().optional(),
  end: z.coerce.number().int().positive().optional(),
});

export const companyIdSchema = z.object({
  company_id: z.string().uuid().optional(),
});

/**
 * Validation middleware factory
 */
export const validate = (schema) => (req, res, next) => {
  try {
    // Validate query params (or apply schema defaults when empty for GET requests)
    if (req.method === 'GET') {
      req.validatedQuery = schema.parse(req.query || {});
    } else if (Object.keys(req.query).length > 0) {
      req.validatedQuery = schema.parse(req.query);
    }
    // Validate body
    if (Object.keys(req.body).length > 0) {
      req.validatedBody = schema.parse(req.body);
    }
    // Validate params
    if (Object.keys(req.params).length > 0) {
      req.validatedParams = schema.parse(req.params);
    }
    next();
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Validation failed',
        details: err.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      });
    }
    next(err);
  }
};

/**
 * Validate MongoDB ObjectId format
 */
export const validateObjectId = (paramName = 'id') => (req, res, next) => {
  const value = req.params[paramName];
  if (value && !/^[0-9a-fA-F]{24}$/.test(value) && !/^[a-zA-Z0-9_-]{1,128}$/.test(value)) {
    return res.status(400).json({ error: `Invalid ${paramName} format` });
  }
  next();
};

/**
 * Sanitize query filters to prevent NoSQL injection
 */
export const sanitizeQuery = (req, res, next) => {
  const sanitize = (obj) => {
    if (obj === null || obj === undefined) return obj;
    if (typeof obj !== 'object') return obj;
    
    const cleaned = Array.isArray(obj) ? [] : {};
    for (const [key, value] of Object.entries(obj)) {
      // Block MongoDB operators
      if (key.startsWith('$') || key.includes('$')) {
        continue; // Skip dangerous keys
      }
      cleaned[key] = sanitize(value);
    }
    return cleaned;
  };

  req.query = sanitize(req.query);
  req.body = sanitize(req.body);
  next();
};

/**
 * API Key authentication middleware
 */
export const apiKeyAuth = (req, res, next) => {
  const apiKey = process.env.API_KEY;
  
  // Skip if no API key configured (development mode)
  if (!apiKey || apiKey === 'your-secure-api-key-here-min-32-chars') {
    if (process.env.NODE_ENV !== 'production') {
      console.warn('⚠️  API_KEY not configured - authentication disabled');
    }
    return next();
  }

  const providedKey = req.headers['x-api-key'] || req.query.api_key;
  
  if (!providedKey) {
    return res.status(401).json({ error: 'API key required. Provide via x-api-key header or api_key query param.' });
  }

  if (providedKey !== apiKey) {
    return res.status(403).json({ error: 'Invalid API key' });
  }

  next();
};

/**
 * JWT authentication middleware (for future use)
 */
export const jwtAuth = (req, res, next) => {
  // TODO: Implement JWT verification when needed
  // const token = req.headers.authorization?.replace('Bearer ', '');
  // if (!token) return res.status(401).json({ error: 'Token required' });
  // try { req.user = jwt.verify(token, process.env.JWT_SECRET); next(); }
  // catch { return res.status(403).json({ error: 'Invalid token' }); }
  next();
};

/**
 * Combined auth middleware - supports both API key and JWT
 */
export const authenticate = (req, res, next) => {
  // Try API key first
  const apiKey = process.env.API_KEY;
  const providedApiKey = req.headers['x-api-key'] || req.query.api_key;
  
  if (apiKey && apiKey !== 'your-secure-api-key-here-min-32-chars' && providedApiKey) {
    if (providedApiKey === apiKey) {
      req.authType = 'api_key';
      return next();
    }
    return res.status(403).json({ error: 'Invalid API key' });
  }

  // Fall back to JWT (when implemented)
  // const token = req.headers.authorization?.replace('Bearer ', '');
  // if (token) { ... }

  // Development mode: allow unauthenticated if no API key configured
  if (!apiKey || apiKey === 'your-secure-api-key-here-min-32-chars') {
    if (process.env.NODE_ENV !== 'production') {
      return next();
    }
    return res.status(401).json({ error: 'Authentication required' });
  }

  res.status(401).json({ error: 'Authentication required. Provide API key via x-api-key header.' });
};

/**
 * Require specific company access (for multi-tenancy)
 */
export const requireCompanyAccess = (req, res, next) => {
  const companyId = req.companyId || req.headers['x-company-id'];
  if (!companyId) {
    return res.status(400).json({ error: 'Company ID required (x-company-id header)' });
  }
  
  // Validate company ID format (24 hex chars, UUID, or valid slug string)
  if (!/^[0-9a-f]{24}$/i.test(companyId) && !/^[0-9a-fA-F-]{36}$/.test(companyId) && !/^[a-zA-Z0-9_-]{3,64}$/.test(companyId)) {
    return res.status(400).json({ error: 'Invalid company ID format' });
  }
  
  next();
};

export default {
  createRateLimiter,
  destructiveRateLimiter,
  validate,
  validateObjectId,
  sanitizeQuery,
  apiKeyAuth,
  jwtAuth,
  authenticate,
  requireCompanyAccess,
  paginationSchema,
  dateRangeSchema,
  companyIdSchema,
};