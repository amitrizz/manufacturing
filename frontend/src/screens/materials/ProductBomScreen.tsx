import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Button } from '../../components/common/Button';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Card } from '../../components/common/Card';
import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import { Screen } from '../../components/common/Screen';
import { SearchField } from '../../components/common/SearchField';
import { SectionHeader } from '../../components/common/SectionHeader';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import {
  getBomForProduct,
  listAllProductBoms,
  type ProductBomGroup,
} from '../../api/repositories/materialRepository';
import { listProducts } from '../../api/repositories/productRepository';
import type { BomItemRow, ProductRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<MoreStackParamList, 'ProductBom'>;

function BomTable({ items }: { items: BomItemRow[] }) {
  if (items.length === 0) {
    return <Text style={typography.bodySmall}>No materials on BOM.</Text>;
  }
  return (
    <View style={styles.table}>
      <View style={styles.tableHead}>
        <Text style={[styles.cellHead, styles.colMaterial]}>Material</Text>
        <Text style={[styles.cellHead, styles.colQty]}>Qty / unit</Text>
      </View>
      {items.map((item) => (
        <View key={item.material_id} style={styles.tableRow}>
          <View style={styles.colMaterial}>
            <Text style={typography.body}>{item.material_code}</Text>
            <Text style={typography.caption}>{item.material_name}</Text>
          </View>
          <Text style={[typography.body, styles.colQty]}>
            {formatNumber(item.quantity, 3)} {item.unit}
          </Text>
        </View>
      ))}
    </View>
  );
}


export function ProductBomScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [groups, setGroups] = useState<ProductBomGroup[]>([]);
  const [products, setProducts] = useState<ProductRow[]>([]);
  const [search, setSearch] = useState('');
  const [focusProductId, setFocusProductId] = useState(route.params.productId ?? '');

  const load = useCallback(async () => {
    const [allBoms, prods] = await Promise.all([listAllProductBoms(), listProducts()]);
    setGroups(allBoms);
    setProducts(prods);
    if (!focusProductId && prods[0]) {
      setFocusProductId(prods[0].id);
    }
  }, [focusProductId]);

  useLiveQuery(load);

  useEffect(() => {
    if (route.params.productId) {
      setFocusProductId(route.params.productId);
    }
  }, [route.params.productId]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return groups;
    return groups.filter(
      (g) =>
        g.product_code.toLowerCase().includes(q) ||
        g.product_name.toLowerCase().includes(q) ||
        g.items.some(
          (i: any) =>
            i.material_code.toLowerCase().includes(q) ||
            i.material_name.toLowerCase().includes(q),
        ),
    );
  }, [groups, search]);

  const [singleBom, setSingleBom] = useState<BomItemRow[]>([]);
  useEffect(() => {
    if (focusProductId) {
      getBomForProduct(focusProductId).then(setSingleBom);
    }
  }, [focusProductId]);

  const focusProduct = products.find((p) => p.id === focusProductId);

  return (
    <Screen>
      {isViewOnly && (
        <ViewModeBanner
          message="BOM Matrix viewing mode. Product and BOM creation are disabled. Use the Management tab to make changes."
        />
      )}
      {!isViewOnly && (
        <Button
          label="+ New product & BOM"
          variant="secondary"
          onPress={() => navigation.navigate('ProductCreate')}
        />
      )}
      <Text style={typography.h2}>Material per product</Text>
      <Text style={typography.caption}>
        Quantity shown is raw material needed to make <Text style={styles.strong}>1 unit</Text> of
        that product (from BOM). For an order: multiply by good + reject output.
      </Text>

      <SearchField
        value={search}
        onChangeText={setSearch}
        placeholder="Search product or material…"
      />

      <SectionHeader title="Quick pick product" />
      <View style={styles.chips}>
        {products.map((p) => (
          <Pressable
            key={p.id}
            style={[styles.chip, focusProductId === p.id && styles.chipActive]}
            onPress={() => setFocusProductId(p.id)}
          >
            <Text style={focusProductId === p.id ? styles.chipTextActive : undefined}>{p.code}</Text>
          </Pressable>
        ))}
      </View>

      {focusProduct ? (
        <Card style={styles.focusCard}>
          <Text style={typography.h3}>{focusProduct.code}</Text>
          <Text style={typography.bodySmall}>{focusProduct.name}</Text>
          <Button
            label="Edit product & materials"
            variant="secondary"
            onPress={() => navigation.navigate('ProductEdit', { productId: focusProduct.id })}
          />
          <BomTable items={singleBom} />
        </Card>
      ) : null}

      <SectionHeader title="All products" />
      {filtered.map((g) => (
        <Card key={g.product_id} style={styles.productCard}>
          <Text style={typography.body}>{g.product_code}</Text>
          <Text style={typography.caption}>{g.product_name}</Text>
          <BomTable items={g.items} />
        </Card>
      ))}
    </Screen>
  );
}

const styles = StyleSheet.create({
  strong: { fontWeight: '700' },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs, marginBottom: spacing.sm },
  chip: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipTextActive: { color: '#fff', fontWeight: '600' },
  focusCard: { borderLeftWidth: 4, borderLeftColor: colors.primary },
  productCard: { marginBottom: spacing.sm },
  table: { marginTop: spacing.sm, gap: spacing.xs },
  tableHead: { flexDirection: 'row', borderBottomWidth: 1, borderBottomColor: colors.border, paddingBottom: 4 },
  tableRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.xs,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border,
  },
  cellHead: { ...typography.caption, fontWeight: '700', color: colors.textMuted },
  colMaterial: { flex: 1 },
  colQty: { width: 110, textAlign: 'right' },
});
