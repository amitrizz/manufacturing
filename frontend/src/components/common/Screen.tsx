import { ScrollView, StyleSheet, View, type ScrollViewProps } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { spacing } from '../../theme';
import { useThemeStore } from '../../store/themeStore';

type Props = ScrollViewProps & {
  scroll?: boolean;
  padded?: boolean;
};

export function Screen({
  children,
  scroll = true,
  padded = true,
  contentContainerStyle,
  style,
  ...rest
}: Props) {
  const insets = useSafeAreaInsets();
  const themeColors = useThemeStore((s) => s.colors);
  const pad = padded ? spacing.lg : 0;

  if (!scroll) {
    return (
      <View
        style={[
          styles.root,
          { backgroundColor: themeColors.background, paddingTop: pad, paddingHorizontal: pad },
          style,
        ]}
      >
        {children}
      </View>
    );
  }

  return (
    <ScrollView
      style={[styles.root, { backgroundColor: themeColors.background }, style]}
      contentContainerStyle={[
        {
          paddingTop: pad,
          paddingBottom: insets.bottom + spacing.xxl,
          paddingHorizontal: pad,
          gap: spacing.md,
        },
        contentContainerStyle,
      ]}
      showsVerticalScrollIndicator={false}
      {...rest}
    >
      {children}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
});
