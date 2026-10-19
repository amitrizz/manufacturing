import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Button } from '../../components/common/Button';
import { APP_DISPLAY_NAME } from '../../constants/app';
import { colors, spacing, typography } from '../../theme';
import { shadows } from '../../theme/shadows';

type Props = {
  onExplore: () => void;
};

export function FirstLaunchScreen({ onExplore }: Props) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top + spacing.xl }]}>
      <View style={styles.iconWrap}>
        <Ionicons name="business" size={48} color={colors.primary} />
      </View>
      <Text style={typography.h1}>{APP_DISPLAY_NAME}</Text>
      <Text style={styles.lead}>
        Production, quality, maintenance, and dispatch — fully offline on this device with local
        SQLite data.
      </Text>
      <View style={styles.features}>
        {['Real-time floor KPIs', 'Material & quality tracking', 'No cloud required'].map((f) => (
          <View key={f} style={styles.featureRow}>
            <Ionicons name="checkmark-circle" size={20} color={colors.success} />
            <Text style={typography.body}>{f}</Text>
          </View>
        ))}
      </View>
      <Button label="Explore Dashboard" onPress={onExplore} style={styles.cta} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    paddingHorizontal: spacing.xl,
    paddingBottom: spacing.xxl,
  },
  iconWrap: {
    width: 88,
    height: 88,
    borderRadius: 24,
    backgroundColor: colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.lg,
    ...shadows.elevated,
  },
  lead: {
    ...typography.body,
    color: colors.textSecondary,
    marginTop: spacing.md,
    lineHeight: 24,
  },
  features: { marginTop: spacing.xl, gap: spacing.md },
  featureRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  cta: { marginTop: 'auto' },
});
