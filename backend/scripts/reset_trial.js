import dotenv from 'dotenv';
dotenv.config();

import { connectToMongo } from '../config/db.js';

async function reset() {
  const db = await connectToMongo();
  const now = Date.now();
  const trialEnd = now + (7 * 24 * 60 * 60 * 1000);
  const result = await db.collection('companies').updateOne(
    { $or: [{ code: 'GOOGLE' }, { company_code: 'GOOGLE' }] },
    {
      $set: {
        subscription: {
          status: 'TRIAL',
          plan: 'FREE_TRIAL',
          trial_days: 7,
          trial_start_date: now,
          trial_end_date: trialEnd,
          valid_until: trialEnd,
          created_at: now,
          updated_at: now,
        }
      }
    }
  );
  console.log('Reset Google subscription: matched', result.matchedCount, 'modified', result.modifiedCount);
  process.exit(0);
}

reset().catch(e => {
  console.error(e);
  process.exit(1);
});
