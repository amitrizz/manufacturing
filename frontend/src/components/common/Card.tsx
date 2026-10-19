import { StyleSheet, View, type ViewProps } from 'react-native';
import { spacing } from '../../theme';
import { shadows } from '../../theme/shadows';
import { useThemeStore } from '../../store/themeStore';

type Props = ViewProps & {
  padded?: boolean;
  variant?: 'default' | 'flat' | 'elevated';
};

export function Card({ style, padded = true, variant = 'default', children, ...rest }: Props) {
  const themeColors = useThemeStore((s) => s.colors);
  const isDark = useThemeStore((s) => s.isDark);

  return (
    <View
      style={[
        styles.card,
        {
          backgroundColor: themeColors.surface,
          borderColor: isDark ? themeColors.border : colors_border_fallback(variant),
        },
        variant === 'elevated' && shadows.elevated,
        variant === 'flat' && styles.flat,
        padded && styles.padded,
        style,
      ]}
      {...rest}
    >
      {children}
    </View>
  );
}

function colors_border_fallback(variant: 'default' | 'flat' | 'elevated') {
  return variant === 'flat' ? '#EDF2F7' : '#E2E8F0';
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 16,
    borderWidth: 1,
    ...shadows.card,
  },
  flat: {
    elevation: 0,
    shadowOpacity: 0,
  },
  padded: {
    padding: spacing.md + 2,
  },
});

