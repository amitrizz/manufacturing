import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { createDispatchOrder } from '../../database/repositories/dispatchRepository';
import { listProducts } from '../../database/repositories/productRepository';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';

type Props = NativeStackScreenProps<MoreStackParamList, 'DispatchCreate'>;

export function DispatchCreateScreen({ navigation }: Props) {
  const [products, setProducts] = useState<{ id: string; code: string }[]>([]);
  const [productId, setProductId] = useState('');
  const [customer, setCustomer] = useState('');
  const [qty, setQty] = useState('50');
  const [number, setNumber] = useState(() => `DSP-${Date.now().toString().slice(-5)}`);

  useEffect(() => {
    listProducts().then((p) => {
      setProducts(p);
      if (p[0]) setProductId(p[0].id);
    });
  }, []);

  const submit = async () => {
    try {
      await createDispatchOrder({
        dispatch_number: number,
        customer_name: customer,
        product_id: productId,
        quantity: Number(qty),
      });
      navigation.goBack();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  return (
    <View style={styles.container}>
      <TextInput style={styles.input} placeholder="Dispatch #" value={number} onChangeText={setNumber} />
      <TextInput style={styles.input} placeholder="Customer" value={customer} onChangeText={setCustomer} />
      {products.map((p) => (
        <Pressable key={p.id} onPress={() => setProductId(p.id)}>
          <Text>{p.code} {productId === p.id ? '✓' : ''}</Text>
        </Pressable>
      ))}
      <TextInput style={styles.input} value={qty} onChangeText={setQty} keyboardType="numeric" />
      <Pressable style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Create</Text>
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
});
