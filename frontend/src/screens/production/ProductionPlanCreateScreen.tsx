import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Screen } from '../../components/common/Screen';
import { createProductionPlan } from '../../database/repositories/productionPlanRepository';
import { listLines } from '../../database/repositories/machineRepository';
import { listProducts } from '../../database/repositories/productRepository';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionPlanCreate'>;

export function ProductionPlanCreateScreen({ navigation }: Props) {
  const [products, setProducts] = useState<{ id: string; code: string }[]>([]);
  const [lines, setLines] = useState<{ id: string; code: string }[]>([]);
  const [productId, setProductId] = useState('');
  const [lineId, setLineId] = useState('');
  const [target, setTarget] = useState('100');
  const [planNumber, setPlanNumber] = useState(() => `PLN-${Date.now().toString().slice(-6)}`);

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
      const now = Date.now();
      const id = await createProductionPlan({
        plan_number: planNumber,
        product_id: productId,
        target_quantity: Number(target),
        line_id: lineId,
        start_date: now,
        expected_completion: now + 3 * 24 * 60 * 60 * 1000,
        priority: 'MEDIUM',
      });
      navigation.replace('ProductionPlanDetail', { planId: id });
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  return (
    <Screen contentContainerStyle={styles.container}>
      <Text style={typography.label}>Plan number</Text>
      <TextInput style={styles.input} value={planNumber} onChangeText={setPlanNumber} />
      <Text style={typography.label}>Product ({products.find((p) => p.id === productId)?.code})</Text>
      <View style={styles.chips}>
        {products.map((p) => (
          <Pressable key={p.id} style={styles.chip} onPress={() => setProductId(p.id)}>
            <Text>{p.code}</Text>
          </Pressable>
        ))}
      </View>
      <Text style={typography.label}>Line</Text>
      <View style={styles.chips}>
        {lines.map((l) => (
          <Pressable key={l.id} style={styles.chip} onPress={() => setLineId(l.id)}>
            <Text>{l.code}</Text>
          </Pressable>
        ))}
      </View>
      <Text style={typography.label}>Target quantity</Text>
      <TextInput style={styles.input} value={target} onChangeText={setTarget} keyboardType="numeric" />
      <Pressable style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Create plan</Text>
      </Pressable>
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
  chip: { padding: spacing.sm, backgroundColor: colors.surface, borderRadius: 6 },
  btn: { backgroundColor: colors.primary, padding: spacing.md, borderRadius: 8, marginTop: spacing.md },
  btnText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});
