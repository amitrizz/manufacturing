// Test environment setup - loads .env.development
// This runs before tests, using CommonJS to avoid import.meta issues

require('dotenv').config({ 
  path: require('path').resolve(__dirname, '../.env.development') 
});

// Ensure test database name matches the main database
process.env.MONGODB_DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';
process.env.NODE_ENV = 'test';