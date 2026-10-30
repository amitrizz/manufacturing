import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.DATABASE_URL;
const DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';

if (!MONGODB_URI && process.env.NODE_ENV !== 'test') {
  throw new Error('DATABASE_URL environment variable is not defined. Copy .env.example to .env and configure it.');
}

let client = null;
let db = null;
let currentUri = null;

/**
 * Connect to MongoDB Atlas (singleton instance)
 * For testing, pass a custom URI to override the default
 */
export async function connectToMongo(customUri = null) {
  const uri = customUri || MONGODB_URI;
  
  // If URI changed, reset connection
  if (db && currentUri !== uri) {
    await closeConnection();
  }
  
  if (!db) {
    if (!uri) {
      throw new Error('DATABASE_URL environment variable is not defined. Copy .env.example to .env and configure it.');
    }
    client = new MongoClient(uri);
    await client.connect();
    db = client.db(DB_NAME);
    currentUri = uri;
    if (process.env.NODE_ENV !== 'production') {
      console.log(`✅ MongoDB connected successfully to database: ${DB_NAME}`);
    }
  }
  return db;
}

/**
 * Close database connection (for testing)
 */
export async function closeConnection() {
  if (client) {
    await client.close();
    client = null;
    db = null;
    currentUri = null;
  }
}

/**
 * Get active MongoDB database instance
 */
export function getDb() {
  if (!db) {
    throw new Error('Database not connected. Call connectToMongo() first.');
  }
  return db;
}

/**
 * Normalizes MongoDB document by ensuring a string `id` field exists.
 */
export function normalizeDoc(doc) {
  if (!doc) return null;
  const normalized = { ...doc };
  if (!normalized.id && normalized._id) {
    normalized.id = String(normalized._id);
  }
  return normalized;
}

export { DB_NAME, MONGODB_URI };
