import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { getDatabaseStats } from '../../database/repositories/statsRepository';
import { APP_DISPLAY_NAME } from '../../constants/app';
import { colors, spacing, typography } from '../../theme';

type Props = {
  seeded: boolean;
};

export function BootstrapScreen({ seeded }: Props) {
  const [stats, setStats] = useState<Awaited<ReturnType<typeof getDatabaseStats>> | null>(
    null,
  );
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDatabaseStats()
      .then(setStats)
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : 'Failed to load database stats');
      });
  }, []);

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <Text style={typography.h1}>{APP_DISPLAY_NAME}</Text>
      <Text style={styles.subtitle}>Offline operations — local SQLite</Text>
      {error ? (
        <Text style={styles.error}>{error}</Text>
      ) : stats ? (
        <View style={styles.card}>
          <Text style={typography.h3}>Database ready</Text>
          {seeded ? (
            <Text style={styles.seedNote}>Demo data seeded on this launch.</Text>
          ) : (
            <Text style={styles.seedNote}>Using persisted demo data.</Text>
          )}
          <Text style={typography.bodySmall}>Factories: {stats.factories}</Text>
          <Text style={typography.bodySmall}>Machines: {stats.machines}</Text>
          <Text style={typography.bodySmall}>Materials: {stats.materials}</Text>
          <Text style={typography.bodySmall}>Production orders: {stats.productionOrders}</Text>
          <Text style={typography.bodySmall}>Activity events: {stats.activityRows}</Text>
        </View>
      ) : (
        <ActivityIndicator size="large" color={colors.primary} style={styles.loader} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: spacing.xl,
    justifyContent: 'center',
  },
  subtitle: {
    ...typography.bodySmall,
    marginTop: spacing.sm,
    marginBottom: spacing.xl,
  },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: spacing.lg,
    borderWidth: 1,
    borderColor: colors.border,
    gap: spacing.sm,
  },
  seedNote: {
    ...typography.body,
    color: colors.primary,
    marginBottom: spacing.sm,
  },
  loader: {
    marginTop: spacing.xl,
  },
  error: {
    ...typography.body,
    color: colors.danger,
  },
});
