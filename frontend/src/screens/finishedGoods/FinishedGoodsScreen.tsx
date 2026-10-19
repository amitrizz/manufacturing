import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { listFinishedGoods } from '../../database/repositories/finishedGoodsRepository';
import type { FinishedGoodsRow } from '../../types/database';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

export function FinishedGoodsScreen() {
  const [items, setItems] = useState<FinishedGoodsRow[]>([]);

  const load = useCallback(async () => {
    setItems(await listFinishedGoods());
  }, []);

  useLiveQuery(load);

  return (
    <FlatList
      style={styles.list}
      contentContainerStyle={styles.content}
      data={items}
      keyExtractor={(i) => i.id}
      onRefresh={load}
      refreshing={false}
      renderItem={({ item }) => (
        <View style={styles.card}>
          <Text style={typography.body}>{item.product_code}</Text>
          <Text style={typography.caption}>
            Available: {formatNumber(item.available_quantity)} (passed{' '}
            {formatNumber(item.quality_passed_quantity)})
          </Text>
        </View>
      )}
    />
  );
}

const styles = StyleSheet.create({
  list: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
});
