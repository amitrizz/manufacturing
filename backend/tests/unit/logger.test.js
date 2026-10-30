import { logger, logApiRequest, logApiResponse, logDatabaseOperation, logAuthEvent, logBusinessEvent, logMigration } from '../../utils/logger.js';

describe('Logger', () => {
  test('should create logger instance', () => {
    expect(logger).toBeDefined();
    expect(typeof logger.info).toBe('function');
    expect(typeof logger.warn).toBe('function');
    expect(typeof logger.error).toBe('function');
    expect(typeof logger.debug).toBe('function');
  });

  test('logApiRequest should log request', () => {
    expect(() => logApiRequest('GET', '/api/health', '127.0.0.1', 'test-agent')).not.toThrow();
  });

  test('logApiResponse should log response', () => {
    expect(() => logApiResponse('GET', '/api/health', 200, 150)).not.toThrow();
  });

  test('logDatabaseOperation should log success', () => {
    expect(() => logDatabaseOperation('find', 'users', 50, true)).not.toThrow();
  });

  test('logDatabaseOperation should log error', () => {
    expect(() => logDatabaseOperation('insert', 'users', 100, false, new Error('Duplicate key'))).not.toThrow();
  });

  test('logAuthEvent should log event', () => {
    expect(() => logAuthEvent('login', 'user-123', '127.0.0.1', true)).not.toThrow();
    expect(() => logAuthEvent('login', 'user-123', '127.0.0.1', false, { reason: 'invalid password' })).not.toThrow();
  });

  test('logBusinessEvent should log event', () => {
    expect(() => logBusinessEvent('grn_created', 'company-123', { grnId: 'grn-001', items: 5 })).not.toThrow();
  });

  test('logMigration should log migration step', () => {
    expect(() => logMigration('START', 'Migration started', { database: 'test' })).not.toThrow();
  });
});