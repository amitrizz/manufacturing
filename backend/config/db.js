import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.DATABASE_URL || '';
const DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';

let client = null;
let db = null;

/**
 * Connect to MongoDB Atlas (singleton instance)
 */
export async function connectToMongo() {
  if (!db) {
    if (!MONGODB_URI) {
      throw new Error('DATABASE_URL environment variable is not defined.');
    }
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(DB_NAME);
    console.log(`✅ MongoDB connected successfully to database: ${DB_NAME}`);
  }
  return db;
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
