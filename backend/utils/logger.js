import winston from 'winston';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    if (Object.keys(meta).length > 0 && meta.stack) {
      msg += `\n${meta.stack}`;
    } else if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    return msg;
  })
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss.SSS' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} ${level}: ${message}`;
    if (Object.keys(meta).length > 0 && meta.stack) {
      msg += `\n${meta.stack}`;
    } else if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    return msg;
  })
);

const transports = [];

// Console transport (always enabled)
transports.push(
  new winston.transports.Console({
    format: process.env.NODE_ENV === 'production' ? logFormat : consoleFormat,
    level: process.env.LOG_LEVEL || 'info',
  })
);

// File transport for production
if (process.env.NODE_ENV === 'production') {
  transports.push(
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      format: logFormat,
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
    }),
    new winston.transports.File({
      filename: 'logs/combined.log',
      format: logFormat,
      maxsize: 10 * 1024 * 1024,
      maxFiles: 5,
    })
  );
}

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports,
  defaultMeta: { service: 'manufacturing-backend' },
  exitOnError: false,
});

// Helper functions for structured logging
export const logApiRequest = (method, url, ip, userAgent) => {
  logger.info('API Request', { method, url, ip, userAgent });
};

export const logApiResponse = (method, url, statusCode, durationMs) => {
  const level = statusCode >= 500 ? 'error' : statusCode >= 400 ? 'warn' : 'info';
  logger.log(level, 'API Response', { method, url, statusCode, durationMs });
};

export const logDatabaseOperation = (operation, collection, durationMs, success, error = null) => {
  if (success) {
    logger.info('Database Operation', { operation, collection, durationMs });
  } else {
    logger.error('Database Operation Failed', { operation, collection, durationMs, error: error?.message });
  }
};

export const logAuthEvent = (event, userId, ip, success, details = {}) => {
  const level = success ? 'info' : 'warn';
  logger.log(level, `Auth: ${event}`, { userId, ip, success, ...details });
};

export const logBusinessEvent = (event, companyId, details = {}) => {
  logger.info(`Business: ${event}`, { companyId, ...details });
};

export const logMigration = (step, message, details = {}) => {
  logger.info(`Migration: ${step}`, { message, ...details });
};

export default logger;