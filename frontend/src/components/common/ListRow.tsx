import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography } from '../../theme';
import { shadows } from '../../theme/shadows';
import { StatusBadge } from './StatusBadge';

type Props = {
  title: string;
  subtitle?: string;
  status?: string;
  onPress?: () => void;
  rightMeta?: string;
};

export function ListRow({ title, subtitle, status, onPress, rightMeta }: Props) {
  return (
    <Pressable
      style={({ pressed }) => [styles.row, pressed && onPress && styles.pressed]}
      onPress={onPress}
      disabled={!onPress}
    >
      <View style={styles.body}>
        <View style={styles.titleRow}>
          <Text style={typography.body} numberOfLines={1}>{title}</Text>
          {status ? <StatusBadge status={status} compact /> : null}
        </View>
        {subtitle ? <Text style={typography.bodySmall} numberOfLines={2}>{subtitle}</Text> : null}
      </View>
      {rightMeta ? <Text style={styles.meta}>{rightMeta}</Text> : null}
      {onPress ? <Ionicons name="chevron-forward" size={18} color={colors.textMuted} /> : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 14,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
    gap: spacing.sm,
    ...shadows.card,
  },
  pressed: { opacity: 0.92 },
  body: { flex: 1, gap: 4 },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.sm,
  },
  meta: { ...typography.caption, color: colors.textMuted },
});
