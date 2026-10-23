import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { Screen } from '../../components/common/Screen';
import { listLines } from '../../api/repositories/machineRepository';
import { createProductionPlan } from '../../api/repositories/productionPlanRepository';
import { listProducts } from '../../api/repositories/productRepository';
import type { Priority } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionPlanCreate'>;

const PRIORITIES: Priority[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

export function ProductionPlanCreateScreen({ navigation }: Props) {
  const [products, setProducts] = useState<{ id: string; code: string; name: string }[]>([]);
  const [lines, setLines] = useState<{ id: string; code: string; name: string }[]>([]);
  const [planNumber, setPlanNumber] = useState(() => `PLN-${Date.now().toString().slice(-6)}`);
  const [productId, setProductId] = useState('');
  const [lineId, setLineId] = useState('');
  const [target, setTarget] = useState('500');
  const [priority, setPriority] = useState<Priority>('MEDIUM');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    listProducts().then((p) => {
      setProducts(p);
      if (p[0]) setProductId(p[0].id);
    });
    listLines().then((l) => {
      setLines(l);
      if (l[0]) setLineId(l[0].id);
    });
  }, []);

  const submit = async () => {
    try {
      const qty = Number(target);
      if (!Number.isFinite(qty) || qty <= 0) {
        Alert.alert('Error', 'Enter a valid target quantity');
        return;
      }
      if (!productId || !lineId) {
        Alert.alert('Error', 'Select a product and production line');
        return;
      }
      const now = Date.now();
      const planId = await createProductionPlan({
        plan_number: planNumber.trim(),
        product_id: productId,
        line_id: lineId,
        target_quantity: qty,
        planned_quantity: qty,
        priority,
        start_date: now,
        end_date: now + 7 * 86400000,
        notes: notes.trim() || undefined,
      });
      navigation.replace('ProductionPlanDetail', { planId });
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed to create plan');
    }
  };

  return (
    <Screen contentContainerStyle={styles.container}>
      <Text style={typography.h2}>New Production Plan</Text>
      <Text style={typography.caption}>
        Define target output schedule, product, and assigned production line.
      </Text>

      <Text style={typography.label}>Plan Number</Text>
      <TextInput style={styles.input} value={planNumber} onChangeText={setPlanNumber} />

      <Text style={typography.label}>Product</Text>
      <View style={styles.chips}>
        {products.map((p) => (
          <Pressable
            key={p.id}
            style={[styles.chip, productId === p.id && styles.chipActive]}
            onPress={() => setProductId(p.id)}
          >
            <Text style={productId === p.id ? styles.chipTextActive : undefined}>{p.code}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Production Line</Text>
      <View style={styles.chips}>
        {lines.map((l) => (
          <Pressable
            key={l.id}
            style={[styles.chip, lineId === l.id && styles.chipActive]}
            onPress={() => setLineId(l.id)}
          >
            <Text style={lineId === l.id ? styles.chipTextActive : undefined}>{l.code}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Planned Target Quantity</Text>
      <TextInput
        style={styles.input}
        value={target}
        onChangeText={setTarget}
        keyboardType="numeric"
      />

      <Text style={typography.label}>Priority</Text>
      <View style={styles.chips}>
        {PRIORITIES.map((p) => (
          <Pressable
            key={p}
            style={[styles.chip, priority === p && styles.chipActive]}
            onPress={() => setPriority(p)}
          >
            <Text style={priority === p ? styles.chipTextActive : undefined}>{p}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Notes (Optional)</Text>
      <TextInput
        style={[styles.input, { height: 80 }]}
        value={notes}
        onChangeText={setNotes}
        multiline
        placeholder="Delivery expectations, customer instructions..."
      />

      <Button label="Create Plan" onPress={submit} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: { gap: spacing.sm, paddingBottom: spacing.xxl },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  chip: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipTextActive: { color: '#fff', fontWeight: '600' },
});
