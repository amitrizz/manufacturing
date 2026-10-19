import { StyleSheet, Text, View } from 'react-native';
import { colors, spacing, typography } from '../../theme';

type Item = { label: string; value: number };

type Props = {
  items: Item[];
  maxValue?: number;
};

export function HorizontalBarChart({ items, maxValue }: Props) {
  const max = maxValue ?? Math.max(...items.map((i) => i.value), 1);
  return (
    <View style={styles.wrap}>
      {items.map((item) => (
        <View key={item.label} style={styles.row}>
          <Text style={styles.label}>{item.label}</Text>
          <View style={styles.barTrack}>
            <View
              style={[styles.barFill, { width: `${(item.value / max) * 100}%` }]}
            />
          </View>
          <Text style={styles.value}>{item.value.toFixed(0)}%</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { gap: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  label: { ...typography.caption, width: 56 },
  barTrack: {
    flex: 1,
    height: 10,
    backgroundColor: colors.border,
    borderRadius: 5,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 5,
  },
  value: { ...typography.caption, width: 36, textAlign: 'right' },
});
