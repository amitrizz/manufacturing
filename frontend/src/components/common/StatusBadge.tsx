import { StyleSheet, Text, View } from 'react-native';
import { colors, typography } from '../../theme';
import { formatStatusLabel } from '../../utils/format';

const STATUS_COLORS: Record<string, { bg: string; fg: string; border: string }> = {
  RUNNING: { bg: colors.successBg, fg: colors.success, border: '#A7F3D0' },
  IDLE: { bg: '#F1F5F9', fg: colors.machineIdle, border: '#E2E8F0' },
  BREAKDOWN: { bg: colors.dangerBg, fg: colors.danger, border: '#FECACA' },
  MAINTENANCE: { bg: colors.warningBg, fg: colors.warning, border: '#FDE68A' },
  OFFLINE: { bg: '#F1F5F9', fg: colors.machineOffline, border: '#E2E8F0' },
  IN_PROGRESS: { bg: colors.infoBg, fg: colors.info, border: '#BAE6FD' },
  COMPLETED: { bg: colors.successBg, fg: colors.success, border: '#A7F3D0' },
  PENDING: { bg: '#F8FAFC', fg: colors.textSecondary, border: '#E2E8F0' },
  OPEN: { bg: colors.warningBg, fg: colors.warning, border: '#FDE68A' },
  DELAYED: { bg: colors.dangerBg, fg: colors.danger, border: '#FECACA' },
  PASS: { bg: colors.successBg, fg: colors.success, border: '#A7F3D0' },
  FAIL: { bg: colors.dangerBg, fg: colors.danger, border: '#FECACA' },
  READY: { bg: colors.infoBg, fg: colors.info, border: '#BAE6FD' },
  DISPATCHED: { bg: colors.successBg, fg: colors.success, border: '#A7F3D0' },
  NEAR_MINIMUM: { bg: colors.warningBg, fg: colors.warning, border: '#FDE68A' },
  AVAILABLE: { bg: colors.successBg, fg: colors.success, border: '#A7F3D0' },
};

type Props = {
  status: string;
  compact?: boolean;
};

export function StatusBadge({ status, compact }: Props) {
  const palette = STATUS_COLORS[status] ?? {
    bg: '#F8FAFC',
    fg: colors.textSecondary,
    border: '#E2E8F0',
  };
  return (
    <View
      style={[
        styles.badge,
        { backgroundColor: palette.bg, borderColor: palette.border },
        compact && styles.compact,
      ]}
    >
      <View style={[styles.dot, { backgroundColor: palette.fg }]} />
      <Text style={[styles.text, { color: palette.fg }, compact && styles.textCompact]}>
        {formatStatusLabel(status)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 20,
    borderWidth: 1,
  },
  compact: {
    paddingHorizontal: 6,
    paddingVertical: 1.5,
    gap: 3.5,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  text: {
    ...typography.caption,
    fontWeight: '700',
    letterSpacing: 0.2,
  },
  textCompact: {
    fontSize: 9.5,
  },
});

