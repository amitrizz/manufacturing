import { Ionicons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, spacing, typography } from '../../theme';
import { StatusBadge } from './StatusBadge';

type Props = {
  title: string;
  subtitle?: string;
  status?: string;
  rightMeta?: string;
  onPress?: () => void;
  showChevron?: boolean;
};

export function ListRow({
  title,
  subtitle,
  status,
  rightMeta,
  onPress,
  showChevron = true,
}: Props) {
  return (
    <Pressable
      style={({ pressed }) => [styles.container, pressed && styles.pressed]}
      onPress={onPress}
    >
      <View style={styles.textWrap}>
        <Text style={typography.bodySmall} numberOfLines={1}>
          {title}
        </Text>
        {subtitle ? (
          <Text style={typography.caption} numberOfLines={1}>
            {subtitle}
          </Text>
        ) : null}
      </View>
      <View style={styles.rightWrap}>
        {status ? <StatusBadge status={status} /> : null}
        {rightMeta ? <Text style={styles.rightMeta}>{rightMeta}</Text> : null}
        {showChevron && onPress ? (
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.surface,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: spacing.xs,
  },
  pressed: {
    backgroundColor: '#F1F5F9',
  },
  textWrap: {
    flex: 1,
    marginRight: spacing.sm,
  },
  rightWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  rightMeta: {
    ...typography.caption,
    fontWeight: '700',
    color: colors.primary,
  },
});
