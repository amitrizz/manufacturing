import { Ionicons } from '@expo/vector-icons';
import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { useAuthStore } from '../../store/authStore';
import { colors } from '../../theme';

type Tab = 'staff' | 'admin' | 'register';

export function LoginScreen() {
  const insets = useSafeAreaInsets();
  const [activeTab, setActiveTab] = useState<Tab>('staff');
  const [loading, setLoading] = useState(false);

  // Staff Login Fields
  const [staffCompanyCode, setStaffCompanyCode] = useState('APEX01');
  const [staffEmpId, setStaffEmpId] = useState('EMP-001');
  const [staffPin, setStaffPin] = useState('1234');

  // Company Admin Login Fields
  const [adminEmailOrCode, setAdminEmailOrCode] = useState('APEX01');
  const [adminPassword, setAdminPassword] = useState('admin123');

  // Register Company Fields
  const [regName, setRegName] = useState('');
  const [regCode, setRegCode] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPassword, setRegPassword] = useState('');

  const loginStaff = useAuthStore((s) => s.loginStaff);
  const loginCompanyAdmin = useAuthStore((s) => s.loginCompanyAdmin);
  const registerCompany = useAuthStore((s) => s.registerCompany);

  const handleStaffLogin = async () => {
    if (!staffCompanyCode.trim() || !staffEmpId.trim() || !staffPin.trim()) {
      Alert.alert('Required Fields', 'Please enter Company Code, Employee ID/Name, and PIN.');
      return;
    }
    setLoading(true);
    try {
      await loginStaff(staffCompanyCode, staffEmpId, staffPin);
    } catch (e: unknown) {
      Alert.alert('Login Failed', e instanceof Error ? e.message : 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  const handleAdminLogin = async () => {
    if (!adminEmailOrCode.trim() || !adminPassword.trim()) {
      Alert.alert('Required Fields', 'Please enter Company Code or Admin Email and Password.');
      return;
    }
    setLoading(true);
    try {
      await loginCompanyAdmin(adminEmailOrCode, adminPassword);
    } catch (e: unknown) {
      Alert.alert('Login Failed', e instanceof Error ? e.message : 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  const handleRegisterCompany = async () => {
    if (!regName.trim() || !regCode.trim() || !regEmail.trim() || !regPassword.trim()) {
      Alert.alert('Required Fields', 'Please complete all company registration fields.');
      return;
    }
    setLoading(true);
    try {
      await registerCompany({
        name: regName.trim(),
        company_code: regCode.trim(),
        admin_email: regEmail.trim(),
        admin_password: regPassword.trim(),
      });
      Alert.alert('Success', `Company "${regName}" registered and logged in!`);
    } catch (e: unknown) {
      Alert.alert('Registration Failed', e instanceof Error ? e.message : 'Could not register company');
    } finally {
      setLoading(false);
    }
  };

  const fillQuickStaff = (code: string, empId: string, pin: string) => {
    setActiveTab('staff');
    setStaffCompanyCode(code);
    setStaffEmpId(empId);
    setStaffPin(pin);
  };

  const fillQuickAdmin = (code: string, pass: string) => {
    setActiveTab('admin');
    setAdminEmailOrCode(code);
    setAdminPassword(pass);
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.keyboardContainer}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.container,
          { paddingTop: Math.max(insets.top, 20) + 16, paddingBottom: insets.bottom + 32 },
        ]}
        keyboardShouldPersistTaps="handled"
      >
        {/* Brand Header */}
        <View style={styles.header}>
          <View style={styles.brandIconWrap}>
            <Ionicons name="business" size={36} color="#FFFFFF" />
          </View>
          <Text style={styles.brandTitle}>MFG ENTERPRISE</Text>
          <Text style={styles.brandSubtitle}>Manufacturing Floor & Company Operations</Text>
        </View>

        {/* Mode Selector Tabs */}
        <View style={styles.tabContainer}>
          <Pressable
            style={[styles.tabBtn, activeTab === 'staff' && styles.tabBtnActive]}
            onPress={() => setActiveTab('staff')}
          >
            <Ionicons
              name="people-outline"
              size={16}
              color={activeTab === 'staff' ? '#FFFFFF' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'staff' && styles.tabTextActive]}>
              Staff Login
            </Text>
          </Pressable>

          <Pressable
            style={[styles.tabBtn, activeTab === 'admin' && styles.tabBtnActive]}
            onPress={() => setActiveTab('admin')}
          >
            <Ionicons
              name="shield-checkmark-outline"
              size={16}
              color={activeTab === 'admin' ? '#FFFFFF' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'admin' && styles.tabTextActive]}>
              Company Admin
            </Text>
          </Pressable>

          <Pressable
            style={[styles.tabBtn, activeTab === 'register' && styles.tabBtnActive]}
            onPress={() => setActiveTab('register')}
          >
            <Ionicons
              name="add-circle-outline"
              size={16}
              color={activeTab === 'register' ? '#FFFFFF' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'register' && styles.tabTextActive]}>
              New Company
            </Text>
          </Pressable>
        </View>

        {/* Card Forms */}
        <Card style={styles.formCard}>
          {activeTab === 'staff' && (
            <View>
              <View style={styles.formHeader}>
                <Text style={styles.formTitle}>Staff / Worker Portal</Text>
                <Text style={styles.formSub}>
                  Log in to your assigned company with your Employee ID and PIN.
                </Text>
              </View>

              <Text style={styles.inputLabel}>Company Code *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. APEX01"
                autoCapitalize="characters"
                value={staffCompanyCode}
                onChangeText={setStaffCompanyCode}
              />

              <Text style={styles.inputLabel}>Employee ID or Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. EMP-001 or Arun Kumar"
                value={staffEmpId}
                onChangeText={setStaffEmpId}
              />

              <Text style={styles.inputLabel}>Staff PIN *</Text>
              <TextInput
                style={styles.input}
                placeholder="4-digit PIN (default 1234)"
                keyboardType="numeric"
                secureTextEntry
                value={staffPin}
                onChangeText={setStaffPin}
              />

              <Button
                label={loading ? 'Verifying...' : 'Sign In as Staff'}
                style={styles.submitBtn}
                onPress={handleStaffLogin}
                disabled={loading}
              />
            </View>
          )}

          {activeTab === 'admin' && (
            <View>
              <View style={styles.formHeader}>
                <Text style={styles.formTitle}>Company Administrator</Text>
                <Text style={styles.formSub}>
                  Manage factory lines, staff rosters, orders, and company policies.
                </Text>
              </View>

              <Text style={styles.inputLabel}>Company Code or Admin Email *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. APEX01 or admin@apex.com"
                autoCapitalize="none"
                value={adminEmailOrCode}
                onChangeText={setAdminEmailOrCode}
              />

              <Text style={styles.inputLabel}>Admin Password *</Text>
              <TextInput
                style={styles.input}
                placeholder="Enter password"
                secureTextEntry
                value={adminPassword}
                onChangeText={setAdminPassword}
              />

              <Button
                label={loading ? 'Signing In...' : 'Sign In as Company Admin'}
                style={styles.submitBtn}
                onPress={handleAdminLogin}
                disabled={loading}
              />
            </View>
          )}

          {activeTab === 'register' && (
            <View>
              <View style={styles.formHeader}>
                <Text style={styles.formTitle}>Register Your Company</Text>
                <Text style={styles.formSub}>
                  Create a new manufacturing account. You can enroll staff under it anytime.
                </Text>
              </View>

              <Text style={styles.inputLabel}>Company Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Precision Tools Pvt Ltd"
                value={regName}
                onChangeText={setRegName}
              />

              <Text style={styles.inputLabel}>Unique Company Code *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. PREC01 (workers use this to sign in)"
                autoCapitalize="characters"
                value={regCode}
                onChangeText={setRegCode}
              />

              <Text style={styles.inputLabel}>Admin Email *</Text>
              <TextInput
                style={styles.input}
                placeholder="admin@precisiontools.com"
                keyboardType="email-address"
                autoCapitalize="none"
                value={regEmail}
                onChangeText={setRegEmail}
              />

              <Text style={styles.inputLabel}>Admin Password *</Text>
              <TextInput
                style={styles.input}
                placeholder="Create a strong password"
                secureTextEntry
                value={regPassword}
                onChangeText={setRegPassword}
              />

              <Button
                label={loading ? 'Registering...' : 'Register Company & Sign In'}
                style={styles.submitBtn}
                onPress={handleRegisterCompany}
                disabled={loading}
              />
            </View>
          )}

          {loading && <ActivityIndicator color={colors.primary} style={{ marginTop: 12 }} />}
        </Card>

        {/* Demo Fast Logins Section */}
        <View style={styles.demoSection}>
          <Text style={styles.demoTitle}>Quick Demo Logins (Instant Testing):</Text>
          <View style={styles.demoChipsRow}>
            <Pressable
              style={styles.demoChip}
              onPress={() => fillQuickStaff('APEX01', 'EMP-001', '1234')}
            >
              <Ionicons name="person" size={13} color="#0A1E38" />
              <Text style={styles.demoChipText}>Arun Kumar (Operator)</Text>
            </Pressable>

            <Pressable
              style={styles.demoChip}
              onPress={() => fillQuickStaff('APEX01', 'EMP-003', '1234')}
            >
              <Ionicons name="person" size={13} color="#0A1E38" />
              <Text style={styles.demoChipText}>Kavita Joshi (Supervisor)</Text>
            </Pressable>

            <Pressable
              style={styles.demoChip}
              onPress={() => fillQuickAdmin('APEX01', 'admin123')}
            >
              <Ionicons name="shield-checkmark" size={13} color="#0A1E38" />
              <Text style={styles.demoChipText}>Apex Company Admin</Text>
            </Pressable>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  keyboardContainer: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollView: {
    flex: 1,
  },
  container: {
    paddingHorizontal: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 20,
  },
  brandIconWrap: {
    width: 68,
    height: 68,
    borderRadius: 20,
    backgroundColor: '#0A1E38',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
  },
  brandTitle: {
    fontSize: 24,
    fontWeight: '900',
    color: '#0A1E38',
    letterSpacing: 1.5,
  },
  brandSubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 4,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#E2E8F0',
    borderRadius: 12,
    padding: 4,
    marginBottom: 16,
  },
  tabBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    paddingVertical: 10,
    borderRadius: 8,
  },
  tabBtnActive: {
    backgroundColor: '#0A1E38',
  },
  tabText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  tabTextActive: {
    color: '#FFFFFF',
  },
  formCard: {
    padding: 20,
    borderRadius: 16,
    backgroundColor: '#FFFFFF',
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
  },
  formHeader: {
    marginBottom: 16,
  },
  formTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.text,
  },
  formSub: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 3,
    lineHeight: 18,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginTop: 12,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 11,
    fontSize: 15,
    color: colors.text,
    backgroundColor: '#F8FAFC',
  },
  submitBtn: {
    marginTop: 20,
  },
  demoSection: {
    marginTop: 24,
    padding: 14,
    backgroundColor: '#F1F5F9',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  demoTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginBottom: 8,
  },
  demoChipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  demoChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#CBD5E1',
  },
  demoChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#0A1E38',
  },
});
