import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import {
  deleteProductionPlan,
  getProductionPlanById,
  updateProductionPlan,
} from '../../database/repositories/productionPlanRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import type { PlanStatus, Priority, ProductionPlanRow } from '../../types/database';
import { formatDate, formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionPlanDetail'>;

const STATUSES: PlanStatus[] = ['PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
const PRIORITIES: Priority[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

export function ProductionPlanDetailScreen({ navigation, route }: Props) {
  const [plan, setPlan] = useState<ProductionPlanRow | null>(null);

  // Edit Modal State
  const [showEditModal, setShowEditModal] = useState(false);
  const [editTargetQty, setEditTargetQty] = useState('');
  const [editPriority, setEditPriority] = useState<Priority>('MEDIUM');
  const [editStatus, setEditStatus] = useState<PlanStatus>('PLANNED');
  const [editNotes, setEditNotes] = useState('');

  const load = useCallback(() => {
    getProductionPlanById(route.params.planId).then(setPlan);
  }, [route.params.planId]);

  useLiveQuery(load);

  const handleOpenEdit = () => {
    if (!plan) return;
    setEditTargetQty(plan.target_quantity.toString());
    setEditPriority(plan.priority);
    setEditStatus(plan.status);
    setEditNotes(plan.notes || '');
    setShowEditModal(true);
  };

  const handleSaveEdit = async () => {
    const qty = parseFloat(editTargetQty);
    if (isNaN(qty) || qty <= 0) {
      Alert.alert('Invalid Target', 'Please enter a valid target quantity greater than 0.');
      return;
    }
    try {
      await updateProductionPlan(route.params.planId, {
        target_quantity: qty,
        priority: editPriority,
        status: editStatus,
        notes: editNotes.trim() || null,
      });
      setShowEditModal(false);
      Alert.alert('Success', 'Production plan updated.');
      load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not update plan');
    }
  };

  const handleDelete = () => {
    if (!plan) return;
    Alert.alert(
      'Delete Production Plan',
      `Are you sure you want to delete production plan ${plan.plan_number}? Linked production orders will be unlinked.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Plan',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteProductionPlan(plan.id);
              Alert.alert('Deleted', `Production plan ${plan.plan_number} deleted.`);
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert('Cannot Delete', e instanceof Error ? e.message : 'Could not delete plan');
            }
          },
        },
      ],
    );
  };

  if (!plan) return null;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <View style={{ flex: 1 }}>
          <Text style={typography.h2}>{plan.plan_number}</Text>
          <Text style={styles.subtitle}>
            {plan.product_code} • {plan.product_name}
          </Text>
        </View>
        <View
          style={[
            styles.badge,
            {
              backgroundColor:
                plan.status === 'COMPLETED'
                  ? '#DCFCE7'
                  : plan.status === 'IN_PROGRESS'
                  ? '#E0F2FE'
                  : plan.status === 'CANCELLED'
                  ? '#FEE2E2'
                  : '#FEF3C7',
            },
          ]}
        >
          <Text
            style={[
              styles.badgeText,
              {
                color:
                  plan.status === 'COMPLETED'
                    ? '#16A34A'
                    : plan.status === 'IN_PROGRESS'
                    ? '#0284C7'
                    : plan.status === 'CANCELLED'
                    ? '#DC2626'
                    : '#D97706',
              },
            ]}
          >
            {plan.status}
          </Text>
        </View>
      </View>

      <Card style={styles.infoCard}>
        <View style={styles.infoGrid}>
          <View style={styles.infoCol}>
            <Text style={styles.infoLabel}>Target Quantity</Text>
            <Text style={styles.infoValue}>{formatNumber(plan.target_quantity)} pcs</Text>
          </View>
          <View style={styles.infoCol}>
            <Text style={styles.infoLabel}>Line</Text>
            <Text style={styles.infoValue}>Line {plan.line_code}</Text>
          </View>
        </View>

        <View style={styles.infoGrid}>
          <View style={styles.infoCol}>
            <Text style={styles.infoLabel}>Priority</Text>
            <Text style={styles.infoValue}>{plan.priority}</Text>
          </View>
          <View style={styles.infoCol}>
            <Text style={styles.infoLabel}>Start Date</Text>
            <Text style={styles.infoValue}>{formatDate(plan.start_date)}</Text>
          </View>
        </View>

        {plan.expected_completion ? (
          <View style={{ marginTop: 6 }}>
            <Text style={styles.infoLabel}>Expected Completion</Text>
            <Text style={styles.infoValue}>{formatDate(plan.expected_completion)}</Text>
          </View>
        ) : null}

        {plan.notes ? (
          <View style={{ marginTop: 6, borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 6 }}>
            <Text style={styles.infoLabel}>Notes / Instructions</Text>
            <Text style={styles.notesText}>{plan.notes}</Text>
          </View>
        ) : null}
      </Card>

      {/* Action Buttons */}
      <View style={styles.actionRow}>
        <View style={{ flex: 1 }}>
          <Button label="Edit Plan" variant="secondary" onPress={handleOpenEdit} />
        </View>
        <View style={{ flex: 1 }}>
          <Button label="Delete Plan" variant="danger" onPress={handleDelete} />
        </View>
      </View>

      {/* Edit Plan Modal */}
      <Modal visible={showEditModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>Edit Production Plan</Text>
              <Pressable onPress={() => setShowEditModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false} style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>Target Quantity *</Text>
              <TextInput
                style={styles.input}
                keyboardType="numeric"
                value={editTargetQty}
                onChangeText={setEditTargetQty}
              />

              <Text style={styles.inputLabel}>Status</Text>
              <View style={styles.chipRow}>
                {STATUSES.map((s) => {
                  const active = editStatus === s;
                  return (
                    <Pressable
                      key={s}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => setEditStatus(s)}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>{s}</Text>
                    </Pressable>
                  );
                })}
              </View>

              <Text style={styles.inputLabel}>Priority</Text>
              <View style={styles.chipRow}>
                {PRIORITIES.map((p) => {
                  const active = editPriority === p;
                  return (
                    <Pressable
                      key={p}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => setEditPriority(p)}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>{p}</Text>
                    </Pressable>
                  );
                })}
              </View>

              <Text style={styles.inputLabel}>Notes</Text>
              <TextInput
                style={[styles.input, { height: 60 }]}
                multiline
                placeholder="Optional planning notes"
                value={editNotes}
                onChangeText={setEditNotes}
              />
            </ScrollView>

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowEditModal(false)} />
              <Button label="Save Changes" onPress={handleSaveEdit} />
            </View>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, gap: spacing.md },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  subtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '700',
  },
  infoCard: {
    padding: spacing.md,
    gap: 10,
  },
  infoGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  infoCol: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
    textTransform: 'uppercase',
  },
  infoValue: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.text,
    marginTop: 2,
  },
  notesText: {
    fontSize: 13,
    color: colors.text,
    marginTop: 2,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 6,
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
    alignItems: 'center',
    marginBottom: spacing.md,
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
    paddingVertical: 8,
    fontSize: 14,
    color: colors.text,
    backgroundColor: colors.background,
  },
  chipRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginVertical: 4,
  },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  chipActive: {
    backgroundColor: '#0A1E38',
    borderColor: '#0A1E38',
  },
  chipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
  },
  chipTextActive: {
    color: '#FFFFFF',
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
});
