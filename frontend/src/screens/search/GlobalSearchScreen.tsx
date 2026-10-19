import { useState } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { SearchField } from '../../components/common/SearchField';
import { searchMachines } from '../../database/repositories/machineRepository';
import { searchMaterials } from '../../database/repositories/materialRepository';
import { searchProductionOrders } from '../../database/repositories/productionOrderRepository';
import { searchProducts } from '../../database/repositories/productRepository';
import { searchInspectionsByBatch } from '../../database/repositories/qualityRepository';
import { searchDispatchOrders } from '../../database/repositories/dispatchRepository';
import { colors, spacing, typography } from '../../theme';

type Result = { type: string; label: string; sub?: string };

export function GlobalSearchScreen() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Result[]>([]);

  const search = async (q: string) => {
    if (!q.trim()) {
      setResults([]);
      return;
    }
    const [products, materials, machines, orders, batches, dispatch] = await Promise.all([
      searchProducts(q),
      searchMaterials(q),
      searchMachines(q),
      searchProductionOrders(q),
      searchInspectionsByBatch(q),
      searchDispatchOrders(q),
    ]);
    const merged: Result[] = [
      ...products.map((p) => ({ type: 'Product', label: p.code, sub: p.name })),
      ...materials.map((m) => ({ type: 'Material', label: m.code, sub: m.name })),
      ...machines.map((m) => ({ type: 'Machine', label: m.code, sub: m.name })),
      ...orders.map((o) => ({ type: 'Order', label: o.order_number, sub: o.product_code })),
      ...batches.map((b) => ({ type: 'Batch', label: b.batch_number, sub: b.overall_result })),
      ...dispatch.map((d) => ({ type: 'Dispatch', label: d.dispatch_number, sub: d.customer_name })),
    ];
    setResults(merged);
  };

  return (
    <View style={styles.container}>
      <SearchField value={query} onChangeText={(t) => { setQuery(t); search(t); }} />
      <FlatList
        data={results}
        keyExtractor={(r, i) => `${r.type}-${r.label}-${i}`}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={typography.caption}>{item.type}</Text>
            <Text style={typography.body}>{item.label}</Text>
            {item.sub ? <Text style={typography.caption}>{item.sub}</Text> : null}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, padding: spacing.lg, gap: spacing.sm },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    marginTop: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
});
