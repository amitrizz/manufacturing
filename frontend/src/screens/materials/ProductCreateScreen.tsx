import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { UnitPicker } from '../../components/common/UnitPicker';
import { listMaterials } from '../../api/repositories/materialRepository';
import { createProductWithBom } from '../../api/repositories/productRepository';
import type { MaterialRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<MoreStackParamList, 'ProductCreate'>;

type BomDraftLine = {
  key: string;
  material_id: string;
  quantity: string;
};

export function ProductCreateScreen({ navigation }: Props) {
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [unit, setUnit] = useState('pcs');
  const [description, setDescription] = useState('');
  const [materials, setMaterials] = useState<MaterialRow[]>([]);
  const [lines, setLines] = useState<BomDraftLine[]>([]);

  useEffect(() => {
    listMaterials().then((m) => {
      setMaterials(m);
      setLines((prev) => {
        if (prev.length > 0 || !m[0]) return prev;
        return [{ key: '1', material_id: m[0].id, quantity: '1' }];
      });
    });
  }, []);

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
      const productId = await createProductWithBom({
        code,
        name,
        unit,
        description,
        bom_lines,
      });
      navigation.replace('ProductBom', { productId });
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  return (
    <Screen contentContainerStyle={styles.content}>
      <Text style={typography.h2}>New product & BOM</Text>
      <Text style={typography.caption}>
        Define the finished product and which materials (qty per 1 unit) are consumed when you
        produce it.
      </Text>

      <Text style={typography.label}>Product code</Text>
      <TextInput style={styles.input} value={code} onChangeText={setCode} autoCapitalize="characters" />

      <Text style={typography.label}>Product name</Text>
      <TextInput style={styles.input} value={name} onChangeText={setName} placeholder="e.g. Ball Valve 2 inch" />

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
      <Button label="Create product" onPress={submit} />
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