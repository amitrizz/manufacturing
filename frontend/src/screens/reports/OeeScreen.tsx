import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { getReportData } from '../../database/repositories/reportsRepository';
import type { OeeRow } from '../../database/repositories/reportsRepository';
import { colors, spacing, typography } from '../../theme';
import { formatPct } from '../../utils/format';

export function OeeScreen() {
  const [rows, setRows] = useState<OeeRow[]>([]);

  useEffect(() => {
    getReportData('oee_summary', 0, Date.now()).then((r) => setRows(r as OeeRow[]));
  }, []);

  return (
    <FlatList
      style={styles.list}
      contentContainerStyle={styles.content}
      ListHeaderComponent={
        <Text style={typography.caption}>
          Performance uses each machine&apos;s historical best output/hour as ideal baseline.
        </Text>
      }
      data={rows}
      keyExtractor={(r) => r.machine_code}
      renderItem={({ item }) => (
        <View style={styles.card}>
          <Text style={typography.body}>{item.machine_code}</Text>
          <Text style={typography.caption}>
            A {formatPct(item.availability)} · P {formatPct(item.performance)} · Q{' '}
            {formatPct(item.quality)} · OEE {formatPct(item.oee)}
          </Text>
        </View>
      )}
    />
  );
}

const styles = StyleSheet.create({
  list: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, gap: spacing.sm },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.sm,
  },
});
