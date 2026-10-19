import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';
import { useCallback, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { AppHeader } from '../../components/common/AppHeader';
import {
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '../../database/repositories/notificationRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { navigateToActivityReference } from '../../navigation/navigateToReference';
import { colors, spacing, typography } from '../../theme';
import type { NotificationRow } from '../../types/database';

const severityColor = (s: string) => {
  if (s === 'CRITICAL') return colors.danger;
  if (s === 'WARNING') return colors.warning;
  return colors.info;
};

export function NotificationsScreen() {
  const navigation = useNavigation<NavigationProp<ParamListBase>>();
  const [items, setItems] = useState<NotificationRow[]>([]);

  const load = useCallback(async () => {
    setItems(await listNotifications());
  }, []);

  useLiveQuery(load);

  return (
    <View style={styles.screen}>
      <AppHeader />
      <View style={styles.container}>
        <View style={styles.topBar}>
          <Text style={typography.h2}>Alerts</Text>
          {items.length > 0 && (
            <Pressable onPress={async () => { await markAllNotificationsRead(); load(); }}>
              <Text style={styles.markAll}>Mark all read</Text>
            </Pressable>
          )}
        </View>
        <FlatList
          data={items}
          keyExtractor={(n) => n.id}
          onRefresh={load}
          refreshing={false}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="notifications-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>No Alerts</Text>
              <Text style={styles.emptySubtitle}>All notifications have been resolved or read.</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Pressable
              style={[styles.card, item.is_read ? null : styles.unread]}
              onPress={async () => {
                await markNotificationRead(item.id);
                navigateToActivityReference(
                  navigation,
                  item.reference_type,
                  item.reference_id,
                );
                load();
              }}
            >
              <Text style={[typography.body, { color: severityColor(item.severity) }]}>
                {item.title}
              </Text>
              <Text style={typography.caption}>{item.body}</Text>
            </Pressable>
          )}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  container: { flex: 1, padding: spacing.lg },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  markAll: { color: colors.primary, fontWeight: '700', fontSize: 13 },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  unread: { borderColor: colors.primary, borderWidth: 1.5 },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
    gap: 8,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
    marginTop: 8,
  },
  emptySubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    textAlign: 'center',
  },
});
