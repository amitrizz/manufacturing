import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { Alert, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { dispatchOrder, listDispatchOrders } from '../../database/repositories/dispatchRepository';
import type { DispatchOrderRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<MoreStackParamList, 'Dispatch'>;

export function DispatchScreen({ navigation }: Props) {
  const [orders, setOrders] = useState<DispatchOrderRow[]>([]);

  const load = useCallback(async () => {
    setOrders(await listDispatchOrders());
  }, []);

  useLiveQuery(load);

  return (
    <View style={styles.container}>
      <Pressable style={styles.link} onPress={() => navigation.navigate('DispatchCreate')}>
        <Text style={styles.linkText}>+ New dispatch</Text>
      </Pressable>
      <FlatList
        data={orders}
        keyExtractor={(o) => o.id}
        onRefresh={load}
        refreshing={false}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={typography.body}>{item.dispatch_number}</Text>
            <Text style={typography.caption}>
              {item.customer_name} · {item.status} · qty {item.quantity}
            </Text>
            {item.status === 'READY' ? (
              <Pressable
                onPress={async () => {
                  try {
                    await dispatchOrder(item.id);
                    load();
                  } catch (e: unknown) {
                    Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
                  }
                }}
              >
                <Text style={styles.dispatch}>Dispatch now</Text>
              </Pressable>
            ) : null}
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, padding: spacing.lg },
  link: { marginBottom: spacing.sm },
  linkText: { color: colors.primary, fontWeight: '600' },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  dispatch: { color: colors.primary, marginTop: spacing.xs, fontWeight: '600' },
});
