import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { UnitPicker } from '../../components/common/UnitPicker';
import { getBomForProduct, listMaterials } from '../../api/repositories/materialRepository';
import {
  deleteProduct,
  getProductById,
  updateProductWithBom,
} from '../../api/repositories/productRepository';
import type { MoreStackParamList } from '../../navigation/types';
import type { MaterialRow } from '../../types/database';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<MoreStackParamList, 'ProductEdit'>;

type BomDraftLine = {
  key: string;
  material_id: string;
  quantity: string;
};

export function ProductEditScreen({ navigation, route }: Props) {
  const { productId } = route.params;
  const [materials, setMaterials] = useState<MaterialRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [unit, setUnit] = useState('pcs');
  const [description, setDescription] = useState('');
  const [lines, setLines] = useState<BomDraftLine[]>([]);

  useEffect(() => {
    (async () => {
      const [mats, product, bom] = await Promise.all([
        listMaterials(),
        getProductById(productId),
        getBomForProduct(productId),
      ]);
      setMaterials(mats);
      if (!product) {
        Alert.alert('Not found', 'Product was removed.', [{ text: 'OK', onPress: () => navigation.goBack() }]);
        setLoading(false);
        return;
      }
      setCode(product.code || '');
      setName(product.name || '');
      setUnit(product.unit || 'pcs');
      setDescription(product.description ?? '');
      if (bom.length > 0) {
        setLines(
          bom.map((item, i) => ({
            key: `${item.material_id}-${i}`,
            material_id: item.material_id,
            quantity: String(item.quantity ?? 1),
          })),
        );
      } else if (mats[0]) {
        setLines([{ key: '1', material_id: mats[0].id, quantity: '1' }]);
      }
      setLoading(false);
    })();
  }, [navigation, productId]);

  const addLine = () => {
    const mat = materials[0];
    if (!mat) return;
    setLines((prev) => [
      ...prev,
      { key: String(Date.now()), material_id: mat.id, quantity: '1' },
    ]);
  };

  const removeLine = (key: string) => {
    setLines((prev) => (prev.length <= 1 ? prev : prev.filter((l) => l.key !== key)));
  };

  const submit = async () => {
    try {
      const bom_lines = lines.map((line) => {
        const mat = materials.find((m) => m.id === line.material_id);
        if (!mat) throw new Error('Select a material for each row');
        return {
          material_id: line.material_id,
          quantity: Number(line.quantity.replace(',', '.')),
          unit: mat.unit,
        };
      });
      await updateProductWithBom({
        product_id: productId,
        code,
        name,
        unit,
        description,
        bom_lines,
      });
      navigation.goBack();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Delete Product',
      `Are you sure you want to delete "${name}" (${code})? This will also remove its associated BOM and finished goods records.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteProduct(productId);
              Alert.alert('Deleted', 'Product has been deleted.');
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert(
                'Delete Failed',
                e instanceof Error ? e.message : 'Could not delete product.',
              );
            }
          },
        },
      ],
    );
  };

  if (loading) {
    return (
      <Screen>
        <Text style={typography.body}>Loading…</Text>
      </Screen>
    );
  }

  return (
    <Screen contentContainerStyle={styles.content}>
      <Text style={typography.h2}>Edit product & BOM</Text>
      <Text style={typography.caption}>
        Change product details and materials consumed per 1 unit. Existing production history is
        not changed.
      </Text>

      <Text style={typography.label}>Product code</Text>
      <TextInput style={styles.input} value={code} onChangeText={setCode} autoCapitalize="characters" />

      <Text style={typography.label}>Product name</Text>
      <TextInput style={styles.input} value={name} onChangeText={setName} />

      <UnitPicker
        label="Unit"
        required
        value={unit}
        onChange={setUnit}
      />

      <Text style={typography.label}>Description (optional)</Text>
      <TextInput
        style={styles.input}
        value={description}
        onChangeText={setDescription}
        multiline
      />

      <SectionHeader title="Materials used (per 1 unit)" />
      {lines.map((line, index) => {
        const mat = materials.find((m) => m.id === line.material_id);
        return (
          <View key={line.key} style={styles.bomBlock}>
            <Text style={typography.caption}>Line {index + 1}</Text>
            <Text style={typography.label}>Material</Text>
            <View style={styles.chips}>
              {materials.map((m) => (
                <Pressable
                  key={m.id}
                  style={[styles.chip, line.material_id === m.id && styles.chipActive]}
                  onPress={() =>
                    setLines((prev) =>
                      prev.map((l) => (l.key === line.key ? { ...l, material_id: m.id } : l)),
                    )
                  }
                >
                  <Text style={line.material_id === m.id ? styles.chipTextActive : undefined}>
                    {m.code}
                  </Text>
                </Pressable>
              ))}
            </View>
            <Text style={typography.label}>
              Quantity per unit {mat ? `(${mat.unit})` : ''}
            </Text>
            <TextInput
              style={styles.input}
              value={line.quantity}
              onChangeText={(t) =>
                setLines((prev) =>
                  prev.map((l) => (l.key === line.key ? { ...l, quantity: t } : l)),
                )
              }
              keyboardType="decimal-pad"
            />
            {lines.length > 1 ? (
              <Pressable onPress={() => removeLine(line.key)}>
                <Text style={styles.remove}>Remove line</Text>
              </Pressable>
            ) : null}
          </View>
        );
      })}

      <Button label="+ Add material" variant="secondary" onPress={addLine} />
      <Button label="Save changes" onPress={submit} />
      <Button
        label="View BOM (read-only)"
        variant="ghost"
        onPress={() => navigation.navigate('ProductBom', { productId })}
      />
      <Button
        label="Delete Product"
        variant="secondary"
        onPress={handleDelete}
        style={{ borderColor: '#FECACA', backgroundColor: '#FEF2F2' }}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  content: { gap: spacing.sm, paddingBottom: spacing.xxl },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  bomBlock: {
    padding: spacing.md,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  chip: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipTextActive: { color: '#fff', fontWeight: '600' },
  remove: { color: colors.danger, marginTop: spacing.xs, fontWeight: '600' },
});