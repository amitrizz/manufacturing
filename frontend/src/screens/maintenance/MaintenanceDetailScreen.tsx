import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import {
  completeMaintenanceOrder,
  deleteMaintenanceOrder,
  getMaintenanceOrderById,
} from '../../database/repositories/maintenanceRepository';
import type { MaintenanceOrderRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<MoreStackParamList, 'MaintenanceDetail'>;

export function MaintenanceDetailScreen({ navigation, route }: Props) {
  const [order, setOrder] = useState<MaintenanceOrderRow | null>(null);
  const [rootCause, setRootCause] = useState('');
  const [action, setAction] = useState('');

  const load = useCallback(() => {
    getMaintenanceOrderById(route.params.orderId).then(setOrder);
  }, [route.params.orderId]);

  useLiveQuery(load);

  const complete = async () => {
    try {
      await completeMaintenanceOrder(route.params.orderId, {
        root_cause: rootCause,
        action_taken: action,
      });
      navigation.goBack();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  const handleDeleteTicket = () => {
    if (!order) return;
    Alert.alert(
      'Delete Ticket',
      `Are you sure you want to delete maintenance ticket ${order.order_number}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteMaintenanceOrder(order.id);
              Alert.alert('Deleted', 'Maintenance ticket deleted.');
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete ticket');
            }
          },
        },
      ],
    );
  };

  if (!order) return null;

  return (
    <View style={styles.container}>
      <Text style={typography.h2}>{order.order_number}</Text>
      <Text style={typography.bodySmall}>
        Machine: {order.machine_code} · Type: {order.type} · Status: {order.status}
      </Text>
      {order.issue ? (
        <View style={styles.issueBox}>
          <Text style={styles.issueLabel}>Reported Issue:</Text>
          <Text style={styles.issueText}>{order.issue}</Text>
        </View>
      ) : null}

      {order.status !== 'COMPLETED' ? (
        <>
          <TextInput
            style={styles.input}
            placeholder="Root cause"
            value={rootCause}
            onChangeText={setRootCause}
          />
          <TextInput
            style={styles.input}
            placeholder="Action taken"
            value={action}
            onChangeText={setAction}
          />
          <Pressable style={styles.btn} onPress={complete}>
            <Text style={styles.btnText}>Complete maintenance</Text>
          </Pressable>
        </>
      ) : (
        <View style={styles.completedBox}>
          <Text style={styles.issueLabel}>Action Taken:</Text>
          <Text style={typography.body}>{order.action_taken || 'Completed'}</Text>
          {order.root_cause && (
            <Text style={styles.rootCauseText}>Root cause: {order.root_cause}</Text>
          )}
        </View>
      )}

      <Pressable style={styles.deleteBtn} onPress={handleDeleteTicket}>
        <Text style={styles.deleteBtnText}>Delete Ticket</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: spacing.lg, backgroundColor: colors.background, gap: spacing.sm },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  btn: { backgroundColor: colors.primary, padding: spacing.md, borderRadius: 8 },
  btnText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
  issueBox: {
    backgroundColor: '#F8FAFC',
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 4,
  },
  issueLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  issueText: {
    fontSize: 14,
    color: colors.text,
  },
  completedBox: {
    backgroundColor: '#F0FDF4',
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#BBF7D0',
    gap: 4,
  },
  rootCauseText: {
    fontSize: 12,
    color: colors.textSecondary,
    fontStyle: 'italic',
    marginTop: 4,
  },
  deleteBtn: {
    marginTop: 12,
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#FECACA',
    backgroundColor: '#FEF2F2',
    alignItems: 'center',
  },
  deleteBtnText: {
    color: colors.danger,
    fontWeight: '700',
    fontSize: 14,
  },
});
