import type { FinishedGoodsRow } from '../../types/database';
import { getDatabase } from '../client';

export async function listFinishedGoods(): Promise<FinishedGoodsRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<FinishedGoodsRow>(
    `SELECT fg.*, p.code as product_code, p.name as product_name
     FROM finished_goods fg
     JOIN products p ON p.id = fg.product_id
     ORDER BY p.code`,
  );
}

export async function getFinishedGoodsByProductId(
  productId: string,
): Promise<FinishedGoodsRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<FinishedGoodsRow>(
    `SELECT fg.*, p.code as product_code, p.name as product_name
     FROM finished_goods fg JOIN products p ON p.id = fg.product_id WHERE fg.product_id = ?`,
    productId,
  );
}
