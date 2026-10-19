import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

export async function seedFactories(ctx: SeedContext): Promise<void> {
  const { db } = ctx;
  ctx.factoryId = newId();
  await db.runAsync(
    'INSERT INTO factories (id, name, code, location) VALUES (?, ?, ?, ?)',
    ctx.factoryId,
    'Apex Manufacturing Plant',
    'AMP-01',
    'Pune, IN',
  );

  const lines: { key: 'A' | 'B' | 'C' | 'D'; code: string; name: string }[] = [
    { key: 'A', code: 'LINE-A', name: 'Machining Line A' },
    { key: 'B', code: 'LINE-B', name: 'Assembly Line B' },
    { key: 'C', code: 'LINE-C', name: 'Press & Form Line C' },
    { key: 'D', code: 'LINE-D', name: 'Finish & Test Line D' },
  ];

  for (const line of lines) {
    const id = newId();
    ctx.lineIds[line.key] = id;
    await db.runAsync(
      'INSERT INTO production_lines (id, factory_id, code, name) VALUES (?, ?, ?, ?)',
      id,
      ctx.factoryId,
      line.code,
      line.name,
    );
  }
}
