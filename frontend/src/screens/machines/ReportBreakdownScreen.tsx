import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { reportBreakdown } from '../../services/breakdownService';
import type { MachinesStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';

type Props = NativeStackScreenProps<MachinesStackParamList, 'ReportBreakdown'>;

export function ReportBreakdownScreen({ navigation, route }: Props) {
  const [description, setDescription] = useState('');

  const submit = async () => {
    try {
      await reportBreakdown(route.params.machineId, 'MECHANICAL_FAILURE', description);
      navigation.goBack();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={typography.label}>Description</Text>
      <TextInput
        style={styles.input}
        value={description}
        onChangeText={setDescription}
        multiline
      />
      <Pressable style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Submit breakdown</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: spacing.lg, backgroundColor: colors.background, gap: spacing.sm },
  input: {
    minHeight: 100,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
    textAlignVertical: 'top',
  },
  btn: { backgroundColor: colors.danger, padding: spacing.md, borderRadius: 8 },
  btnText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});
