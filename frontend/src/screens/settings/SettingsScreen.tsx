import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { AppHeader } from '../../components/common/AppHeader';
import { Card } from '../../components/common/Card';
import { useAuthStore } from '../../store/authStore';
import { type SubscriptionState, useSubscriptionStore } from '../../store/subscriptionStore';
import { useThemeStore } from '../../store/themeStore';
import { useTranslation } from '../../store/languageStore';

export function SettingsScreen() {
  const navigation = useNavigation<any>();
  const company = useAuthStore((s) => s.company);
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);
  const { status, daysRemaining, renewSubscription, simulateStatus } =
    useSubscriptionStore();

  const isDark = useThemeStore((s) => s.isDark);
  const themeMode = useThemeStore((s) => s.themeMode);
  const setThemeMode = useThemeStore((s) => s.setThemeMode);
  const themeColors = useThemeStore((s) => s.colors);

  const { language, setLanguage, t } = useTranslation();

  const [showSimModal, setShowSimModal] = useState(false);

  const getSubStatusText = () => {
    if (status === 'PAID') return t('activePro');
    if (status === 'TRIAL') return t('freeTrial');
    if (status === 'GRACE') return t('gracePeriod');
    return t('expired');
  };

  return (
    <View style={[styles.screen, { backgroundColor: themeColors.background }]}>
      <AppHeader />
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.contentContainer}
      >
        {/* 1. Company Profile Card */}
        <Pressable
          style={[
            styles.companyCard,
            { backgroundColor: themeColors.surface, borderColor: themeColors.border },
          ]}
          onPress={() => {
            Alert.alert(
              t('company'),
              `${t('company')}: ${company?.name || 'Apex Manufacturing Ltd'}\n${t('companyCode')}: ${company?.company_code || 'APEX01'}\n${t('administrator')}: ${user?.name || 'Admin'} (${user?.role || 'ADMIN'})`,
            );
          }}
        >
          <View style={styles.companyIconBox}>
            <Ionicons name="business" size={26} color="#FFFFFF" />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.companyName, { color: themeColors.text }]}>
              {company?.name || 'Apex Manufacturing Ltd'}
            </Text>
            <Text style={[styles.companyCode, { color: themeColors.textSecondary }]}>
              {t('companyCode')}: <Text style={{ fontWeight: '700' }}>{company?.company_code || 'APEX01'}</Text>
            </Text>
            <View style={styles.userRoleRow}>
              <Ionicons name="person" size={12} color="#2563EB" />
              <Text style={styles.userRoleText} numberOfLines={1}>
                {user?.name || 'Admin'} ({user?.role || 'ADMIN'})
              </Text>
            </View>
          </View>
          <Ionicons name="chevron-forward" size={18} color="#94A3B8" />
        </Pressable>

        {/* 2. Subscription Status Card */}
        <Card style={[styles.subCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
          <View style={styles.subTopRow}>
            <View style={styles.subIconContainer}>
              <Ionicons name="ribbon" size={22} color="#10B981" />
            </View>

            <View style={{ flex: 1, marginLeft: 12 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Text style={[styles.subTitle, { color: themeColors.text }]}>{t('activeSubscription')}</Text>
                <View style={styles.subBadge}>
                  <Text style={styles.subBadgeText}>{getSubStatusText()}</Text>
                </View>
              </View>
              <Text style={[styles.subSubtitle, { color: themeColors.textSecondary }]}>
                {status === 'TRIAL'
                  ? `${t('trialSubtitle')} (${daysRemaining} ${t('daysLeft')})`
                  : status === 'GRACE'
                  ? `⚠️ ${t('gracePeriod')} (${daysRemaining} ${t('daysLeft')})`
                  : status === 'PAID'
                  ? t('activePro')
                  : t('expired')}
              </Text>
            </View>

            <Pressable
              style={styles.renewButton}
              onPress={async () => {
                await renewSubscription();
                Alert.alert('Subscription Activated', 'Full editing and entry access restored.');
              }}
            >
              <Text style={styles.renewButtonText}>{t('renew')}</Text>
            </Pressable>
          </View>

          {/* Progress bar */}
          <View style={[styles.subProgressBarBg, { backgroundColor: isDark ? '#334155' : '#E2E8F0' }]}>
            <View
              style={[
                styles.subProgressBarFill,
                { width: `${Math.min(100, Math.max(10, (daysRemaining / 14) * 100))}%` },
              ]}
            />
          </View>

          <View style={styles.subFooterRow}>
            <Text style={[styles.subFooterText, { color: themeColors.textSecondary }]}>
              {daysRemaining} {t('daysLeft')}
            </Text>
            <Text style={[styles.subFooterText, { color: themeColors.textSecondary }]}>
              {t('validTill')} 31 Oct 2026
            </Text>
          </View>
        </Card>

        {/* 3. Four Quick Action / Stats Cards in a row */}
        <View style={styles.quickGridRow}>
          {/* Users */}
          <Pressable
            style={[
              styles.quickGridCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
            ]}
            onPress={() => navigation.navigate('Staff', { viewOnly: true })}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
              <Ionicons name="people" size={17} color="#2563EB" />
            </View>
            <Text style={[styles.quickGridLabel, { color: themeColors.textSecondary }]}>{t('users')}</Text>
            <Text style={[styles.quickGridVal, { color: themeColors.text }]}>6 {t('activeUsers')}</Text>
            <Ionicons
              name="chevron-forward"
              size={12}
              color="#94A3B8"
              style={styles.quickGridChevron}
            />
          </Pressable>

          {/* Company */}
          <Pressable
            style={[
              styles.quickGridCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
            ]}
            onPress={() => {
              Alert.alert(t('company'), `${t('companyCode')}: ${company?.company_code || 'APEX01'}`);
            }}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: isDark ? '#4C1D95' : '#F5F3FF' }]}>
              <Ionicons name="business" size={17} color="#7C3AED" />
            </View>
            <Text style={[styles.quickGridLabel, { color: themeColors.textSecondary }]}>{t('company')}</Text>
            <Text style={[styles.quickGridVal, { color: themeColors.text }]}>{company?.company_code || 'APEX01'}</Text>
            <Ionicons
              name="chevron-forward"
              size={12}
              color="#94A3B8"
              style={styles.quickGridChevron}
            />
          </Pressable>

          {/* Plan Details */}
          <Pressable
            style={[
              styles.quickGridCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
            ]}
            onPress={() => setShowSimModal(true)}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: isDark ? '#064E3B' : '#ECFDF5' }]}>
              <Ionicons name="document-text" size={17} color="#059669" />
            </View>
            <Text style={[styles.quickGridLabel, { color: themeColors.textSecondary }]}>{t('planDetails')}</Text>
            <Text style={[styles.quickGridVal, { color: themeColors.text }]}>{t('freeTrial')}</Text>
            <Ionicons
              name="chevron-forward"
              size={12}
              color="#94A3B8"
              style={styles.quickGridChevron}
            />
          </Pressable>

          {/* Billing */}
          <Pressable
            style={[
              styles.quickGridCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
            ]}
            onPress={() => {
              Alert.alert(t('billing'), 'Your billing is on Free Trial tier. No invoices due.');
            }}
          >
            <View style={[styles.quickIconCircle, { backgroundColor: isDark ? '#78350F' : '#FFFBEB' }]}>
              <Ionicons name="card" size={17} color="#D97706" />
            </View>
            <Text style={[styles.quickGridLabel, { color: themeColors.textSecondary }]}>{t('billing')}</Text>
            <Text style={[styles.quickGridVal, { color: themeColors.text }]}>{t('viewManage')}</Text>
            <Ionicons
              name="chevron-forward"
              size={12}
              color="#94A3B8"
              style={styles.quickGridChevron}
            />
          </Pressable>
        </View>

        {/* 4. App Preferences Section */}
        <Text style={[styles.sectionTitle, { color: themeColors.text }]}>{t('appPreferences')}</Text>
        <Card style={[styles.menuGroupCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
          {/* Language */}
          <View style={[styles.menuRow, { borderBottomColor: isDark ? '#334155' : '#F1F5F9' }]}>
            <View style={[styles.menuIconCircle, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
              <Ionicons name="globe" size={18} color="#2563EB" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.menuLabel, { color: themeColors.text }]}>{t('language')}</Text>
              <Text style={[styles.menuSubLabel, { color: themeColors.textSecondary }]}>{t('chooseLanguage')}</Text>
            </View>
            <View style={[styles.toggleSegment, { backgroundColor: isDark ? '#0F172A' : '#F1F5F9' }]}>
              <Pressable
                style={[styles.toggleBtn, language === 'EN' && styles.toggleBtnActive]}
                onPress={() => setLanguage('EN')}
              >
                <Text style={[styles.toggleBtnText, language === 'EN' && styles.toggleBtnTextActive]}>
                  EN
                </Text>
              </Pressable>
              <Pressable
                style={[styles.toggleBtn, language === 'HI' && styles.toggleBtnActive]}
                onPress={() => setLanguage('HI')}
              >
                <Text style={[styles.toggleBtnText, language === 'HI' && styles.toggleBtnTextActive]}>
                  हिंदी
                </Text>
              </Pressable>
            </View>
          </View>

          {/* Notifications */}
          <Pressable
            style={[styles.menuRow, { borderBottomColor: isDark ? '#334155' : '#F1F5F9' }]}
            onPress={() => navigation.navigate('Notifications')}
          >
            <View style={[styles.menuIconCircle, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
              <Ionicons name="notifications" size={18} color="#2563EB" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.menuLabel, { color: themeColors.text }]}>{t('notifications')}</Text>
              <Text style={[styles.menuSubLabel, { color: themeColors.textSecondary }]}>{t('manageAlerts')}</Text>
            </View>
            <Ionicons name="chevron-forward" size={16} color="#94A3B8" />
          </Pressable>

          {/* Theme */}
          <View style={[styles.menuRow, { borderBottomWidth: 0 }]}>
            <View style={[styles.menuIconCircle, { backgroundColor: isDark ? '#78350F' : '#FFFBEB' }]}>
              <Ionicons name="color-palette" size={18} color="#D97706" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.menuLabel, { color: themeColors.text }]}>{t('theme')}</Text>
              <Text style={[styles.menuSubLabel, { color: themeColors.textSecondary }]}>{t('chooseTheme')}</Text>
            </View>
            <View style={[styles.toggleSegment, { backgroundColor: isDark ? '#0F172A' : '#F1F5F9' }]}>
              {(['Light', 'Dark', 'System'] as const).map((mode) => (
                <Pressable
                  key={mode}
                  style={[styles.toggleBtn, themeMode === mode && styles.toggleBtnActive]}
                  onPress={() => setThemeMode(mode)}
                >
                  <Text style={[styles.toggleBtnText, themeMode === mode && styles.toggleBtnTextActive]}>
                    {mode === 'Light' ? t('themeLight') : mode === 'Dark' ? t('themeDark') : t('themeSystem')}
                  </Text>
                </Pressable>
              ))}
            </View>
          </View>
        </Card>

        {/* 5. Tools & System Section */}
        <Text style={[styles.sectionTitle, { color: themeColors.text }]}>{t('toolsSystem')}</Text>
        <Card style={[styles.menuGroupCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
          {/* How Platform Works - Visual Flow */}
          <Pressable
            style={[styles.menuRow, { borderBottomColor: isDark ? '#334155' : '#F1F5F9' }]}
            onPress={() => navigation.navigate('PlatformWorkflow')}
          >
            <View style={[styles.menuIconCircle, { backgroundColor: isDark ? '#0369A1' : '#EFF6FF' }]}>
              <Ionicons name="git-network-outline" size={18} color="#0284C7" />
            </View>
            <View style={{ flex: 1 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Text style={[styles.menuLabel, { color: isDark ? '#38BDF8' : '#0369A1' }]}>
                  {t('howPlatformWorks')}
                </Text>
              </View>
              <Text style={[styles.menuSubLabel, { color: themeColors.textSecondary }]}>
                {t('viewArchitecture')}
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={16} color="#0284C7" />
          </Pressable>


          {/* Security */}
          <Pressable
            style={[styles.menuRow, { borderBottomWidth: 0 }]}
            onPress={() => navigation.navigate('RolesList', { viewOnly: true })}
          >
            <View style={[styles.menuIconCircle, { backgroundColor: isDark ? '#4C1D95' : '#EDE9FE' }]}>
              <Ionicons name="shield-checkmark-outline" size={18} color="#6D28D9" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.menuLabel, { color: themeColors.text }]}>{t('accountSecurity')}</Text>
              <Text style={[styles.menuSubLabel, { color: themeColors.textSecondary }]}>{t('accessRoles')}</Text>
            </View>
            <Ionicons name="chevron-forward" size={16} color="#94A3B8" />
          </Pressable>
        </Card>

        {/* 6. Logout Card */}
        <Pressable
          style={[
            styles.logoutCard,
            { backgroundColor: themeColors.surface, borderColor: themeColors.border },
          ]}
          onPress={() => {
            Alert.alert(
              t('logOut'),
              `Are you sure you want to log out from ${company?.name || 'this company'}?`,
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: t('logOut'),
                  style: 'destructive',
                  onPress: () => logout(),
                },
              ],
            );
          }}
        >
          <View style={[styles.logoutIconBox, { backgroundColor: isDark ? '#7F1D1D' : '#FEE2E2' }]}>
            <Ionicons name="log-out-outline" size={20} color="#DC2626" />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.logoutTitle, { color: '#EF4444' }]}>{t('logOut')}</Text>
            <Text style={[styles.logoutSub, { color: themeColors.textSecondary }]}>{t('signOut')}</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color="#DC2626" />
        </Pressable>
      </ScrollView>



      {/* Subscription Simulator Modal */}
      <Modal
        visible={showSimModal}
        animationType="slide"
        transparent
        onRequestClose={() => setShowSimModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            <View style={styles.modalHeader}>
              <Text style={[styles.modalHeaderTitle, { color: themeColors.text }]}>{t('simulateSubStatus')}</Text>
              <Pressable
                onPress={() => setShowSimModal(false)}
                style={[styles.modalCloseBtn, { backgroundColor: isDark ? '#1E293B' : '#F1F5F9' }]}
              >
                <Ionicons name="close" size={20} color={themeColors.textSecondary} />
              </Pressable>
            </View>

            <View style={{ flexDirection: 'row', gap: 8, marginTop: 14 }}>
              {(['TRIAL', 'GRACE', 'EXPIRED', 'PAID'] as SubscriptionState[]).map((st) => (
                <Pressable
                  key={st}
                  style={[
                    styles.simChip,
                    { backgroundColor: isDark ? '#1E293B' : '#F1F5F9' },
                    status === st && styles.simChipActive,
                  ]}
                  onPress={() => {
                    simulateStatus(st);
                    setShowSimModal(false);
                  }}
                >
                  <Text
                    style={[
                      styles.simChipText,
                      { color: themeColors.textSecondary },
                      status === st && styles.simChipTextActive,
                    ]}
                  >
                    {st}
                  </Text>
                </Pressable>
              ))}
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#F8FAFC' },
  container: { flex: 1 },
  contentContainer: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 40 },

  /* Company Card */
  companyCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 14,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 1.5,
  },
  companyIconBox: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: '#2563EB',
    justifyContent: 'center',
    alignItems: 'center',
  },
  companyName: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: -0.2,
  },
  companyCode: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  userRoleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  userRoleText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#2563EB',
  },

  /* Subscription Card */
  subCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 14,
    marginBottom: 14,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 1.5,
  },
  subTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  subIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: '#ECFDF5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  subTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
  },
  subBadge: {
    backgroundColor: '#ECFDF5',
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 6,
  },
  subBadgeText: {
    fontSize: 9.5,
    fontWeight: '800',
    color: '#10B981',
  },
  subSubtitle: {
    fontSize: 11.5,
    color: '#64748B',
    marginTop: 2,
  },
  renewButton: {
    borderWidth: 1.5,
    borderColor: '#2563EB',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 6,
    backgroundColor: '#FFFFFF',
  },
  renewButtonText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#2563EB',
  },
  subProgressBarBg: {
    height: 5,
    backgroundColor: '#E2E8F0',
    borderRadius: 3,
    marginVertical: 12,
    overflow: 'hidden',
  },
  subProgressBarFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 3,
  },
  subFooterRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  subFooterText: {
    fontSize: 11,
    color: '#64748B',
    fontWeight: '500',
  },

  /* 4 Quick Grid */
  quickGridRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 18,
  },
  quickGridCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 12,
    paddingHorizontal: 8,
    alignItems: 'flex-start',
    position: 'relative',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 2,
    elevation: 1,
  },
  quickIconCircle: {
    width: 30,
    height: 30,
    borderRadius: 15,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 6,
  },
  quickGridLabel: {
    fontSize: 10,
    color: '#64748B',
    fontWeight: '600',
  },
  quickGridVal: {
    fontSize: 11.5,
    fontWeight: '800',
    color: '#0F172A',
    marginTop: 2,
  },
  quickGridChevron: {
    position: 'absolute',
    top: 10,
    right: 8,
  },

  /* Sections & Menu Cards */
  sectionTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 8,
    marginLeft: 2,
  },
  menuGroupCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
    marginBottom: 18,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  menuRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    gap: 12,
  },
  menuIconCircle: {
    width: 34,
    height: 34,
    borderRadius: 17,
    justifyContent: 'center',
    alignItems: 'center',
  },
  menuLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
  },
  menuSubLabel: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 1,
  },
  visualFlowBadge: {
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 6,
    paddingVertical: 1.5,
    borderRadius: 6,
  },
  visualFlowBadgeText: {
    fontSize: 9.5,
    fontWeight: '800',
    color: '#0284C7',
  },
  versionBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#64748B',
  },

  /* Segmented Toggle */
  toggleSegment: {
    flexDirection: 'row',
    backgroundColor: '#F1F5F9',
    borderRadius: 8,
    padding: 2,
    gap: 2,
  },
  toggleBtn: {
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 6,
  },
  toggleBtnActive: {
    backgroundColor: '#2563EB',
  },
  toggleBtnText: {
    fontSize: 10.5,
    fontWeight: '700',
    color: '#64748B',
  },
  toggleBtnTextActive: {
    color: '#FFFFFF',
  },

  /* Logout Card */
  logoutCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FECACA',
    borderRadius: 14,
    padding: 14,
    gap: 12,
    marginTop: 4,
  },
  logoutIconBox: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FEE2E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  logoutTitle: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#DC2626',
  },
  logoutSub: {
    fontSize: 11,
    color: '#991B1B',
    marginTop: 1,
  },

  /* Modals */
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 36,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  modalHeaderTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
  },
  modalCloseBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalSubText: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 6,
    lineHeight: 16,
  },
  dataModalActionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 12,
    padding: 12,
    gap: 10,
  },
  dataModalActionTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
  },
  dataModalActionSub: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 1,
  },
  modalDismissBtn: {
    backgroundColor: '#2563EB',
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 16,
  },
  modalDismissBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 13,
  },
  simChip: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
  },
  simChipActive: {
    backgroundColor: '#2563EB',
  },
  simChipText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#475569',
  },
  simChipTextActive: {
    color: '#FFFFFF',
  },
});
