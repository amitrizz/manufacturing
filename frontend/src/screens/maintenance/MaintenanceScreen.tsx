import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
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
import { listMachines } from '../../api/repositories/machineRepository';
import {
  createMaintenanceOrder,
  listMaintenanceOrders,
} from '../../api/repositories/maintenanceRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import type { MachineRow, MaintenanceOrderRow, Priority } from '../../types/database';
import { formatDateTime } from '../../utils/format';

type Props = NativeStackScreenProps<MoreStackParamList, 'Maintenance'>;

const ORDER_TYPES = ['PREVENTIVE', 'CORRECTIVE', 'BREAKDOWN'] as const;
const PRIORITIES: Priority[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

export function MaintenanceScreen({ navigation }: Props) {
  const [orders, setOrders] = useState<MaintenanceOrderRow[]>([]);
  const [machines, setMachines] = useState<MachineRow[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  // New Ticket Modal State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedMachineId, setSelectedMachineId] = useState('');
  const [orderType, setOrderType] = useState<'PREVENTIVE' | 'CORRECTIVE' | 'BREAKDOWN'>('PREVENTIVE');
  const [priority, setPriority] = useState<Priority>('MEDIUM');
  const [issue, setIssue] = useState('');
  const [assignedTeam, setAssignedTeam] = useState('');

  const load = useCallback(async () => {
    setRefreshing(true);
    try {
      const [orderList, machineList] = await Promise.all([
        listMaintenanceOrders(),
        listMachines().catch(() => []),
      ]);
      setOrders(orderList);
      setMachines(machineList);
      if (machineList.length > 0 && !selectedMachineId) {
        setSelectedMachineId(machineList[0].id);
      }
    } finally {
      setRefreshing(false);
    }
  }, [selectedMachineId]);

  useLiveQuery(load);

  const handleCreateOrder = async () => {
    if (!selectedMachineId || !issue.trim()) {
      Alert.alert('Required Fields', 'Please select a machine and describe the issue.');
      return;
    }
    try {
      await createMaintenanceOrder({
        machine_id: selectedMachineId,
        type: orderType,
        priority,
        issue: issue.trim(),
        assigned_team: assignedTeam.trim() || undefined,
      });
      setShowCreateModal(false);
      setIssue('');
      setAssignedTeam('');
      Alert.alert('Success', 'Maintenance ticket created successfully.');
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create maintenance ticket');
    }
  };

  return (
    <View style={styles.container}>
      {/* Header with Title and Add Button */}
      <View style={styles.headerRow}>
        <View>
          <Text style={typography.h2}>Maintenance Tickets</Text>
          <Text style={typography.caption}>{orders.length} tickets total</Text>
        </View>
        <Button
          label="+ New Ticket"
          onPress={() => {
            if (machines.length > 0 && !selectedMachineId) setSelectedMachineId(machines[0].id);
            setShowCreateModal(true);
          }}
        />
      </View>

      <FlatList
        data={orders}
        keyExtractor={(o) => o.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={load} />}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="construct-outline" size={36} color={colors.textSecondary} />
            <Text style={styles.emptyText}>No maintenance tickets logged</Text>
          </View>
        }
        renderItem={({ item }) => {
          const isCompleted = item.status === 'COMPLETED';
          const isBreakdown = item.type === 'BREAKDOWN';

          return (
            <Pressable
              onPress={() => navigation.navigate('MaintenanceDetail', { orderId: item.id })}
            >
              <Card style={styles.card}>
                <View style={styles.cardHeader}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.orderNumber}>{item.order_number}</Text>
                    <Text style={styles.machineCode}>Machine: {item.machine_code}</Text>
                  </View>
                  <View style={{ flexDirection: 'row', gap: 6, alignItems: 'center' }}>
                    <View
                      style={[
                        styles.badge,
                        {
                          backgroundColor: isBreakdown ? '#FEE2E2' : '#E0F2FE',
                        },
                      ]}
                    >
                      <Text
                        style={[
                          styles.badgeText,
                          { color: isBreakdown ? '#DC2626' : '#0369A1' },
                        ]}
                      >
                        {item.type}
                      </Text>
                    </View>
                    <View
                      style={[
                        styles.badge,
                        {
                          backgroundColor: isCompleted ? '#DCFCE7' : '#FEF3C7',
                        },
                      ]}
                    >
                      <Text
                        style={[
                          styles.badgeText,
                          { color: isCompleted ? '#16A34A' : '#D97706' },
                        ]}
                      >
                        {item.status}
                      </Text>
                    </View>
                  </View>
                </View>

                {item.issue ? (
                  <Text style={styles.issueText} numberOfLines={2}>
                    {item.issue}
                  </Text>
                ) : null}

                <View style={styles.footerRow}>
                  <Text style={styles.priorityText}>Priority: {item.priority}</Text>
                  <Text style={styles.timestamp}>{formatDateTime(item.created_at)}</Text>
                </View>
              </Card>
            </Pressable>
          );
        }}
      />

      {/* New Ticket Modal */}
      <Modal visible={showCreateModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>New Maintenance Ticket</Text>
              <Pressable onPress={() => setShowCreateModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false} style={{ maxHeight: 440 }}>
              <Text style={styles.inputLabel}>Select Machine *</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 4 }}>
                {machines.map((m) => {
                  const active = selectedMachineId === m.id;
                  return (
                    <Pressable
                      key={m.id}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => setSelectedMachineId(m.id)}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>
                        {m.code} ({m.name})
                      </Text>
                    </Pressable>
                  );
                })}
              </ScrollView>

              <Text style={styles.inputLabel}>Ticket Type *</Text>
              <View style={styles.chipRow}>
                {ORDER_TYPES.map((t) => {
                  const active = orderType === t;
                  return (
                    <Pressable
                      key={t}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => setOrderType(t)}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>{t}</Text>
                    </Pressable>
                  );
                })}
              </View>

              <Text style={styles.inputLabel}>Priority *</Text>
              <View style={styles.chipRow}>
                {PRIORITIES.map((p) => {
                  const active = priority === p;
                  return (
                    <Pressable
                      key={p}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => setPriority(p)}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>{p}</Text>
                    </Pressable>
                  );
                })}
              </View>

              <Text style={styles.inputLabel}>Issue / Fault Description *</Text>
              <TextInput
                style={[styles.input, { height: 70 }]}
                placeholder="Describe machine issue or reason for maintenance"
                multiline
                value={issue}
                onChangeText={setIssue}
              />

              <Text style={styles.inputLabel}>Assigned Team / Technician (Optional)</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Electrical Team, Mech Team"
                value={assignedTeam}
                onChangeText={setAssignedTeam}
              />
            </ScrollView>

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowCreateModal(false)} />
              <Button label="Create Ticket" onPress={handleCreateOrder} />
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.md,
    paddingBottom: spacing.sm,
  },
  listContent: { padding: spacing.lg, paddingBottom: 40 },
  card: {
    marginBottom: spacing.sm,
    padding: spacing.md,
    gap: 6,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  orderNumber: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.text,
  },
  machineCode: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  issueText: {
    fontSize: 13,
    color: colors.text,
    marginVertical: 4,
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 6,
  },
  priorityText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  timestamp: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  emptyContainer: {
    paddingVertical: 40,
    alignItems: 'center',
    gap: 8,
  },
  emptyText: {
    color: colors.textSecondary,
    fontSize: 14,
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
    marginRight: 6,
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
