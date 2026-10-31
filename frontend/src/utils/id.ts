import * as Crypto from 'expo-crypto';

/**
 * Generates a MongoDB ObjectId-compatible string (24 hex characters)
 * Format: timestamp(8) + machine(6) + process(4) + counter(6) = 24 hex chars
 */
export function newId(): string {
  const timestamp = Math.floor(Date.now() / 1000).toString(16).padStart(8, '0');
  const randomPart = Crypto.getRandomBytes(8).map(b => b.toString(16).padStart(2, '0')).join('');
  return timestamp + randomPart;
}
