import { Ionicons } from '@expo/vector-icons';
import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import {
  createUnit,
  DEFAULT_APP_UNITS,
  listUnits,
} from '../../api/repositories/unitRepository';
import { colors, spacing, typography } from '../../theme';
import type { UnitCategory, UnitRow } from '../../types/database';

interface UnitPickerProps {
  value: string;
  onChange: (unitCode: string, unit?: UnitRow) => void;
  label?: string;
  required?: boolean;
  disabled?: boolean;
  error?: string;
  style?: object;
  placeholder?: string;
}

const CATEGORIES: ('All' | UnitCategory)[] = [
  'All',
  'Count',
  'Weight',
  'Volume',
  'Length',
  'Packaging',
  'Area',
];

export function UnitPicker({
  value,
  onChange,
  label = 'Unit',
  required = false,
  disabled = false,
  error,
  style,
  placeholder = 'Select unit',
}: UnitPickerProps) {
  const [modalVisible, setModalVisible] = useState(false);
  const [units, setUnits] = useState<UnitRow[]>(DEFAULT_APP_UNITS);
  const [selectedCategory, setSelectedCategory] = useState<'All' | UnitCategory>('All');
  const [search, setSearch] = useState('');

  // Add custom unit sub-state
  const [showAddCustom, setShowAddCustom] = useState(false);
  const [customCode, setCustomCode] = useState('');
  const [customName, setCustomName] = useState('');
  const [customSymbol, setCustomSymbol] = useState('');
  const [customCategory, setCustomCategory] = useState<UnitCategory>('Count');
  const [savingCustom, setSavingCustom] = useState(false);

  useEffect(() => {
    let isMounted = true;
    listUnits().then((data) => {
      if (isMounted && data.length > 0) {
        setUnits(data);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [modalVisible]);

  const selectedUnit = useMemo(() => {
    if (!value) return null;
    const vLower = value.trim().toLowerCase();
    return (
      units.find(
        (u) =>
          u.code.toLowerCase() === vLower ||
          u.symbol.toLowerCase() === vLower ||
          u.name.toLowerCase() === vLower,
      ) || null
    );
  }, [value, units]);

  const filteredUnits = useMemo(() => {
    let result = units;
    if (selectedCategory !== 'All') {
      result = result.filter((u) => u.category === selectedCategory);
    }
    const q = search.trim().toLowerCase();
    if (q) {
      result = result.filter(
        (u) =>
          u.code.toLowerCase().includes(q) ||
          u.name.toLowerCase().includes(q) ||
          u.symbol.toLowerCase().includes(q),
      );
    }
    return result;
  }, [units, selectedCategory, search]);

  const handleSelect = (unit: UnitRow) => {
    // Return unit's code or symbol depending on existing style, lower or upper
    onChange(unit.symbol || unit.code, unit);
    setModalVisible(false);
  };

  const handleSaveCustom = async () => {
    const code = customCode.trim().toUpperCase();
    const name = customName.trim();
    if (!code || !name) {
      Alert.alert('Required Fields', 'Please enter both Unit Code (e.g. BRL) and Unit Name (e.g. Barrel).');
      return;
    }

    try {
      setSavingCustom(true);
      const created = await createUnit({
        code,
        name,
        symbol: customSymbol.trim() || code.toLowerCase(),
        category: customCategory,
        precision: 0,
        is_active: true,
      });

      setUnits((prev) => [created, ...prev]);
      onChange(created.symbol || created.code, created);
      setShowAddCustom(false);
      setCustomCode('');
      setCustomName('');
      setCustomSymbol('');
      setModalVisible(false);
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed to save unit');
    } finally {
      setSavingCustom(false);
    }
  };

  return (
    <View style={[styles.container, style]}>
      {Boolean(label) && (
        <Text style={styles.label}>
          {label} {required && <Text style={styles.requiredStar}>*</Text>}
        </Text>
      )}

      <Pressable
        style={[
          styles.trigger,
          disabled && styles.triggerDisabled,
          Boolean(error) && styles.triggerError,
        ]}
        onPress={() => !disabled && setModalVisible(true)}
      >
        <View style={styles.triggerContent}>
          {selectedUnit ? (
            <View style={styles.selectedBadge}>
              <Text style={styles.selectedCode}>{selectedUnit.code}</Text>
              <Text style={styles.selectedName}>· {selectedUnit.name}</Text>
            </View>
          ) : value ? (
            <View style={styles.selectedBadge}>
              <Text style={styles.selectedCode}>{value.toUpperCase()}</Text>
            </View>
          ) : (
            <Text style={styles.placeholderText}>{placeholder}</Text>
          )}
        </View>

        <Ionicons
          name="chevron-down"
          size={18}
          color={colors.textMuted || '#64748B'}
        />
      </Pressable>

      {Boolean(error) && <Text style={styles.errorText}>{error}</Text>}

      {/* Modal Dropdown Picker */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            {/* Modal Header */}
            <View style={styles.modalHeader}>
              <View>
                <Text style={styles.modalTitle}>Select Unit of Measurement</Text>
                <Text style={styles.modalSubtitle}>
                  Choose standard manufacturing unit or add custom
                </Text>
              </View>
              <Pressable
                onPress={() => setModalVisible(false)}
                style={styles.closeBtn}
              >
                <Ionicons name="close" size={22} color={colors.text || '#0F172A'} />
              </Pressable>
            </View>

            {!showAddCustom ? (
              <>
                {/* Search Bar */}
                <View style={styles.searchContainer}>
                  <Ionicons name="search" size={18} color="#94A3B8" />
                  <TextInput
                    style={styles.searchInput}
                    value={search}
                    onChangeText={setSearch}
                    placeholder="Search unit by name, code, symbol..."
                    placeholderTextColor="#94A3B8"
                    clearButtonMode="while-editing"
                  />
                  {search ? (
                    <Pressable onPress={() => setSearch('')}>
                      <Ionicons name="close-circle" size={16} color="#94A3B8" />
                    </Pressable>
                  ) : null}
                </View>

                {/* Categories Bar */}
                <View style={styles.categoryScroll}>
                  <FlatList
                    horizontal
                    showsHorizontalScrollIndicator={false}
                    data={CATEGORIES}
                    keyExtractor={(item) => item}
                    contentContainerStyle={styles.categoryList}
                    renderItem={({ item }) => {
                      const isActive = selectedCategory === item;
                      return (
                        <Pressable
                          style={[
                            styles.categoryChip,
                            isActive && styles.categoryChipActive,
                          ]}
                          onPress={() => setSelectedCategory(item)}
                        >
                          <Text
                            style={[
                              styles.categoryChipText,
                              isActive && styles.categoryChipTextActive,
                            ]}
                          >
                            {item}
                          </Text>
                        </Pressable>
                      );
                    }}
                  />
                </View>

                {/* Units List */}
                <FlatList
                  data={filteredUnits}
                  keyExtractor={(item) => item.id || item.code}
                  contentContainerStyle={styles.unitsList}
                  renderItem={({ item }) => {
                    const isSelected =
                      selectedUnit?.code === item.code ||
                      value?.toLowerCase() === item.code.toLowerCase() ||
                      value?.toLowerCase() === item.symbol.toLowerCase();

                    return (
                      <Pressable
                        style={[
                          styles.unitItem,
                          isSelected && styles.unitItemActive,
                        ]}
                        onPress={() => handleSelect(item)}
                      >
                        <View style={styles.unitItemLeft}>
                          <View
                            style={[
                              styles.unitBadge,
                              isSelected && styles.unitBadgeActive,
                            ]}
                          >
                            <Text
                              style={[
                                styles.unitBadgeText,
                                isSelected && styles.unitBadgeTextActive,
                              ]}
                            >
                              {item.code}
                            </Text>
                          </View>

                          <View style={styles.unitDetails}>
                            <Text
                              style={[
                                styles.unitName,
                                isSelected && styles.unitNameActive,
                              ]}
                            >
                              {item.name}
                            </Text>
                            <Text style={styles.unitCategory}>
                              {item.category} · Symbol: {item.symbol}
                            </Text>
                          </View>
                        </View>

                        {isSelected && (
                          <Ionicons
                            name="checkmark-circle"
                            size={22}
                            color={colors.primary || '#0284C7'}
                          />
                        )}
                      </Pressable>
                    );
                  }}
                  ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                      <Ionicons
                        name="flask-outline"
                        size={36}
                        color="#94A3B8"
                      />
                      <Text style={styles.emptyText}>No matching units found</Text>
                    </View>
                  }
                />

                {/* Footer action to add custom */}
                <View style={styles.modalFooter}>
                  <Pressable
                    style={styles.addCustomBtn}
                    onPress={() => setShowAddCustom(true)}
                  >
                    <Ionicons
                      name="add-circle-outline"
                      size={18}
                      color={colors.primary || '#0284C7'}
                    />
                    <Text style={styles.addCustomBtnText}>
                      + Define Custom Unit
                    </Text>
                  </Pressable>
                </View>
              </>
            ) : (
              /* Custom Unit Creator Form */
              <View style={styles.customForm}>
                <Text style={styles.customFormHeader}>Add New Unit</Text>

                <Text style={styles.inputLabel}>Unit Code (e.g. DRUM) *</Text>
                <TextInput
                  style={styles.textInput}
                  value={customCode}
                  onChangeText={setCustomCode}
                  placeholder="e.g. BOX, DRUM, MTR"
                  autoCapitalize="characters"
                />

                <Text style={styles.inputLabel}>Unit Full Name *</Text>
                <TextInput
                  style={styles.textInput}
                  value={customName}
                  onChangeText={setCustomName}
                  placeholder="e.g. 200L Industrial Drum"
                />

                <Text style={styles.inputLabel}>Symbol / Abbreviation</Text>
                <TextInput
                  style={styles.textInput}
                  value={customSymbol}
                  onChangeText={setCustomSymbol}
                  placeholder="e.g. drum"
                />

                <Text style={styles.inputLabel}>Category</Text>
                <View style={styles.categorySelectRow}>
                  {(['Count', 'Weight', 'Volume', 'Packaging', 'Length'] as UnitCategory[]).map(
                    (cat) => (
                      <Pressable
                        key={cat}
                        style={[
                          styles.catSelectChip,
                          customCategory === cat && styles.catSelectChipActive,
                        ]}
                        onPress={() => setCustomCategory(cat)}
                      >
                        <Text
                          style={[
                            styles.catSelectChipText,
                            customCategory === cat && styles.catSelectChipTextActive,
                          ]}
                        >
                          {cat}
                        </Text>
                      </Pressable>
                    ),
                  )}
                </View>

                <View style={styles.customFormActions}>
                  <Pressable
                    style={styles.cancelCustomBtn}
                    onPress={() => setShowAddCustom(false)}
                  >
                    <Text style={styles.cancelCustomBtnText}>Cancel</Text>
                  </Pressable>
                  <Pressable
                    style={[
                      styles.saveCustomBtn,
                      savingCustom && { opacity: 0.6 },
                    ]}
                    onPress={handleSaveCustom}
                    disabled={savingCustom}
                  >
                    <Text style={styles.saveCustomBtnText}>
                      {savingCustom ? 'Saving...' : 'Save & Select'}
                    </Text>
                  </Pressable>
                </View>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 4,
  },
  label: {
    ...typography.label,
    fontSize: 13,
    fontWeight: '600',
    color: '#334155',
    marginBottom: 6,
  },
  requiredStar: {
    color: colors.danger || '#DC2626',
  },
  trigger: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    minHeight: 44,
  },
  triggerDisabled: {
    backgroundColor: '#F1F5F9',
    borderColor: '#E2E8F0',
  },
  triggerError: {
    borderColor: colors.danger || '#DC2626',
  },
  triggerContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  selectedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  selectedCode: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0F172A',
    backgroundColor: '#F0F9FF',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  selectedName: {
    fontSize: 14,
    color: '#475569',
    fontWeight: '500',
  },
  placeholderText: {
    fontSize: 14,
    color: '#94A3B8',
  },
  errorText: {
    ...typography.caption,
    color: colors.danger || '#DC2626',
    marginTop: 4,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '85%',
    paddingBottom: 24,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#0F172A',
  },
  modalSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  closeBtn: {
    padding: 6,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 10,
    marginHorizontal: spacing.lg,
    marginTop: spacing.md,
    paddingHorizontal: 10,
    paddingVertical: 8,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: '#0F172A',
    padding: 0,
  },
  categoryScroll: {
    marginTop: spacing.sm,
  },
  categoryList: {
    paddingHorizontal: spacing.lg,
    gap: 8,
  },
  categoryChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
  },
  categoryChipActive: {
    backgroundColor: colors.primary || '#0284C7',
  },
  categoryChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  categoryChipTextActive: {
    color: '#FFFFFF',
  },
  unitsList: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    gap: 8,
  },
  unitItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    backgroundColor: '#FFFFFF',
  },
  unitItemActive: {
    borderColor: colors.primary || '#0284C7',
    backgroundColor: '#F0F9FF',
  },
  unitItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  unitBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#F1F5F9',
    minWidth: 46,
    alignItems: 'center',
  },
  unitBadgeActive: {
    backgroundColor: colors.primary || '#0284C7',
  },
  unitBadgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#334155',
  },
  unitBadgeTextActive: {
    color: '#FFFFFF',
  },
  unitDetails: {
    flex: 1,
  },
  unitName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#0F172A',
  },
  unitNameActive: {
    color: '#0369A1',
  },
  unitCategory: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 32,
    gap: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#64748B',
  },
  modalFooter: {
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.xs,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  addCustomBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 10,
  },
  addCustomBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.primary || '#0284C7',
  },
  customForm: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
  },
  customFormHeader: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: spacing.md,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
    marginBottom: 4,
    marginTop: 8,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    color: '#0F172A',
    backgroundColor: '#FFFFFF',
  },
  categorySelectRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 6,
    marginBottom: 16,
  },
  catSelectChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    backgroundColor: '#F8FAFC',
  },
  catSelectChipActive: {
    backgroundColor: colors.primary || '#0284C7',
    borderColor: colors.primary || '#0284C7',
  },
  catSelectChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
  },
  catSelectChipTextActive: {
    color: '#FFFFFF',
  },
  customFormActions: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 12,
  },
  cancelCustomBtn: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    backgroundColor: '#F8FAFC',
  },
  cancelCustomBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#475569',
  },
  saveCustomBtn: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderRadius: 8,
    backgroundColor: colors.primary || '#0284C7',
  },
  saveCustomBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});
