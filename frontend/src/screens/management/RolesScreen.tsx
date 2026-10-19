import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useCallback, useState } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import {
  createRole,
  deleteRole,
  ensureCompanyRolesSeeded,
  listRolesByCompany,
  updateRole,
} from '../../database/repositories/roleRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { useAuthStore } from '../../store/authStore';
import { colors, spacing, typography } from '../../theme';
import {
  AVAILABLE_PERMISSIONS,
  type CompanyRoleRow,
  type PermissionCategory,
} from '../../types/permissions';

export function RolesScreen() {
  const navigation = useNavigation<any>();
  const company = useAuthStore((s) => s.company);
  const startRolePreview = useAuthStore((s) => s.startRolePreview);
  const previewRole = useAuthStore((s) => s.previewRole);
  const exitRolePreview = useAuthStore((s) => s.exitRolePreview);
  const [roles, setRoles] = useState<CompanyRoleRow[]>([]);
  const [loading, setLoading] = useState(false);

  // Modal State
  const [modalVisible, setModalVisible] = useState(false);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingRoleId, setEditingRoleId] = useState<string | null>(null);
  const [roleName, setRoleName] = useState('');
  const [roleDesc, setRoleDesc] = useState('');
  const [selectedPermissions, setSelectedPermissions] = useState<string[]>([]);

  const load = useCallback(async () => {
    if (!company?.id) return;
    setLoading(true);
    try {
      await ensureCompanyRolesSeeded(company.id);
      const list = await listRolesByCompany(company.id);
      setRoles(list);
    } finally {
      setLoading(false);
    }
  }, [company?.id]);

  useLiveQuery(load);

  const handleOpenCreate = () => {
    setModalMode('create');
    setEditingRoleId(null);
    setRoleName('');
    setRoleDesc('');
    setSelectedPermissions([
      'home_production',
      'home_machines',
      'tasks_production',
    ]);
    setModalVisible(true);
  };

  const handleOpenEdit = (role: CompanyRoleRow) => {
    setModalMode('edit');
    setEditingRoleId(role.id);
    setRoleName(role.name);
    setRoleDesc(role.description || '');
    setSelectedPermissions([...role.permissions]);
    setModalVisible(true);
  };

  const togglePermission = (key: string) => {
    if (selectedPermissions.includes(key)) {
      setSelectedPermissions(selectedPermissions.filter((k) => k !== key));
    } else {
      setSelectedPermissions([...selectedPermissions, key]);
    }
  };

  const selectCategoryAll = (category: PermissionCategory) => {
    const catKeys = AVAILABLE_PERMISSIONS.filter((p) => p.category === category).map(
      (p) => p.key,
    );
    const merged = Array.from(new Set([...selectedPermissions, ...catKeys]));
    setSelectedPermissions(merged);
  };

  const clearCategoryAll = (category: PermissionCategory) => {
    const catKeys = AVAILABLE_PERMISSIONS.filter((p) => p.category === category).map(
      (p) => p.key,
    );
    setSelectedPermissions(selectedPermissions.filter((k) => !catKeys.includes(k)));
  };

  const handleSave = async () => {
    if (!company?.id) return;
    if (!roleName.trim()) {
      Alert.alert('Required Field', 'Please enter a role name.');
      return;
    }
    if (selectedPermissions.length === 0) {
      Alert.alert(
        'Permissions Required',
        'Please select at least one permission for this role.',
      );
      return;
    }

    try {
      if (modalMode === 'edit' && editingRoleId) {
        await updateRole({
          id: editingRoleId,
          name: roleName.trim().toUpperCase(),
          description: roleDesc.trim() || undefined,
          permissions: selectedPermissions,
        });
        Alert.alert('Success', `Role "${roleName.trim()}" updated successfully.`);
      } else {
        await createRole({
          company_id: company.id,
          name: roleName.trim().toUpperCase(),
          description: roleDesc.trim() || undefined,
          permissions: selectedPermissions,
        });
        Alert.alert('Success', `Role "${roleName.trim()}" created successfully.`);
      }
      setModalVisible(false);
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed to save role');
    }
  };

  const handleDelete = (role: CompanyRoleRow) => {
    Alert.alert(
      'Delete Role',
      `Are you sure you want to delete "${role.name}"? This action cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteRole(role.id);
              await load();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Failed to delete role');
            }
          },
        },
      ],
    );
  };

  const handleViewAsRole = (roleItem: { id: string; name: string; permissions: string[] }) => {
    startRolePreview({
      id: roleItem.id,
      name: roleItem.name,
      permissions: roleItem.permissions,
    });
    setModalVisible(false);
    Alert.alert(
      `Viewing as "${roleItem.name}"`,
      `You are now viewing the mobile interface as "${roleItem.name}".\n\n• Home tab: Modules filtered for this role\n• My Tasks tab: Activities filtered for this role\n• Management tab: Features restricted based on role\n\nTap "Exit" in the top header anytime to return to Owner view.`,
      [
        {
          text: 'Open Home Screen',
          onPress: () => {
            try {
              navigation.navigate('Main', {
                screen: 'Home',
                params: { screen: 'Dashboard' },
              });
            } catch {
              navigation.navigate('Home');
            }
          },
        },
        {
          text: 'Stay on Roles',
          style: 'cancel',
        },
      ],
    );
  };

  const renderPermissionCategory = (
    category: PermissionCategory,
    title: string,
    icon: keyof typeof Ionicons.glyphMap,
  ) => {
    const items = AVAILABLE_PERMISSIONS.filter((p) => p.category === category);
    return (
      <View style={styles.permCategoryBox}>
        <View style={styles.permCategoryHeader}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name={icon} size={16} color="#0A1E38" />
            <Text style={styles.permCategoryTitle}>{title}</Text>
          </View>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <Pressable onPress={() => selectCategoryAll(category)}>
              <Text style={styles.catActionText}>Select All</Text>
            </Pressable>
            <Text style={{ color: colors.textMuted }}>·</Text>
            <Pressable onPress={() => clearCategoryAll(category)}>
              <Text style={styles.catActionText}>Clear</Text>
            </Pressable>
          </View>
        </View>

        {items.map((perm) => {
          const checked = selectedPermissions.includes(perm.key);
          return (
            <Pressable
              key={perm.key}
              style={[styles.permRow, checked && styles.permRowChecked]}
              onPress={() => togglePermission(perm.key)}
            >
              <Ionicons
                name={checked ? 'checkbox' : 'square-outline'}
                size={18}
                color={checked ? colors.primary : colors.textMuted}
              />
              <View style={{ flex: 1 }}>
                <Text style={[styles.permLabel, checked && styles.permLabelChecked]}>
                  {perm.label}
                </Text>
                <Text style={styles.permDesc}>{perm.description}</Text>
              </View>
            </Pressable>
          );
        })}
      </View>
    );
  };

  return (
    <Screen scroll={false}>
      {/* Active Role Preview Banner */}
      {previewRole && (
        <View style={styles.activePreviewBanner}>
          <View style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 8 }}>
            <Ionicons name="eye" size={16} color="#D97706" />
            <Text style={styles.activePreviewText} numberOfLines={1}>
              Previewing as: <Text style={styles.activePreviewBold}>{previewRole.name}</Text>
            </Text>
          </View>
          <Pressable style={styles.activeExitBtn} onPress={exitRolePreview}>
            <Ionicons name="close-circle" size={13} color="#FFFFFF" />
            <Text style={styles.activeExitText}>Exit</Text>
          </Pressable>
        </View>
      )}

      <View style={styles.topBar}>
        <View style={{ flex: 1 }}>
          <Text style={typography.h2}>Roles & Access Control</Text>
          <Text style={styles.topSub}>
            Define custom roles and assign module & task permissions for staff.
          </Text>
        </View>
        <Button label="+ New Role" onPress={handleOpenCreate} />
      </View>

      <FlatList
        data={roles}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={load} />}
        contentContainerStyle={{ paddingBottom: 32 }}
        renderItem={({ item }) => {
          const homePerms = item.permissions.filter((p) => p.startsWith('home_')).length;
          const taskPerms = item.permissions.filter((p) => p.startsWith('tasks_')).length;
          const mgmtPerms = item.permissions.filter((p) => p.startsWith('mgmt_')).length;

          return (
            <Card style={styles.roleCard}>
              <View style={styles.roleHeader}>
                <View style={{ flex: 1 }}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                    <Text style={styles.roleTitle}>{item.name}</Text>
                    {item.is_system === 1 ? (
                      <View style={styles.systemBadge}>
                        <Text style={styles.systemBadgeText}>SYSTEM</Text>
                      </View>
                    ) : (
                      <View style={styles.customBadge}>
                        <Text style={styles.customBadgeText}>CUSTOM</Text>
                      </View>
                    )}
                  </View>
                  {item.description ? (
                    <Text style={styles.roleDesc}>{item.description}</Text>
                  ) : null}
                </View>

                <View style={{ flexDirection: 'row', gap: 6 }}>
                  <Pressable style={styles.cardActionBtn} onPress={() => handleOpenEdit(item)}>
                    <Ionicons name="create-outline" size={16} color="#0A1E38" />
                    <Text style={styles.cardActionText}>Edit</Text>
                  </Pressable>
                  {item.is_system === 0 && (
                    <Pressable
                      style={[styles.cardActionBtn, { borderColor: '#FCA5A5' }]}
                      onPress={() => handleDelete(item)}
                    >
                      <Ionicons name="trash-outline" size={16} color={colors.danger} />
                    </Pressable>
                  )}
                </View>
              </View>

              {/* Permissions Summary Badges */}
              <View style={styles.permSummaryRow}>
                <View style={styles.summaryChip}>
                  <Ionicons name="construct-outline" size={12} color="#0284C7" />
                  <Text style={styles.summaryChipText}>{homePerms} Ops</Text>
                </View>
                <View style={styles.summaryChip}>
                  <Ionicons name="checkbox-outline" size={12} color="#15803D" />
                  <Text style={styles.summaryChipText}>{taskPerms} Tasks</Text>
                </View>
                <View style={styles.summaryChip}>
                  <Ionicons name="briefcase-outline" size={12} color="#7C3AED" />
                  <Text style={styles.summaryChipText}>{mgmtPerms} Mgmt</Text>
                </View>
                <Text style={styles.totalPermsText}>
                  Total: {item.permissions.length} permissions
                </Text>
              </View>

              {/* Sample Tag Pills */}
              <View style={styles.tagsRow}>
                {item.permissions.slice(0, 5).map((pKey) => {
                  const perm = AVAILABLE_PERMISSIONS.find((p) => p.key === pKey);
                  return (
                    <View key={pKey} style={styles.permTag}>
                      <Text style={styles.permTagText}>{perm?.label || pKey}</Text>
                    </View>
                  );
                })}
                {item.permissions.length > 5 && (
                  <View style={[styles.permTag, { backgroundColor: '#F1F5F9' }]}>
                    <Text style={[styles.permTagText, { color: colors.textSecondary }]}>
                      +{item.permissions.length - 5} more
                    </Text>
                  </View>
                )}
              </View>

              {/* View As This Role Button */}
              <View style={styles.cardFooterRow}>
                <Pressable
                  style={styles.viewAsCardBtn}
                  onPress={() => handleViewAsRole(item)}
                >
                  <Ionicons name="eye-outline" size={15} color="#0284C7" />
                  <Text style={styles.viewAsCardBtnText}>View as this role</Text>
                </Pressable>
              </View>
            </Card>
          );
        }}
      />

      {/* Role Configuration Modal */}
      <Modal visible={modalVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View>
                <Text style={typography.h2}>
                  {modalMode === 'create' ? 'Create Custom Role' : `Edit Role: ${roleName}`}
                </Text>
                <Text style={styles.modalSub}>
                  Select what this role can see in Home, My Tasks, and Management.
                </Text>
              </View>
              <Pressable onPress={() => setModalVisible(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView style={{ maxHeight: 500 }} keyboardShouldPersistTaps="handled">
              <Text style={styles.inputLabel}>Role Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. CNC OPERATOR or STORE KEEPER"
                autoCapitalize="characters"
                value={roleName}
                onChangeText={setRoleName}
              />

              <Text style={styles.inputLabel}>Role Description (Optional)</Text>
              <TextInput
                style={styles.input}
                placeholder="Brief summary of duties and permissions"
                value={roleDesc}
                onChangeText={setRoleDesc}
              />

              {/* 1. Operations & Floor Access */}
              {renderPermissionCategory(
                'home',
                '1. Operations & Floor Modules (Orders, Production, Machines, Stock)',
                'construct-outline',
              )}

              {/* 2. My Tasks Activities */}
              {renderPermissionCategory(
                'tasks',
                '2. My Tasks Activities (Work queue & actions user can perform)',
                'checkbox-outline',
              )}

              {/* 3. Management Tab Modules */}
              {renderPermissionCategory(
                'management',
                '3. Management Tab Modules (Administrative functions)',
                'briefcase-outline',
              )}
            </ScrollView>

            <View style={styles.modalActions}>
              <Pressable
                style={styles.modalViewAsBtn}
                onPress={() => {
                  handleViewAsRole({
                    id: editingRoleId || 'preview-temp',
                    name: roleName.trim() || 'Custom Role',
                    permissions: selectedPermissions,
                  });
                }}
              >
                <Ionicons name="eye-outline" size={15} color="#0369A1" />
                <Text style={styles.modalViewAsBtnText}>View as this role</Text>
              </Pressable>
              <View style={{ flex: 1 }} />
              <Button label="Cancel" variant="secondary" onPress={() => setModalVisible(false)} />
              <Button
                label={modalMode === 'create' ? 'Create Role' : 'Save Permissions'}
                onPress={handleSave}
              />
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
    gap: 8,
  },
  topSub: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  roleCard: {
    marginBottom: spacing.md,
    padding: spacing.md,
  },
  roleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  roleTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.text,
  },
  roleDesc: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 3,
  },
  systemBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: '#E0F2FE',
  },
  systemBadgeText: {
    fontSize: 9,
    fontWeight: '800',
    color: '#0369A1',
  },
  customBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: '#DCFCE7',
  },
  customBadgeText: {
    fontSize: 9,
    fontWeight: '800',
    color: '#15803D',
  },
  cardActionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#CBD5E1',
  },
  cardActionText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0A1E38',
  },
  permSummaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 10,
  },
  summaryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 6,
  },
  summaryChipText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.text,
  },
  totalPermsText: {
    fontSize: 11,
    color: colors.textMuted,
    marginLeft: 4,
  },
  tagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 8,
  },
  permTag: {
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 4,
  },
  permTagText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#1D4ED8',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: spacing.lg,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.md,
  },
  modalSub: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginTop: 10,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
    fontSize: 14,
    color: colors.text,
    backgroundColor: colors.background,
  },
  permCategoryBox: {
    marginTop: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
  },
  permCategoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  permCategoryTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: '#0A1E38',
  },
  catActionText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0284C7',
  },
  permRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  permRowChecked: {
    backgroundColor: '#F0F9FF',
  },
  permLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
  },
  permLabelChecked: {
    color: '#0369A1',
  },
  permDesc: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 1,
  },
  modalActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  activePreviewBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FEF3C7',
    borderWidth: 1,
    borderColor: '#FCD34D',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: spacing.md,
  },
  activePreviewText: {
    fontSize: 12,
    color: '#92400E',
    flex: 1,
  },
  activePreviewBold: {
    fontWeight: '800',
    color: '#78350F',
  },
  activeExitBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#DC2626',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  activeExitText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  cardFooterRow: {
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  viewAsCardBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  viewAsCardBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0369A1',
  },
  modalViewAsBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
  },
  modalViewAsBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0369A1',
  },
});
