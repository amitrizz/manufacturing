import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { FlatList, Pressable, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { SearchField } from '../../components/common/SearchField';
import { StatusBadge } from '../../components/common/StatusBadge';
import { listMaterials } from '../../api/repositories/materialRepository';
import type { MaterialRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { inventoryLevel } from '../../utils/calculations';
import { formatNumber } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<MoreStackParamList, 'Materials'>;

type StockFilter = 'all' | 'low';

const colorForLevel = (level: ReturnType<typeof inventoryLevel>) => {
  if (level === 'SHORTAGE') return colors.materialShortage;
  if (level === 'NEAR_MINIMUM') return colors.materialNearMinimum;
  return colors.materialAvailable;
};

export function MaterialsScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [materials, setMaterials] = useState<MaterialRow[]>([]);
  const [search, setSearch] = useState('');
  const [stockFilter, setStockFilter] = useState<StockFilter>('all');
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    setRefreshing(true);
    try {
      setMaterials(
        await listMaterials({
          search: search || undefined,
          lowStockOnly: stockFilter === 'low',
        }),
      );
    } finally {
      setRefreshing(false);
    }
  }, [search, stockFilter]);

  useLiveQuery(load);

  return (
    <View style={styles.container}>
      {isViewOnly && (
        <ViewModeBanner
          message="Materials inventory viewing mode. Stock receipts and adjustments are disabled. Use the Management tab to make changes."
        />
      )}
      <Pressable onPress={() => navigation.navigate('ProductBom', { viewOnly: isViewOnly })}>
        <Text style={styles.bomLink}>Material qty per product (BOM) →</Text>
      </Pressable>
      <SearchField value={search} onChangeText={setSearch} placeholder="Search materials…" />
      <View style={styles.filters}>
        {(['all', 'low'] as StockFilter[]).map((f) => (
          <Pressable
            key={f}
            style={[styles.chip, stockFilter === f && styles.chipActive]}
            onPress={() => setStockFilter(f)}
          >
            <Text style={stockFilter === f ? styles.chipTextActive : styles.chipText}>
              {f === 'all' ? 'All materials' : 'Low stock'}
            </Text>
          </Pressable>
        ))}
      </View>
      <FlatList
        data={materials}
        keyExtractor={(m) => m.id}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={load} tintColor={colors.primary} />
        }
        renderItem={({ item }) => {
          const level = inventoryLevel(item.current_stock, item.minimum_stock);
          return (
            <Pressable
              style={styles.card}
              onPress={() =>
                navigation.navigate('MaterialDetail', {
                  materialId: item.id,
                  viewOnly: isViewOnly,
                })
              }
            >
              <View style={styles.cardTop}>
                <Text style={typography.body}>{item.code}</Text>
                <StatusBadge status={level} compact />
              </View>
              <Text style={typography.caption}>{item.name}</Text>
              <Text style={[typography.caption, { color: colorForLevel(level) }]}>
                Stock {formatNumber(item.current_stock, 1)} {item.unit} (min{' '}
                {formatNumber(item.minimum_stock, 1)})
              </Text>
              <Text style={styles.handleHint}>
                {isViewOnly ? 'Tap to view material specifications' : 'Tap to receive, issue, or adjust'}
              </Text>
            </Pressable>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, padding: spacing.lg, gap: spacing.sm },
  bomLink: { color: colors.primary, fontWeight: '600' },
  filters: { flexDirection: 'row', gap: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: 6,
    borderRadius: 12,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { ...typography.caption, fontWeight: '600' },
  chipTextActive: { ...typography.caption, fontWeight: '600', color: '#fff' },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    marginTop: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  handleHint: { ...typography.caption, color: colors.primary, marginTop: spacing.xs },
});
