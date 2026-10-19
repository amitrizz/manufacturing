import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { useCallback, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { countUnreadNotifications } from '../../database/repositories/notificationRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors } from '../../theme';

import { useAuthStore } from '../../store/authStore';

type Props = {
  title?: string;
  showActions?: boolean;
};

export function AppHeader({ title = 'MY FACTORY', showActions = true }: Props) {
  const navigation = useNavigation<any>();
  const insets = useSafeAreaInsets();
  const [unreadCount, setUnreadCount] = useState(0);
  const company = useAuthStore((s) => s.company);
  const user = useAuthStore((s) => s.user);
  const previewRole = useAuthStore((s) => s.previewRole);
  const previewStaff = useAuthStore((s) => s.previewStaff);
  const exitPreview = useAuthStore((s) => s.exitPreview);

  const displayTitle = title === 'MY FACTORY' ? (company?.name || 'MY FACTORY') : title;
  const isPreviewing = Boolean(previewRole || previewStaff);
  const previewTitle = previewStaff
    ? `${previewStaff.name} (${previewStaff.role})`
    : previewRole
    ? previewRole.name
    : '';
  const previewTagLabel = previewStaff ? 'STAFF' : 'ROLE';

  const loadUnread = useCallback(async () => {
    try {
      const count = await countUnreadNotifications();
      setUnreadCount(count);
    } catch {
      // Ignore fallback
    }
  }, []);

  useLiveQuery(loadUnread);

  const handleOpenSearch = () => {
    try {
      navigation.navigate('GlobalSearch');
    } catch {
      navigation.navigate('Home', { screen: 'GlobalSearch' });
    }
  };

  const handleOpenNotifications = () => {
    try {
      navigation.navigate('Notifications');
    } catch {
      navigation.navigate('Home', { screen: 'Notifications' });
    }
  };

  return (
    <>
      <StatusBar style="light" />
      <View style={[styles.header, { paddingTop: Math.max(insets.top, 16) + 12 }]}>
        <View style={styles.topRow}>
          <View style={{ flex: 1, marginRight: 8 }}>
            <Text style={styles.brandTitle} numberOfLines={1}>{displayTitle}</Text>
            {user && (
              <View style={styles.userBadgeRow}>
                <Ionicons
                  name={
                    isPreviewing
                      ? 'eye'
                      : user.type === 'COMPANY_ADMIN'
                      ? 'shield-checkmark'
                      : 'person'
                  }
                  size={11}
                  color={isPreviewing ? '#FBBF24' : '#93C5FD'}
                />
                <Text style={styles.userBadgeText} numberOfLines={1}>
                  {isPreviewing
                    ? `Previewing: ${previewTitle}`
                    : `${user.name} (${user.role})`}
                </Text>
              </View>
            )}
          </View>
          {showActions && (
            <View style={styles.rightActions}>
              <Pressable style={styles.iconBtn} onPress={handleOpenSearch}>
                <Ionicons name="search-outline" size={19} color="#FFFFFF" />
              </Pressable>
              <Pressable style={styles.iconBtn} onPress={handleOpenNotifications}>
                <Ionicons name="notifications-outline" size={19} color="#FFFFFF" />
                {unreadCount > 0 && (
                  <View style={styles.badge}>
                    <Text style={styles.badgeText}>{unreadCount > 99 ? '99+' : unreadCount}</Text>
                  </View>
                )}
              </Pressable>
              <Pressable
                style={styles.avatarBtn}
                onPress={() => {
                  try {
                    navigation.navigate('Profile');
                  } catch {
                    navigation.navigate('Settings');
                  }
                }}
              >
                <Text style={styles.avatarText}>
                  {(user?.name || company?.name || 'A').charAt(0).toUpperCase()}
                </Text>
              </Pressable>
            </View>
          )}
        </View>

        {/* Role & Staff Preview Bar with Exit Button */}
        {isPreviewing && (
          <View style={styles.previewModeBar}>
            <View style={styles.previewModeLeft}>
              <View style={styles.previewTag}>
                <Ionicons name="eye" size={11} color="#92400E" />
                <Text style={styles.previewTagText}>{previewTagLabel}</Text>
              </View>
              <Text style={styles.previewRoleText} numberOfLines={1}>
                Viewing as: <Text style={styles.previewRoleBold}>{previewTitle}</Text>
              </Text>
            </View>
            <Pressable
              style={styles.exitPreviewBtn}
              onPress={() => {
                exitPreview();
              }}
            >
              <Ionicons name="close-circle" size={14} color="#FFFFFF" />
              <Text style={styles.exitPreviewText}>Exit</Text>
            </Pressable>
          </View>
        )}
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#0F172A',
    paddingHorizontal: 20,
    paddingBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.16,
    shadowRadius: 10,
    elevation: 6,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  brandTitle: {
    fontSize: 21,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.2,
  },
  userBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    marginTop: 3,
  },
  userBadgeText: {
    fontSize: 11,
    color: '#94A3B8',
    fontWeight: '600',
  },
  rightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  iconBtn: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.12)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 2,
    borderWidth: 1.5,
    borderColor: '#93C5FD',
  },
  avatarText: {
    color: '#1D4ED8',
    fontSize: 15,
    fontWeight: '800',
  },
  badge: {
    position: 'absolute',
    top: -3,
    right: -3,
    backgroundColor: colors.danger,
    borderRadius: 10,
    minWidth: 18,
    height: 18,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
    borderWidth: 2,
    borderColor: '#0F172A',
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 9.5,
    fontWeight: '800',
  },
  previewModeBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#0F2744',
    borderWidth: 1,
    borderColor: '#F59E0B',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginTop: 12,
  },
  previewModeLeft: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginRight: 8,
  },
  previewTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: '#FEF3C7',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  previewTagText: {
    fontSize: 9,
    fontWeight: '800',
    color: '#92400E',
    letterSpacing: 0.4,
  },
  previewRoleText: {
    fontSize: 12,
    color: '#E2E8F0',
    flex: 1,
  },
  previewRoleBold: {
    fontWeight: '800',
    color: '#FBBF24',
  },
  exitPreviewBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#DC2626',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  exitPreviewText: {
    fontSize: 12,
    fontWeight: '800',
    color: '#FFFFFF',
  },
});
