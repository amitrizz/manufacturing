import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { DatePresetChips } from '../../components/common/DatePresetChips';
import type { ReportType } from '../../database/repositories/reportsRepository';
import { getReportData } from '../../database/repositories/reportsRepository';
import { exportReport } from '../../services/exportService';
import type { MoreStackParamList } from '../../navigation/types';
import { useFilterStore } from '../../store/filterStore';
import { colors, spacing, typography } from '../../theme';
import { getRangeForPreset } from '../../utils/dateRange';

type Props = NativeStackScreenProps<MoreStackParamList, 'Reports'>;

const REPORTS: { type: ReportType; label: string }[] = [
  { type: 'production', label: 'Production' },
  { type: 'quality', label: 'Quality' },
  { type: 'downtime', label: 'Downtime' },
  { type: 'maintenance', label: 'Maintenance' },
  { type: 'materials', label: 'Materials' },
  { type: 'finished_goods', label: 'Finished goods' },
  { type: 'dispatch', label: 'Dispatch' },
  { type: 'oee_summary', label: 'OEE summary' },
  { type: 'attendance', label: 'Staff Attendance' },
];

export function ReportsScreen({ navigation }: Props) {
  const preset = useFilterStore((s) => s.dashboardDatePreset);
  const setPreset = useFilterStore((s) => s.setDashboardDatePreset);
  const customStart = useFilterStore((s) => s.customRangeStart);
  const customEnd = useFilterStore((s) => s.customRangeEnd);
  const [preview, setPreview] = useState<string>('');

  const runPreview = async (type: ReportType) => {
    const { start, end } = getRangeForPreset(preset, customStart ?? undefined, customEnd ?? undefined);
    const rows = await getReportData(type, start, end);
    setPreview(`${type}: ${rows.length} rows`);
  };

  const exportCsv = async (type: ReportType) => {
    try {
      const { start, end } = getRangeForPreset(preset, customStart ?? undefined, customEnd ?? undefined);
      await exportReport(type, start, end, 'csv');
    } catch (e: unknown) {
      Alert.alert('Export failed', e instanceof Error ? e.message : 'Unknown');
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <DatePresetChips value={preset} onChange={setPreset} />
      <Pressable onPress={() => navigation.navigate('Oee')}>
        <Text style={styles.oeeLink}>OEE detail screen →</Text>
      </Pressable>
      {REPORTS.map((r) => (
        <View key={r.type} style={styles.row}>
          <Text style={typography.body}>{r.label}</Text>
          <View style={styles.actions}>
            <Pressable onPress={() => runPreview(r.type)}>
              <Text style={styles.action}>Preview</Text>
            </Pressable>
            <Pressable onPress={() => exportCsv(r.type)}>
              <Text style={styles.action}>CSV</Text>
            </Pressable>
            <Pressable onPress={() => exportReport(r.type, 0, Date.now(), 'json').catch(() => {})}>
              <Text style={styles.action}>JSON</Text>
            </Pressable>
          </View>
        </View>
      ))}
      {preview ? <Text style={typography.caption}>{preview}</Text> : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, gap: spacing.md },
  row: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  actions: { flexDirection: 'row', gap: spacing.md, marginTop: spacing.xs },
  action: { color: colors.primary, fontWeight: '600' },
  oeeLink: { color: colors.primary, fontWeight: '600' },
});
