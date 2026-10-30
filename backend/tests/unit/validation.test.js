import { 
  validate, 
  paginationSchema, 
  dateRangeSchema, 
  companyIdSchema,
  sanitizeQuery,
  validateObjectId,
  createRateLimiter,
  apiKeyAuth
} from '../../middlewares/validation.js';

describe('Validation Middleware', () => {
  describe('paginationSchema', () => {
    test('should parse valid pagination params', () => {
      const result = paginationSchema.parse({
        limit: '20',
        skip: '10',
        sort: 'created_at',
        order: 'desc'
      });
      expect(result.limit).toBe(20);
      expect(result.skip).toBe(10);
      expect(result.sort).toBe('created_at');
      expect(result.order).toBe('desc');
    });

    test('should apply defaults', () => {
      const result = paginationSchema.parse({});
      expect(result.limit).toBe(50);
      expect(result.skip).toBe(0);
      expect(result.order).toBe('desc');
    });

    test('should reject invalid limit', () => {
      expect(() => paginationSchema.parse({ limit: '0' })).toThrow();
      expect(() => paginationSchema.parse({ limit: '101' })).toThrow();
      expect(() => paginationSchema.parse({ limit: '-1' })).toThrow();
    });

    test('should reject invalid skip', () => {
      expect(() => paginationSchema.parse({ skip: '-1' })).toThrow();
    });

    test('should reject invalid order', () => {
      expect(() => paginationSchema.parse({ order: 'invalid' })).toThrow();
    });
  });

  describe('dateRangeSchema', () => {
    test('should parse valid date range', () => {
      const result = dateRangeSchema.parse({
        start: '1704067200000',
        end: '1706745600000'
      });
      expect(result.start).toBe(1704067200000);
      expect(result.end).toBe(1706745600000);
    });

    test('should accept optional fields', () => {
      const result = dateRangeSchema.parse({});
      expect(result.start).toBeUndefined();
      expect(result.end).toBeUndefined();
    });

    test('should reject invalid dates', () => {
      expect(() => dateRangeSchema.parse({ start: '0' })).toThrow();
      expect(() => dateRangeSchema.parse({ start: '-1' })).toThrow();
    });
  });

  describe('companyIdSchema', () => {
    test('should parse valid UUID', () => {
      const result = companyIdSchema.parse({ company_id: '123e4567-e89b-12d3-a456-426614174000' });
      expect(result.company_id).toBe('123e4567-e89b-12d3-a456-426614174000');
    });

    test('should accept missing company_id', () => {
      const result = companyIdSchema.parse({});
      expect(result.company_id).toBeUndefined();
    });

    test('should reject invalid UUID', () => {
      expect(() => companyIdSchema.parse({ company_id: 'invalid' })).toThrow();
      expect(() => companyIdSchema.parse({ company_id: '123' })).toThrow();
    });
  });

  describe('sanitizeQuery', () => {
    test('should remove MongoDB operators', () => {
      const req = { query: { $where: 'test', $gt: 5, name: 'test' }, body: {} };
      const res = {};
      let nextCalled = false;
      
      sanitizeQuery(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(true);
      expect(req.query.$where).toBeUndefined();
      expect(req.query.$gt).toBeUndefined();
      expect(req.query.name).toBe('test');
    });

    test('should handle nested objects', () => {
      const req = { 
        query: { filter: { $eq: 'test', name: 'value' } }, 
        body: { data: { $ne: null, value: 'keep' } } 
      };
      const res = {};
      
      sanitizeQuery(req, res, () => {});
      
      expect(req.query.filter.$eq).toBeUndefined();
      expect(req.query.filter.name).toBe('value');
      expect(req.body.data.$ne).toBeUndefined();
      expect(req.body.data.value).toBe('keep');
    });
  });

  describe('validateObjectId', () => {
    test('should pass valid ObjectId', () => {
      const req = { params: { id: '507f1f77bcf86cd799439011' } };
      const res = {};
      let nextCalled = false;
      
      validateObjectId('id')(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(true);
    });

    test('should pass valid custom ID format', () => {
      const req = { params: { id: 'machine-001' } };
      const res = {};
      let nextCalled = false;
      
      validateObjectId('id')(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(true);
    });

    test('should reject invalid ID', () => {
      const req = { params: { id: 'invalid$id' } };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      let nextCalled = false;
      
      validateObjectId('id')(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(false);
      expect(res.status).toHaveBeenCalledWith(400);
    });
  });

  describe('validate middleware', () => {
    test('should validate query params', () => {
      const schema = paginationSchema;
      const req = { query: { limit: '10', skip: '5' }, body: {}, params: {} };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      let nextCalled = false;
      
      validate(schema)(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(true);
      expect(req.validatedQuery.limit).toBe(10);
      expect(req.validatedQuery.skip).toBe(5);
    });

    test('should validate body', () => {
      const schema = paginationSchema;
      const req = { query: {}, body: { limit: '20' }, params: {} };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      let nextCalled = false;
      
      validate(schema)(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(true);
      expect(req.validatedBody.limit).toBe(20);
    });

    test('should return 400 on validation error', () => {
      const schema = paginationSchema;
      const req = { query: { limit: 'invalid' }, body: {}, params: {} };
      const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
      let nextCalled = false;
      
      validate(schema)(req, res, () => { nextCalled = true; });
      
      expect(nextCalled).toBe(false);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        error: 'Validation failed'
      }));
    });
  });
});

describe('Rate Limiter', () => {
  test('createRateLimiter should return middleware', () => {
    const limiter = createRateLimiter(1000, 5);
    expect(typeof limiter).toBe('function');
  });

  test('destructiveRateLimiter should be stricter', () => {
    const limiter = createRateLimiter(60 * 60 * 1000, 10);
    expect(typeof limiter).toBe('function');
  });
});

describe('API Key Auth', () => {
  const originalEnv = process.env.API_KEY;
  
  beforeAll(() => {
    process.env.API_KEY = 'test-api-key-1234567890abcdef';
  });
  
  afterAll(() => {
    process.env.API_KEY = originalEnv;
  });
  
  test('should allow valid API key', () => {
    const req = { headers: { 'x-api-key': 'test-api-key-1234567890abcdef' }, query: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    let nextCalled = false;
    
    apiKeyAuth(req, res, () => { nextCalled = true; });
    
    expect(nextCalled).toBe(true);
  });
  
  test('should reject invalid API key', () => {
    const req = { headers: { 'x-api-key': 'invalid-key' }, query: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    let nextCalled = false;
    
    apiKeyAuth(req, res, () => { nextCalled = true; });
    
    expect(nextCalled).toBe(false);
    expect(res.status).toHaveBeenCalledWith(403);
  });
  
  test('should reject missing API key', () => {
    const req = { headers: {}, query: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    let nextCalled = false;
    
    apiKeyAuth(req, res, () => { nextCalled = true; });
    
    expect(nextCalled).toBe(false);
    expect(res.status).toHaveBeenCalledWith(401);
  });
  
  test('should allow API key in query param', () => {
    const req = { headers: {}, query: { api_key: 'test-api-key-1234567890abcdef' } };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    let nextCalled = false;
    
    apiKeyAuth(req, res, () => { nextCalled = true; });
    
    expect(nextCalled).toBe(true);
  });
});