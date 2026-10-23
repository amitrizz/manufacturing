import type { FinishedGoodsRow } from '../../types/database';
import { mongoApi } from '../client';

export async function listFinishedGoods(): Promise<FinishedGoodsRow[]> {
  try {
    const [goods, products] = await Promise.all([
      mongoApi.getCollection<any>('finished_goods'),
      mongoApi.getCollection<any>('products'),
    ]);

    const prodMap = new Map(products.map((p) => [p.id || p._id, p]));

    return goods.map((fg) => {
      const p = prodMap.get(fg.product_id);
      return {
        ...fg,
        id: fg.id || fg._id,
        product_code: p?.code || '',
        product_name: p?.name || '',
      };
    });
  } catch (err) {
    console.warn('MongoDB listFinishedGoods error:', err);
    return [];
  }
}

export async function getFinishedGoodsByProductId(
  productId: string,
): Promise<FinishedGoodsRow | null> {
  const all = await listFinishedGoods();
  return all.find((fg) => fg.product_id === productId) || null;
}
