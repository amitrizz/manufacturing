import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { DatePreset } from '../../utils/dateRange';
import { colors } from '../../theme';

const PRESETS: { key: DatePreset; label: string }[] = [
  { key: 'today', label: 'Today' },
  { key: 'week', label: 'Week' },
  { key: 'month', label: 'Month' },
];

type Props = {
  value: DatePreset;
  onChange: (preset: DatePreset) => void;
};

export function DatePresetChips({ value, onChange }: Props) {
  return (
    <View style={styles.row}>
      {PRESETS.map((p) => (
        <Pressable
          key={p.key}
          style={[styles.chip, value === p.key && styles.chipActive]}
          onPress={() => onChange(p.key)}
        >
          <Text style={[styles.chipText, value === p.key && styles.chipTextActive]}>
            {p.label}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' },
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    backgroundColor: '#FFFFFF',
  },
  chipActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.18,
    shadowRadius: 3,
    elevation: 2,
  },
  chipText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  chipTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
});
