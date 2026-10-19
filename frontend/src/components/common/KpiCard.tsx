import { StyleSheet, Text, View } from 'react-native';
import { colors, spacing, typography } from '../../theme';
import { shadows } from '../../theme/shadows';

type Props = {
  label: string;
  value: string;
  hint?: string;
  accent?: string;
  icon?: string;
};

export function KpiCard({ label, value, hint, accent }: Props) {
  return (
    <View style={styles.card}>
      <Text style={styles.label}>{label.toUpperCase()}</Text>
      <Text style={[styles.value, accent ? { color: accent } : null]}>{value}</Text>
      {hint ? <Text style={typography.caption}>{hint}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    minWidth: '46%',
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: spacing.lg,
    borderWidth: 1,
    borderColor: colors.border,
    ...shadows.card,
  },
  label: {
    ...typography.caption,
    fontWeight: '700',
    color: colors.textMuted,
    letterSpacing: 0.6,
  },
  value: {
    ...typography.h2,
    marginVertical: spacing.xs,
    color: colors.text,
  },
});
