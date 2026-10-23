import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { Alert, StyleSheet, Text, TextInput } from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { StatusBadge } from '../../components/common/StatusBadge';
import { getBomForProduct, getMaterialById } from '../../api/repositories/materialRepository';
import { listProducts } from '../../api/repositories/productRepository';
import {
  adjustMaterialStock,
  issueMaterialStock,
  MaterialStockError,
  receiveMaterialStock,
  updateMaterialMinimumStock,
} from '../../services/materialService';
import type { BomItemRow, MaterialRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { inventoryLevel } from '../../utils/calculations';
import { formatNumber } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<MoreStackParamList, 'MaterialDetail'>;

export function MaterialDetailScreen({ route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [material, setMaterial] = useState<MaterialRow | null>(null);
  const [bomUsage, setBomUsage] = useState<{ product: string; item: BomItemRow }[]>([]);
  const [qty, setQty] = useState('');
  const [notes, setNotes] = useState('');
  const [minStock, setMinStock] = useState('');

  const load = useCallback(async () => {
    const m = await getMaterialById(route.params.materialId);
    setMaterial(m);
    if (m) setMinStock(String(m.minimum_stock));

    const products = await listProducts();
    const hits: { product: string; item: BomItemRow }[] = [];
    for (const p of products) {
      const bom = await getBomForProduct(p.id);
      const found = bom.find((b) => b.material_id === route.params.materialId);
      if (found) hits.push({ product: p.code, item: found });
    }
    setBomUsage(hits);
  }, [route.params.materialId]);

  useLiveQuery(load);

  const parseQty = () => {
    const n = Number(qty.replace(',', '.'));
    if (!Number.isFinite(n) || n <= 0) {
      throw new MaterialStockError('Enter a positive quantity');
    }
    return n;
  };

  const run = async (action: () => Promise<void>, success: string) => {
    try {
      await action();
      setQty('');
      setNotes('');
      await load();
      Alert.alert('Saved', success);
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  if (!material) return null;

  const level = inventoryLevel(material.current_stock, material.minimum_stock);

  return (
    <Screen scroll>
      {isViewOnly && (
        <ViewModeBanner
          message="Material detail viewing mode. Stock receipts, issues, adjustments, and reorder levels cannot be modified from Home. Use the Management tab to make changes."
        />
      )}
      <Text style={typography.h2}>{material.name}</Text>
      <Text style={typography.bodySmall}>{material.code} · {material.category}</Text>
      <StatusBadge status={level} />

      <Card>
        <Text style={typography.label}>On hand</Text>
        <Text style={typography.h3}>
          {formatNumber(material.current_stock, 2)} {material.unit}
        </Text>
        <Text style={typography.caption}>
          Min {formatNumber(material.minimum_stock, 1)} · Max {formatNumber(material.maximum_stock, 1)}{' '}
          {material.unit}
        </Text>
      </Card>

      {!isViewOnly && (
        <>
          <SectionHeader title="Stock movement" />
          <TextInput
            style={styles.input}
            placeholder="Quantity"
            keyboardType="decimal-pad"
            value={qty}
            onChangeText={setQty}
          />
          <TextInput
            style={styles.input}
            placeholder="Notes (optional)"
            value={notes}
            onChangeText={setNotes}
          />
          <Button
            label="Receive stock"
            onPress={() =>
              run(() => receiveMaterialStock(material.id, parseQty(), notes), 'Stock received')
            }
          />
          <Button
            label="Issue stock"
            variant="secondary"
            onPress={() =>
              run(() => issueMaterialStock(material.id, parseQty(), notes), 'Stock issued')
            }
          />
          <Button
            label="Record adjustment (+/− qty)"
            variant="ghost"
            onPress={() => {
              const n = Number(qty.replace(',', '.'));
              if (!Number.isFinite(n) || n === 0) {
                Alert.alert('Error', 'Enter a positive or negative quantity for adjustment');
                return;
              }
              run(() => adjustMaterialStock(material.id, n, notes), 'Stock adjusted');
            }}
          />

          <SectionHeader title="Reorder level" />
          <TextInput
            style={styles.input}
            placeholder="Minimum stock"
            keyboardType="decimal-pad"
            value={minStock}
            onChangeText={setMinStock}
          />
          <Button
            label="Update minimum"
            variant="secondary"
            onPress={() => {
              const n = Number(minStock.replace(',', '.'));
              run(
                () => updateMaterialMinimumStock(material.id, n),
                'Minimum stock updated',
              );
            }}
          />
        </>
      )}

      <SectionHeader title="Used in BOM" />
      {bomUsage.length === 0 ? (
        <Text style={typography.bodySmall}>Not on any active BOM.</Text>
      ) : (
        bomUsage.map((b) => (
          <Text key={b.product} style={typography.bodySmall}>
            {b.product}: {b.item.quantity} {b.item.unit}
          </Text>
        ))
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: spacing.md,
    backgroundColor: colors.surface,
    marginBottom: spacing.sm,
  },
});
