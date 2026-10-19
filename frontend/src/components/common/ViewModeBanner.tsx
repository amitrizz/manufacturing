import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Text, View } from 'react-native';
import { spacing } from '../../theme';

type Props = {
  title?: string;
  message?: string;
  showManagementLink?: boolean;
};

export function ViewModeBanner({
  message = 'For edit, open from Management',
}: Props) {
  // Streamline text to a clean single line
  const displayText =
    !message || message.length > 40
      ? 'For edit, open from Management'
      : message;

  return (
    <View style={styles.oneLineBar}>
      <View style={styles.badgePill}>
        <Ionicons name="eye-outline" size={12} color="#0369A1" />
        <Text style={styles.badgeText}>View Only</Text>
      </View>
      <Text style={styles.lineText} numberOfLines={1} ellipsizeMode="tail">
        {displayText}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  oneLineBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    paddingVertical: 6,
    paddingHorizontal: 10,
    marginBottom: spacing.xs,
    gap: 8,
  },
  badgePill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#7DD3FC',
    borderRadius: 5,
    paddingHorizontal: 6,
    paddingVertical: 2,
    flexShrink: 0,
  },
  badgeText: {
    fontSize: 10.5,
    fontWeight: '800',
    color: '#0369A1',
    letterSpacing: 0.2,
  },
  lineText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#0C4A6E',
    flex: 1,
    flexShrink: 1,
  },
});
