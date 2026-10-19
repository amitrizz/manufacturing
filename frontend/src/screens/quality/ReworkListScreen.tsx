import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { Alert, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { completeReworkOrder, listReworkOrders } from '../../database/repositories/qualityRepository';
import type { ReworkOrderRow } from '../../types/database';
import { colors, spacing, typography } from '../../theme';

export function ReworkListScreen() {
  const [items, setItems] = useState<ReworkOrderRow[]>([]);

  const load = useCallback(async () => {
    setItems(await listReworkOrders());
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
          <Text style={typography.body}>{item.rework_number}</Text>
          <Text style={typography.caption}>{item.product_code} · {item.status}</Text>
          {item.status !== 'COMPLETED' ? (
            <Pressable
              onPress={async () => {
                await completeReworkOrder(item.id);
                load();
                Alert.alert('Done', 'Rework marked complete');
              }}
            >
              <Text style={styles.complete}>Complete</Text>
            </Pressable>
          ) : null}
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
  complete: { color: colors.primary, marginTop: spacing.xs, fontWeight: '600' },
});
