import { StyleSheet, Text, View } from 'react-native';
import { colors, spacing, typography } from '../../theme';

type Props = {
  title: string;
  subtitle?: string;
};

export function ScreenPlaceholder({ title, subtitle }: Props) {
  return (
    <View style={styles.container}>
      <Text style={typography.h2}>{title}</Text>
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
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
  },
});
