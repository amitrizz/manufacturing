import { StyleSheet, View } from 'react-native';
import { colors } from '../../theme';

type Props = {
  progress: number;
  color?: string;
};

export function ProgressBar({ progress, color = colors.primary }: Props) {
  const pct = Math.min(100, Math.max(0, progress));
  return (
    <View style={styles.track}>
      <View style={[styles.fill, { width: `${pct}%`, backgroundColor: color }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  track: {
    height: 7,
    backgroundColor: '#E2E8F0',
    borderRadius: 6,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    borderRadius: 6,
  },
});
