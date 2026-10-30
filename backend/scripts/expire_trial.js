import { connectToMongo } from '../config/db.js';

async function expireTrial() {
  const db = await connectToMongo();
  const now = Date.now();
  // Valid until 4 days ago so it passes 7 days trial + 3 days grace and is fully EXPIRED
  const expiredDate = now - (4 * 24 * 60 * 60 * 1000);
  const trialStart = now - (11 * 24 * 60 * 60 * 1000);

  const result = await db.collection('companies').updateOne(
    { $or: [{ code: 'GOOGLE' }, { company_code: 'GOOGLE' }] },
    {
      $set: {
        subscription: {
          status: 'EXPIRED',
          plan: 'FREE_TRIAL',
          trial_days: 7,
          trial_start_date: trialStart,
          trial_end_date: expiredDate,
          valid_until: expiredDate,
          created_at: trialStart,
          updated_at: now,
        }
      }
    }
  );

  console.log('Successfully expired trial for Google: matched', result.matchedCount, 'modified', result.modifiedCount);
  process.exit(0);
}

expireTrial().catch(e => {
  console.error(e);
  process.exit(1);
});
