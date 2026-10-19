import { Ionicons } from '@expo/vector-icons';
import { useCallback, useMemo, useState } from 'react';
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
import { Screen } from '../../components/common/Screen';
import { SearchField } from '../../components/common/SearchField';
import {
  createMaterial,
  deleteMaterial,
  listMaterials,
  updateMaterial,
} from '../../database/repositories/materialRepository';
import {
  listStockTransactions,
  recordStockMovement,
} from '../../database/repositories/stockTransactionRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors, spacing, typography } from '../../theme';
import type {
  MaterialRow,
  StockTransactionRow,
  StockTransactionType,
} from '../../types/database';
import { formatDateTime, formatNumber } from '../../utils/format';

import { useRoute } from '@react-navigation/native';
import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Tab = 'raw' | 'ledger';
type UpdateStockMode = 'IN' | 'OUT' | 'SET';

export function StockHomeScreen() {
  const route = useRoute<any>();
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [tab, setTab] = useState<Tab>('raw');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);

  const [materials, setMaterials] = useState<MaterialRow[]>([]);
  const [transactions, setTransactions] = useState<StockTransactionRow[]>([]);

  // Modals for Stock Update
  const [showMoveModal, setShowMoveModal] = useState(false);
  const [updateMode, setUpdateMode] = useState<UpdateStockMode>('IN');
  const [selectedMatId, setSelectedMatId] = useState('');
  const [moveQty, setMoveQty] = useState('');
  const [batchLot, setBatchLot] = useState('');
  const [moveNotes, setMoveNotes] = useState('');

  // Modals for Material Create / Edit
  const [showItemModal, setShowItemModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [itemMatId, setItemMatId] = useState('');
  const [itemCode, setItemCode] = useState('');
  const [itemName, setItemName] = useState('');
  const [itemCategory, setItemCategory] = useState('RAW_MATERIAL');
  const [itemUnit, setItemUnit] = useState('pcs');
  const [itemOpeningStock, setItemOpeningStock] = useState('0');
  const [itemMinStock, setItemMinStock] = useState('0');
  const [itemMaxStock, setItemMaxStock] = useState('1000');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [mats, txs] = await Promise.all([
        listMaterials({ search }),
        listStockTransactions({ limit: 40 }),
      ]);
      setMaterials(mats);
      setTransactions(txs);
      if (mats.length > 0 && !selectedMatId) {
        setSelectedMatId(mats[0].id);
      }
    } finally {
      setLoading(false);
    }
  }, [search, selectedMatId]);

  useLiveQuery(loadData);

  const selectedMaterial = useMemo(
    () => materials.find((m) => m.id === selectedMatId) ?? materials[0] ?? null,
    [materials, selectedMatId],
  );

  const previewNewStock = useMemo(() => {
    if (!selectedMaterial) return 0;
    const qty = parseFloat(moveQty);
    if (isNaN(qty)) return selectedMaterial.current_stock;
    if (updateMode === 'SET') return Math.max(0, qty);
    if (updateMode === 'IN') return selectedMaterial.current_stock + qty;
    if (updateMode === 'OUT') return Math.max(0, selectedMaterial.current_stock - qty);
    return selectedMaterial.current_stock;
  }, [selectedMaterial, moveQty, updateMode]);

  const openUpdateStockModal = (matId?: string) => {
    if (matId) {
      setSelectedMatId(matId);
    } else if (materials.length > 0 && !selectedMatId) {
      setSelectedMatId(materials[0].id);
    }
    setUpdateMode('IN');
    setMoveQty('');
    setBatchLot('');
    setMoveNotes('');
    setShowMoveModal(true);
  };

  const handleRecordMovement = async () => {
    if (!selectedMaterial) {
      Alert.alert('Invalid Selection', 'Please select a material.');
      return;
    }
    const qty = parseFloat(moveQty);
    if (isNaN(qty) || (qty <= 0 && updateMode !== 'SET')) {
      Alert.alert('Invalid Input', 'Please enter a valid positive quantity.');
      return;
    }

    try {
      let finalMoveType: StockTransactionType = 'IN';
      let deltaQty = qty;

      if (updateMode === 'IN') {
        finalMoveType = 'IN';
        deltaQty = qty;
      } else if (updateMode === 'OUT') {
        finalMoveType = 'OUT';
        deltaQty = qty;
      } else if (updateMode === 'SET') {
        const diff = qty - selectedMaterial.current_stock;
        if (diff === 0) {
          Alert.alert('No Change', 'Entered balance matches current stock.');
          return;
        }
        finalMoveType = diff > 0 ? 'IN' : 'OUT';
        deltaQty = Math.abs(diff);
      }

      await recordStockMovement({
        material_id: selectedMaterial.id,
        transaction_type: finalMoveType,
        category: 'RAW_MATERIAL',
        quantity: deltaQty,
        batch_lot: batchLot,
        notes:
          moveNotes ||
          (updateMode === 'SET'
            ? `Stock count balance adjusted to ${qty} ${selectedMaterial.unit}`
            : `Stock ${updateMode} recorded`),
      });

      setShowMoveModal(false);
      setMoveQty('');
      setBatchLot('');
      setMoveNotes('');
      Alert.alert('Success', `Stock updated for ${selectedMaterial.name}.`);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Movement failed');
    }
  };

  const openCreateMaterial = () => {
    setIsEditMode(false);
    setItemMatId('');
    setItemCode('');
    setItemName('');
    setItemCategory('RAW_MATERIAL');
    setItemUnit('pcs');
    setItemOpeningStock('0');
    setItemMinStock('10');
    setItemMaxStock('500');
    setShowItemModal(true);
  };

  const openEditMaterial = (item: MaterialRow) => {
    setIsEditMode(true);
    setItemMatId(item.id);
    setItemCode(item.code);
    setItemName(item.name);
    setItemCategory(item.category);
    setItemUnit(item.unit);
    setItemOpeningStock(String(item.current_stock ?? 0));
    setItemMinStock(String(item.minimum_stock ?? 0));
    setItemMaxStock(String(item.maximum_stock ?? 0));
    setShowItemModal(true);
  };

  const handleSaveItem = async () => {
    if (!itemCode.trim() || !itemName.trim()) {
      Alert.alert('Required Fields', 'Item code and item name are required.');
      return;
    }
    const minVal = parseFloat(itemMinStock) || 0;
    const maxVal = parseFloat(itemMaxStock) || 0;
    const openingStock = parseFloat(itemOpeningStock) || 0;

    try {
      if (isEditMode) {
        await updateMaterial({
          id: itemMatId,
          code: itemCode,
          name: itemName,
          category: itemCategory,
          unit: itemUnit,
          minimum_stock: minVal,
          maximum_stock: maxVal,
        });
        Alert.alert('Success', `Updated "${itemName}".`);
      } else {
        const newMat = await createMaterial({
          code: itemCode,
          name: itemName,
          category: itemCategory,
          unit: itemUnit,
          current_stock: 0,
          minimum_stock: minVal,
          maximum_stock: maxVal,
        });
        if (openingStock > 0) {
          await recordStockMovement({
            material_id: newMat.id,
            transaction_type: 'IN',
            category: 'RAW_MATERIAL',
            quantity: openingStock,
            notes: 'Initial opening stock intake',
          });
        }
        Alert.alert('Success', `Created material "${itemName}".`);
      }
      setShowItemModal(false);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Save Failed', e instanceof Error ? e.message : 'Could not save material.');
    }
  };

  const handleDeleteMaterial = (item: MaterialRow) => {
    Alert.alert(
      'Delete Material',
      `Are you sure you want to delete "${item.name}" (${item.code})?\n\nThis will remove the item and its ledger history. This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteMaterial(item.id);
              Alert.alert('Deleted', `"${item.name}" has been removed from inventory.`);
              await loadData();
            } catch (e: unknown) {
              Alert.alert(
                'Cannot Delete',
                e instanceof Error ? e.message : 'Could not delete material.',
              );
            }
          },
        },
      ],
    );
  };

  return (
    <Screen>
      {isViewOnly && (
        <ViewModeBanner
          message="Inventory monitoring mode. Adding items, updating stock, and modifying inventory are disabled. Use the Management tab to make changes."
        />
      )}

      {/* Segment switcher */}
      <View style={styles.segmentContainer}>
        <Pressable
          style={[styles.segmentBtn, tab === 'raw' && styles.segmentBtnActive]}
          onPress={() => setTab('raw')}
        >
          <Text style={[styles.segmentText, tab === 'raw' && styles.segmentTextActive]}>
            Raw & Components ({materials.length})
          </Text>
        </Pressable>
        <Pressable
          style={[styles.segmentBtn, tab === 'ledger' && styles.segmentBtnActive]}
          onPress={() => setTab('ledger')}
        >
          <Text style={[styles.segmentText, tab === 'ledger' && styles.segmentTextActive]}>
            Ledger
          </Text>
        </Pressable>
      </View>

      {/* Action Header */}
      <View style={styles.actionRow}>
        {tab !== 'ledger' ? (
          <View style={{ flex: 1 }}>
            <SearchField
              value={search}
              onChangeText={setSearch}
              placeholder="Search items by code/name..."
            />
          </View>
        ) : (
          <Text style={typography.h2}>Inventory Transactions</Text>
        )}
        {!isViewOnly && (
          <View style={{ flexDirection: 'row', gap: 6 }}>
            {tab === 'raw' && (
              <Button
                label="+ Add Item"
                variant="secondary"
                onPress={openCreateMaterial}
                style={{ paddingHorizontal: 10 }}
              />
            )}
            <Button
              label="Update Stock"
              onPress={() => openUpdateStockModal()}
              style={{ paddingHorizontal: 12 }}
            />
          </View>
        )}
      </View>

      {/* Content */}
      {tab === 'raw' ? (
        <FlatList
          data={materials}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No materials found</Text>
            </View>
          }
          renderItem={({ item }) => {
            const isLow = item.current_stock <= item.minimum_stock;
            return (
              <Card style={styles.cardItem}>
                <View style={styles.cardHeader}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.cardTitle}>{item.name}</Text>
                    <Text style={styles.cardSubtitle}>
                      {item.code} • {item.category}
                    </Text>
                  </View>
                  <View
                    style={[
                      styles.badge,
                      { backgroundColor: isLow ? colors.dangerBg : colors.successBg },
                    ]}
                  >
                    <Text
                      style={[
                        styles.badgeText,
                        { color: isLow ? colors.danger : colors.success },
                      ]}
                    >
                      {isLow ? 'LOW STOCK' : 'AVAILABLE'}
                    </Text>
                  </View>
                </View>

                <View style={styles.stockNumbersRow}>
                  <View>
                    <Text style={styles.stockLabel}>Current Stock</Text>
                    <Text style={[styles.stockValue, isLow && { color: colors.danger }]}>
                      {formatNumber(item.current_stock)} {item.unit}
                    </Text>
                  </View>
                  <View>
                    <Text style={styles.stockLabel}>Min Required</Text>
                    <Text style={styles.stockValue}>
                      {formatNumber(item.minimum_stock)} {item.unit}
                    </Text>
                  </View>
                  <View>
                    <Text style={styles.stockLabel}>Max Cap</Text>
                    <Text style={styles.stockValue}>
                      {formatNumber(item.maximum_stock)} {item.unit}
                    </Text>
                  </View>
                </View>

                {/* Actions: Edit, Delete, Update Stock (Hidden in viewOnly mode) */}
                {!isViewOnly && (
                  <View style={styles.cardActionRow}>
                    <View style={styles.cardActionLeft}>
                      <Pressable
                        style={styles.cardEditBtn}
                        onPress={() => openEditMaterial(item)}
                      >
                        <Ionicons name="pencil" size={13} color={colors.primary} />
                        <Text style={styles.cardEditBtnText}>Edit</Text>
                      </Pressable>
                      <Pressable
                        style={styles.cardDeleteBtn}
                        onPress={() => handleDeleteMaterial(item)}
                      >
                        <Ionicons name="trash-outline" size={13} color={colors.danger} />
                        <Text style={styles.cardDeleteBtnText}>Delete</Text>
                      </Pressable>
                    </View>

                    <Pressable
                      style={styles.cardUpdateBtn}
                      onPress={() => openUpdateStockModal(item.id)}
                    >
                      <Ionicons name="swap-vertical" size={14} color="#0A1E38" />
                      <Text style={styles.cardUpdateBtnText}>Update Stock</Text>
                    </Pressable>
                  </View>
                )}
              </Card>
            );
          }}
        />
      ) : (
        <FlatList
          data={transactions}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No stock transactions in ledger</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View>
                  <Text style={styles.cardTitle}>
                    {item.material_name || item.product_name || 'Inventory Item'}
                  </Text>
                  <Text style={styles.cardSubtitle}>
                    {formatDateTime(item.created_at)} • {item.reference_type || 'MANUAL'}
                  </Text>
                </View>
                <View
                  style={[
                    styles.badge,
                    {
                      backgroundColor:
                        item.transaction_type === 'IN' ? colors.successBg : colors.dangerBg,
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.badgeText,
                      {
                        color:
                          item.transaction_type === 'IN' ? colors.success : colors.danger,
                      },
                    ]}
                  >
                    {item.transaction_type === 'IN' ? '+' : '-'} {item.quantity}
                  </Text>
                </View>
              </View>
              {item.notes ? (
                <Text style={{ fontSize: 12, color: colors.textSecondary, marginTop: 4 }}>
                  Notes: {item.notes}
                </Text>
              ) : null}
            </Card>
          )}
        />
      )}

      {/* Unified Update Stock Modal */}
      <Modal visible={showMoveModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Ionicons name="swap-vertical" size={20} color="#0A1E38" />
                <Text style={typography.h2}>Update Stock</Text>
              </View>
              <Pressable onPress={() => setShowMoveModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>
            <ScrollView style={{ maxHeight: 440 }}>
              {/* Selected Material Summary Card */}
              {selectedMaterial && (
                <View style={styles.modalMatSummary}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.modalMatTitle}>{selectedMaterial.name}</Text>
                    <Text style={styles.modalMatSub}>
                      {selectedMaterial.code} • {selectedMaterial.category}
                    </Text>
                  </View>
                  <View style={styles.modalMatStockBadge}>
                    <Text style={styles.modalMatStockLabel}>Current</Text>
                    <Text style={styles.modalMatStockValue}>
                      {formatNumber(selectedMaterial.current_stock)} {selectedMaterial.unit}
                    </Text>
                  </View>
                </View>
              )}

              {/* Mode Switcher: Add (IN), Deduct (OUT), Set Exact (SET) */}
              <Text style={styles.inputLabel}>Adjustment Action *</Text>
              <View style={styles.modalModeRow}>
                <Pressable
                  style={[styles.modalModeBtn, updateMode === 'IN' && styles.modalModeBtnActive]}
                  onPress={() => setUpdateMode('IN')}
                >
                  <Ionicons
                    name="arrow-down-circle-outline"
                    size={16}
                    color={updateMode === 'IN' ? '#FFFFFF' : colors.success}
                  />
                  <Text style={[styles.modalModeBtnText, updateMode === 'IN' && styles.modalModeBtnTextActive]}>
                    + Add (In)
                  </Text>
                </Pressable>

                <Pressable
                  style={[styles.modalModeBtn, updateMode === 'OUT' && styles.modalModeBtnActiveDanger]}
                  onPress={() => setUpdateMode('OUT')}
                >
                  <Ionicons
                    name="arrow-up-circle-outline"
                    size={16}
                    color={updateMode === 'OUT' ? '#FFFFFF' : colors.danger}
                  />
                  <Text style={[styles.modalModeBtnText, updateMode === 'OUT' && styles.modalModeBtnTextActive]}>
                    - Deduct (Out)
                  </Text>
                </Pressable>

                <Pressable
                  style={[styles.modalModeBtn, updateMode === 'SET' && styles.modalModeBtnActivePrimary]}
                  onPress={() => setUpdateMode('SET')}
                >
                  <Ionicons
                    name="swap-horizontal-outline"
                    size={16}
                    color={updateMode === 'SET' ? '#FFFFFF' : colors.primary}
                  />
                  <Text style={[styles.modalModeBtnText, updateMode === 'SET' && styles.modalModeBtnTextActive]}>
                    = Set Exact
                  </Text>
                </Pressable>
              </View>

              {/* Material Switcher Carousel */}
              <Text style={styles.inputLabel}>Select Material Item</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 10 }}>
                {materials.map((m) => (
                  <Pressable
                    key={m.id}
                    style={[styles.chip, selectedMatId === m.id && styles.chipActive]}
                    onPress={() => setSelectedMatId(m.id)}
                  >
                    <Text style={[styles.chipText, selectedMatId === m.id && styles.chipTextActive]}>
                      {m.name}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>

              {/* Quantity Input */}
              <Text style={styles.inputLabel}>
                {updateMode === 'SET' ? 'New Target Stock Balance *' : 'Quantity *'}
              </Text>
              <TextInput
                style={styles.input}
                placeholder={updateMode === 'SET' ? 'e.g. 500' : 'e.g. 100'}
                keyboardType="numeric"
                value={moveQty}
                onChangeText={setMoveQty}
              />

              {/* Dynamic Balance Preview */}
              {selectedMaterial && moveQty.trim() !== '' && !isNaN(parseFloat(moveQty)) && (
                <View style={styles.balancePreviewBox}>
                  <Text style={styles.balancePreviewLabel}>Resulting Stock Level:</Text>
                  <Text style={styles.balancePreviewValue}>
                    {formatNumber(previewNewStock)} {selectedMaterial.unit}
                    {updateMode !== 'SET' && (
                      <Text style={{ fontSize: 11, fontWeight: 'normal', color: colors.textSecondary }}>
                        {' '}({updateMode === 'IN' ? '+' : '-'}{moveQty})
                      </Text>
                    )}
                  </Text>
                </View>
              )}

              <Text style={styles.inputLabel}>Batch / Lot Number (Optional)</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. LOT-2026-B1"
                value={batchLot}
                onChangeText={setBatchLot}
              />

              <Text style={styles.inputLabel}>Purpose / Reason</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Physical inventory audit / Workshop intake"
                value={moveNotes}
                onChangeText={setMoveNotes}
              />
            </ScrollView>

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowMoveModal(false)} />
              <Button
                label="Confirm Stock Update"
                onPress={handleRecordMovement}
              />
            </View>
          </View>
        </View>
      </Modal>

      {/* Add / Edit Material Item Modal */}
      <Modal visible={showItemModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Ionicons
                  name={isEditMode ? 'create-outline' : 'cube-outline'}
                  size={20}
                  color={colors.primary}
                />
                <Text style={typography.h2}>
                  {isEditMode ? 'Edit Material Item' : 'New Material Item'}
                </Text>
              </View>
              <Pressable onPress={() => setShowItemModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView style={{ maxHeight: 420 }}>
              <View style={{ flexDirection: 'row', gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.inputLabel}>Code *</Text>
                  <TextInput
                    style={styles.input}
                    value={itemCode}
                    onChangeText={setItemCode}
                    placeholder="e.g. MAT-010"
                    autoCapitalize="characters"
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.inputLabel}>Unit *</Text>
                  <TextInput
                    style={styles.input}
                    value={itemUnit}
                    onChangeText={setItemUnit}
                    placeholder="e.g. kg, pcs, m"
                  />
                </View>
              </View>

              <Text style={styles.inputLabel}>Material Name *</Text>
              <TextInput
                style={styles.input}
                value={itemName}
                onChangeText={setItemName}
                placeholder="e.g. Steel Pipe 50mm"
              />

              <Text style={styles.inputLabel}>Category</Text>
              <TextInput
                style={styles.input}
                value={itemCategory}
                onChangeText={setItemCategory}
                placeholder="e.g. RAW_MATERIAL, FASTENER, CHEMICAL"
              />

              {!isEditMode && (
                <>
                  <Text style={styles.inputLabel}>Initial Stock Balance</Text>
                  <TextInput
                    style={styles.input}
                    keyboardType="numeric"
                    value={itemOpeningStock}
                    onChangeText={setItemOpeningStock}
                    placeholder="0"
                  />
                </>
              )}

              <View style={{ flexDirection: 'row', gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.inputLabel}>Min Stock (Alert)</Text>
                  <TextInput
                    style={styles.input}
                    keyboardType="numeric"
                    value={itemMinStock}
                    onChangeText={setItemMinStock}
                    placeholder="0"
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.inputLabel}>Max Stock Cap</Text>
                  <TextInput
                    style={styles.input}
                    keyboardType="numeric"
                    value={itemMaxStock}
                    onChangeText={setItemMaxStock}
                    placeholder="1000"
                  />
                </View>
              </View>
            </ScrollView>

            <View style={styles.modalActions}>
              <Button
                label="Cancel"
                variant="secondary"
                onPress={() => setShowItemModal(false)}
              />
              <Button
                label={isEditMode ? 'Save Changes' : 'Create Item'}
                onPress={handleSaveItem}
              />
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  segmentContainer: {
    flexDirection: 'row',
    backgroundColor: '#E2E8F0',
    borderRadius: 12,
    padding: 3,
    marginBottom: spacing.md,
  },
  segmentBtn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 9,
  },
  segmentBtnActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 3,
    elevation: 2,
  },
  segmentText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
  },
  segmentTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  cardItem: {
    marginBottom: spacing.sm,
    padding: spacing.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  cardSubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  stockNumbersRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  stockLabel: {
    fontSize: 11,
    color: colors.textMuted,
    fontWeight: '600',
  },
  stockValue: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
    marginTop: 2,
  },
  cardActionRow: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardActionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  cardEditBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 7,
    paddingVertical: 5,
    paddingHorizontal: 10,
  },
  cardEditBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0A1E38',
  },
  cardDeleteBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FECACA',
    borderRadius: 7,
    paddingVertical: 5,
    paddingHorizontal: 10,
  },
  cardDeleteBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.danger,
  },
  cardUpdateBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 7,
    paddingVertical: 5,
    paddingHorizontal: 10,
  },
  cardUpdateBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0369A1',
  },
  empty: {
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    color: colors.textMuted,
    fontSize: 15,
  },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
    marginRight: 6,
  },
  chipActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  chipText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  chipTextActive: {
    color: colors.surface,
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
  modalMatSummary: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    padding: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 8,
  },
  modalMatTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
  modalMatSub: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  modalMatStockBadge: {
    alignItems: 'flex-end',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  modalMatStockLabel: {
    fontSize: 10,
    color: colors.textMuted,
    fontWeight: '600',
  },
  modalMatStockValue: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.primary,
  },
  modalModeRow: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 6,
  },
  modalModeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  modalModeBtnActive: {
    backgroundColor: colors.success,
    borderColor: colors.success,
  },
  modalModeBtnActiveDanger: {
    backgroundColor: colors.danger,
    borderColor: colors.danger,
  },
  modalModeBtnActivePrimary: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  modalModeBtnText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.text,
  },
  modalModeBtnTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  balancePreviewBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    padding: 8,
    marginTop: 8,
    marginBottom: 4,
  },
  balancePreviewLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#0369A1',
  },
  balancePreviewValue: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.primaryDark,
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
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
});
