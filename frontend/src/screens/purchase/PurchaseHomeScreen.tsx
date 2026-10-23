import { Ionicons } from '@expo/vector-icons';
import { useCallback, useState } from 'react';
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
import { listMaterials } from '../../api/repositories/materialRepository';
import {
  createPurchaseOrder,
  createPurchaseRequest,
  deleteGrnReceipt,
  deletePurchaseOrder,
  deletePurchaseRequest,
  getPurchaseOrderItems,
  listGrnReceipts,
  listPurchaseOrders,
  listPurchaseRequests,
  receiveGrn,
  updatePurchaseRequestStatus,
} from '../../api/repositories/purchaseRepository';
import { listSuppliers } from '../../api/repositories/supplierRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors, spacing, typography } from '../../theme';
import type {
  GrnReceiptRow,
  MaterialRow,
  PurchaseOrderItemRow,
  PurchaseOrderRow,
  PurchaseRequestRow,
  SupplierRow,
} from '../../types/database';
import { formatNumber } from '../../utils/format';

type Tab = 'requests' | 'orders' | 'grn';

export function PurchaseHomeScreen() {
  const [tab, setTab] = useState<Tab>('orders');
  const [loading, setLoading] = useState(false);

  const [requests, setRequests] = useState<PurchaseRequestRow[]>([]);
  const [orders, setOrders] = useState<PurchaseOrderRow[]>([]);
  const [grnList, setGrnList] = useState<GrnReceiptRow[]>([]);
  const [materials, setMaterials] = useState<MaterialRow[]>([]);
  const [suppliers, setSuppliers] = useState<SupplierRow[]>([]);

  // Modals
  const [showRequestModal, setShowRequestModal] = useState(false);
  const [showPoModal, setShowPoModal] = useState(false);
  const [showGrnModal, setShowGrnModal] = useState(false);

  // Request Form
  const [reqMatId, setReqMatId] = useState('');
  const [reqQty, setReqQty] = useState('');
  const [reqReason, setReqReason] = useState('');

  // PO Form
  const [poSupplierId, setPoSupplierId] = useState('');
  const [poMatId, setPoMatId] = useState('');
  const [poQty, setPoQty] = useState('');
  const [poRate, setPoRate] = useState('');
  const [poTerms, setPoTerms] = useState('');

  // GRN Receipt
  const [grnMode, setGrnMode] = useState<'po' | 'direct'>('direct');
  const [activePo, setActivePo] = useState<PurchaseOrderRow | null>(null);
  const [poItems, setPoItems] = useState<PurchaseOrderItemRow[]>([]);
  const [receivedQtyMap, setReceivedQtyMap] = useState<Record<string, string>>({});
  const [invoiceNumber, setInvoiceNumber] = useState('');
  const [grnSupplierId, setGrnSupplierId] = useState('');
  const [grnMaterialId, setGrnMaterialId] = useState('');
  const [grnDirectQty, setGrnDirectQty] = useState('');
  const [grnNotes, setGrnNotes] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [reqs, pos, grns, mats, supps] = await Promise.all([
        listPurchaseRequests(),
        listPurchaseOrders(),
        listGrnReceipts(),
        listMaterials(),
        listSuppliers(),
      ]);
      setRequests(reqs);
      setOrders(pos);
      setGrnList(grns);
      setMaterials(mats);
      setSuppliers(supps);
      if (mats.length > 0 && !reqMatId) setReqMatId(mats[0].id);
      if (mats.length > 0 && !poMatId) setPoMatId(mats[0].id);
      if (supps.length > 0 && !poSupplierId) setPoSupplierId(supps[0].id);
      if (supps.length > 0 && !grnSupplierId) setGrnSupplierId(supps[0].id);
      if (mats.length > 0 && !grnMaterialId) setGrnMaterialId(mats[0].id);
    } finally {
      setLoading(false);
    }
  }, [reqMatId, poMatId, poSupplierId, grnSupplierId, grnMaterialId]);

  useLiveQuery(loadData);

  const handleCreateRequest = async () => {
    const qty = parseFloat(reqQty);
    if (!reqMatId || isNaN(qty) || qty <= 0) {
      Alert.alert('Invalid Input', 'Please select a material and enter a valid quantity.');
      return;
    }
    try {
      await createPurchaseRequest({
        material_id: reqMatId,
        quantity: qty,
        required_by_date: Date.now() + 7 * 86400000,
        reason: reqReason,
      });
      setShowRequestModal(false);
      setReqQty('');
      setReqReason('');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create request');
    }
  };

  const handleCreatePo = async () => {
    const qty = parseFloat(poQty);
    const rate = parseFloat(poRate);
    if (!poSupplierId || !poMatId || isNaN(qty) || isNaN(rate) || qty <= 0 || rate <= 0) {
      Alert.alert('Invalid Input', 'Please fill supplier, material, quantity, and rate.');
      return;
    }
    try {
      await createPurchaseOrder({
        supplier_id: poSupplierId,
        expected_date: Date.now() + 5 * 86400000,
        terms: poTerms,
        items: [
          {
            material_id: poMatId,
            quantity: qty,
            unit_rate: rate,
            tax_pct: 18,
          },
        ],
      });
      setShowPoModal(false);
      setPoQty('');
      setPoRate('');
      setPoTerms('');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create PO');
    }
  };

  const handleOpenGrn = async (po: PurchaseOrderRow) => {
    setGrnMode('po');
    setActivePo(po);
    const items = await getPurchaseOrderItems(po.id);
    setPoItems(items);
    const map: Record<string, string> = {};
    for (const item of items) {
      const remaining = Math.max(0, (item.quantity || 0) - (item.received_quantity || 0));
      map[item.material_id] = String(remaining);
    }
    setReceivedQtyMap(map);
    setInvoiceNumber('');
    setGrnNotes('');
    setShowGrnModal(true);
  };

  const handleOpenDirectGrn = () => {
    setGrnMode('direct');
    setActivePo(null);
    setPoItems([]);
    setReceivedQtyMap({});
    setInvoiceNumber('');
    setGrnNotes('');
    setGrnDirectQty('');
    if (suppliers.length > 0 && !grnSupplierId) setGrnSupplierId(suppliers[0].id);
    if (materials.length > 0 && !grnMaterialId) setGrnMaterialId(materials[0].id);
    setShowGrnModal(true);
  };

  const handleSelectPoForGrn = async (po: PurchaseOrderRow) => {
    setActivePo(po);
    const items = await getPurchaseOrderItems(po.id);
    setPoItems(items);
    const map: Record<string, string> = {};
    for (const item of items) {
      const remaining = Math.max(0, (item.quantity || 0) - (item.received_quantity || 0));
      map[item.material_id] = String(remaining);
    }
    setReceivedQtyMap(map);
  };

  const handleProcessGrn = async () => {
    try {
      if (grnMode === 'direct') {
        const qty = parseFloat(grnDirectQty.trim());
        if (!grnMaterialId) {
          Alert.alert('Required', 'Please select a material.');
          return;
        }
        if (isNaN(qty) || qty <= 0) {
          Alert.alert('Invalid Quantity', 'Please enter a valid quantity greater than zero.');
          return;
        }

        await receiveGrn({
          po_id: null,
          supplier_id: grnSupplierId || null,
          invoice_number: invoiceNumber,
          notes: grnNotes,
          received_items: [
            {
              material_id: grnMaterialId,
              received_qty: qty,
            },
          ],
        });

        setShowGrnModal(false);
        Alert.alert('Goods Received', 'Direct material inward processed and stock updated!');
        await loadData();
      } else {
        if (!activePo) {
          Alert.alert('Required', 'Please select a purchase order to receive.');
          return;
        }
        const receivedItems = poItems.map((item) => ({
          material_id: item.material_id,
          received_qty: parseFloat(receivedQtyMap[item.material_id] || '0') || 0,
        }));

        const totalReceived = receivedItems.reduce((acc, it) => acc + it.received_qty, 0);
        if (totalReceived <= 0) {
          Alert.alert('Invalid Quantity', 'Please enter at least one item received quantity > 0.');
          return;
        }

        await receiveGrn({
          po_id: activePo.id,
          supplier_id: activePo.supplier_id,
          invoice_number: invoiceNumber,
          notes: grnNotes,
          received_items: receivedItems,
        });

        setShowGrnModal(false);
        setActivePo(null);
        Alert.alert('GRN Processed', 'Raw material stock updated successfully from PO!');
        await loadData();
      }
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed to process Goods Receipt');
    }
  };

  const handleDeleteGrn = (grn: GrnReceiptRow) => {
    Alert.alert(
      'Revert Goods Receipt',
      `Are you sure you want to revert ${grn.grn_number}? This will reverse the stock addition and update PO status back.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Revert',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteGrnReceipt(grn.id);
              Alert.alert('Reverted', `${grn.grn_number} reverted and stock deducted.`);
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete GRN');
            }
          },
        },
      ],
    );
  };

  const handleApproveRequest = async (id: string) => {
    try {
      await updatePurchaseRequestStatus(id, 'APPROVED');
      Alert.alert('Approved', 'Purchase request marked as APPROVED.');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not approve request');
    }
  };

  const handleRejectRequest = async (id: string) => {
    try {
      await updatePurchaseRequestStatus(id, 'REJECTED');
      Alert.alert('Rejected', 'Purchase request marked as REJECTED.');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not reject request');
    }
  };

  const handleDeleteRequest = (id: string) => {
    Alert.alert(
      'Delete Request',
      'Are you sure you want to delete this purchase request?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deletePurchaseRequest(id);
              Alert.alert('Deleted', 'Purchase request deleted.');
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete request');
            }
          },
        },
      ],
    );
  };

  const handleDeletePo = (po: PurchaseOrderRow) => {
    Alert.alert(
      'Delete Purchase Order',
      `Are you sure you want to delete PO ${po.po_number}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deletePurchaseOrder(po.id);
              Alert.alert('Deleted', `Purchase order ${po.po_number} deleted.`);
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Cannot Delete', e instanceof Error ? e.message : 'Could not delete purchase order');
            }
          },
        },
      ],
    );
  };

  return (
    <Screen scroll={false}>
      {/* Segment Switcher */}
      <View style={styles.segmentContainer}>
        <Pressable
          style={[styles.segmentBtn, tab === 'orders' && styles.segmentBtnActive]}
          onPress={() => setTab('orders')}
        >
          <Text style={[styles.segmentText, tab === 'orders' && styles.segmentTextActive]}>
            Orders ({orders.length})
          </Text>
        </Pressable>
        <Pressable
          style={[styles.segmentBtn, tab === 'requests' && styles.segmentBtnActive]}
          onPress={() => setTab('requests')}
        >
          <Text style={[styles.segmentText, tab === 'requests' && styles.segmentTextActive]}>
            Requests ({requests.length})
          </Text>
        </Pressable>
        <Pressable
          style={[styles.segmentBtn, tab === 'grn' && styles.segmentBtnActive]}
          onPress={() => setTab('grn')}
        >
          <Text style={[styles.segmentText, tab === 'grn' && styles.segmentTextActive]}>
            GRN ({grnList.length})
          </Text>
        </Pressable>
      </View>

      {/* Action Header */}
      <View style={styles.actionRow}>
        <Text style={typography.h2}>
          {tab === 'orders' ? 'Purchase Orders' : tab === 'requests' ? 'Material Requests' : 'Goods Receipts'}
        </Text>
        {tab === 'orders' ? (
          <Button label="+ New PO" onPress={() => setShowPoModal(true)} />
        ) : tab === 'requests' ? (
          <Button label="+ New Request" onPress={() => setShowRequestModal(true)} />
        ) : (
          <Button label="+ Receive Goods" onPress={handleOpenDirectGrn} />
        )}
      </View>

      {/* Content */}
      {tab === 'orders' ? (
        <FlatList
          data={orders}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No purchase orders found</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View>
                  <Text style={styles.cardTitle}>{item.po_number}</Text>
                  <Text style={styles.cardSubtitle}>Vendor: {item.supplier_name}</Text>
                </View>
                <View
                  style={[
                    styles.badge,
                    {
                      backgroundColor:
                        item.status === 'RECEIVED'
                          ? colors.successBg
                          : item.status === 'PARTIALLY_RECEIVED'
                          ? colors.warningBg
                          : colors.infoBg,
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.badgeText,
                      {
                        color:
                          item.status === 'RECEIVED'
                            ? colors.success
                            : item.status === 'PARTIALLY_RECEIVED'
                            ? colors.warning
                            : colors.info,
                      },
                    ]}
                  >
                    {item.status}
                  </Text>
                </View>
              </View>

              <View style={styles.detailRow}>
                <Text style={styles.detailText}>Total: ₹{formatNumber(item.total_amount)}</Text>
                <View style={{ flexDirection: 'row', gap: 6, alignItems: 'center' }}>
                  {item.status !== 'RECEIVED' && (
                    <Button
                      label="Receive GRN"
                      variant="secondary"
                      onPress={() => handleOpenGrn(item)}
                      style={{ paddingVertical: 4, paddingHorizontal: 8 }}
                    />
                  )}
                  {item.status !== 'RECEIVED' && item.status !== 'PARTIALLY_RECEIVED' && (
                    <Pressable
                      style={{
                        padding: 6,
                        borderRadius: 6,
                        borderWidth: 1,
                        borderColor: '#FECACA',
                        backgroundColor: '#FEF2F2',
                      }}
                      onPress={() => handleDeletePo(item)}
                    >
                      <Ionicons name="trash-outline" size={16} color={colors.danger} />
                    </Pressable>
                  )}
                </View>
              </View>
            </Card>
          )}
        />
      ) : tab === 'requests' ? (
        <FlatList
          data={requests}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No pending purchase requests</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.cardTitle}>{item.request_number}</Text>
                  <Text style={styles.cardSubtitle}>
                    {item.material_name} ({item.material_code})
                  </Text>
                </View>
                <View style={{ flexDirection: 'row', gap: 6, alignItems: 'center' }}>
                  <View
                    style={[
                      styles.badge,
                      {
                        backgroundColor:
                          item.status === 'APPROVED'
                            ? colors.successBg
                            : item.status === 'REJECTED'
                            ? '#FEE2E2'
                            : colors.warningBg,
                      },
                    ]}
                  >
                    <Text
                      style={[
                        styles.badgeText,
                        {
                          color:
                            item.status === 'APPROVED'
                              ? colors.success
                              : item.status === 'REJECTED'
                              ? colors.danger
                              : colors.warning,
                        },
                      ]}
                    >
                      {item.status}
                    </Text>
                  </View>
                  <Pressable
                    style={{
                      padding: 6,
                      borderRadius: 6,
                      borderWidth: 1,
                      borderColor: '#FECACA',
                      backgroundColor: '#FEF2F2',
                    }}
                    onPress={() => handleDeleteRequest(item.id)}
                  >
                    <Ionicons name="trash-outline" size={15} color={colors.danger} />
                  </Pressable>
                </View>
              </View>
              <Text style={styles.detailText}>
                Requested Qty: {item.quantity} {item.material_unit}
              </Text>
              {item.reason ? (
                <Text style={[styles.detailText, { color: colors.textMuted }]}>
                  Reason: {item.reason}
                </Text>
              ) : null}

              {item.status === 'PENDING' && (
                <View
                  style={{
                    flexDirection: 'row',
                    gap: 8,
                    marginTop: 8,
                    borderTopWidth: 1,
                    borderTopColor: colors.border,
                    paddingTop: 8,
                  }}
                >
                  <View style={{ flex: 1 }}>
                    <Button
                      label="Approve"
                      onPress={() => handleApproveRequest(item.id)}
                      style={{ paddingVertical: 4 }}
                    />
                  </View>
                  <View style={{ flex: 1 }}>
                    <Button
                      label="Reject"
                      variant="secondary"
                      onPress={() => handleRejectRequest(item.id)}
                      style={{ paddingVertical: 4 }}
                    />
                  </View>
                </View>
              )}
            </Card>
          )}
        />
      ) : (
        <FlatList
          data={grnList}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Ionicons name="receipt-outline" size={40} color={colors.textSecondary} style={{ marginBottom: 8 }} />
              <Text style={styles.emptyText}>No goods receipts recorded</Text>
              <Text style={[styles.detailText, { textAlign: 'center', marginTop: 4, color: colors.textSecondary }]}>
                Inward materials from open purchase orders or record a direct inward entry.
              </Text>
              <Button
                label="+ Receive Goods Now"
                onPress={handleOpenDirectGrn}
                style={{ marginTop: 16 }}
              />
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View style={{ flex: 1 }}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                    <Text style={styles.cardTitle}>{item.grn_number}</Text>
                    <View style={[styles.badge, { backgroundColor: colors.successBg }]}>
                      <Text style={[styles.badgeText, { color: colors.success }]}>RECEIVED</Text>
                    </View>
                  </View>
                  <Text style={styles.grnTimestamp}>
                    {new Date(item.received_date || item.created_at || item.received_at || Date.now()).toLocaleDateString(undefined, {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric',
                    })}{' '}
                    •{' '}
                    {new Date(item.received_date || item.created_at || item.received_at || Date.now()).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </Text>
                </View>
                <Pressable
                  style={styles.deleteIconBtn}
                  onPress={() => handleDeleteGrn(item)}
                  hitSlop={8}
                >
                  <Ionicons name="trash-outline" size={17} color="#EF4444" />
                </Pressable>
              </View>

              <View style={styles.grnMetaRow}>
                <View style={styles.grnMetaItem}>
                  <Ionicons name="business-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.grnMetaText} numberOfLines={1}>
                    {item.supplier_name || 'Vendor Unassigned'}
                  </Text>
                </View>
                {item.po_number ? (
                  <View style={styles.grnPoTag}>
                    <Ionicons name="document-text-outline" size={13} color="#2563EB" />
                    <Text style={styles.grnPoText}>{item.po_number}</Text>
                  </View>
                ) : (
                  <View style={[styles.grnPoTag, { backgroundColor: '#F3F4F6' }]}>
                    <Text style={[styles.grnPoText, { color: '#4B5563' }]}>Direct Inward</Text>
                  </View>
                )}
              </View>

              {item.invoice_number ? (
                <View style={[styles.grnMetaItem, { marginTop: 6 }]}>
                  <Ionicons name="receipt-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.grnMetaText}>Invoice: {item.invoice_number}</Text>
                </View>
              ) : null}

              {/* Dynamic Items breakdown */}
              {item.items && item.items.length > 0 ? (
                <View style={styles.grnItemsBox}>
                  <Text style={styles.grnItemsHeader}>
                    Items Inwarded ({item.items.length} {item.items.length === 1 ? 'item' : 'items'}
                    {item.total_qty ? ` • Total: ${formatNumber(item.total_qty)}` : ''})
                  </Text>
                  {item.items.map((it: any, idx: number) => (
                    <View key={idx} style={styles.grnItemPill}>
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, flex: 1 }}>
                        <Ionicons name="cube-outline" size={13} color={colors.primary} />
                        <Text style={styles.grnItemName} numberOfLines={1}>
                          {it.material_name}
                        </Text>
                      </View>
                      <Text style={styles.grnItemQty}>
                        +{formatNumber(it.quantity)} {it.unit || ''}
                      </Text>
                    </View>
                  ))}
                </View>
              ) : (
                <Text style={[styles.detailText, { marginTop: 6, fontStyle: 'italic', color: colors.textSecondary }]}>
                  {item.items_summary || 'General material inward recorded'}
                </Text>
              )}

              {item.notes ? (
                <View style={styles.grnNotesBox}>
                  <Text style={styles.grnNotesText}>Note: {item.notes}</Text>
                </View>
              ) : null}
            </Card>
          )}
        />
      )}

      {/* New Request Modal */}
      <Modal visible={showRequestModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>Raise Purchase Request</Text>
              <Pressable onPress={() => setShowRequestModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>
            <ScrollView style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>Select Material *</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 8 }}>
                {materials.map((m) => (
                  <Pressable
                    key={m.id}
                    style={[styles.chip, reqMatId === m.id && styles.chipActive]}
                    onPress={() => setReqMatId(m.id)}
                  >
                    <Text style={[styles.chipText, reqMatId === m.id && styles.chipTextActive]}>
                      {m.name}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
              <Text style={styles.inputLabel}>Required Quantity *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 500"
                keyboardType="numeric"
                value={reqQty}
                onChangeText={setReqQty}
              />
              <Text style={styles.inputLabel}>Reason / Justification</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Stock shortage for Valve Order #104"
                value={reqReason}
                onChangeText={setReqReason}
              />
            </ScrollView>
            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowRequestModal(false)} />
              <Button label="Submit Request" onPress={handleCreateRequest} />
            </View>
          </View>
        </View>
      </Modal>

      {/* New PO Modal */}
      <Modal visible={showPoModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>Issue Purchase Order</Text>
              <Pressable onPress={() => setShowPoModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>
            <ScrollView style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>Select Supplier *</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 8 }}>
                {suppliers.map((s) => (
                  <Pressable
                    key={s.id}
                    style={[styles.chip, poSupplierId === s.id && styles.chipActive]}
                    onPress={() => setPoSupplierId(s.id)}
                  >
                    <Text style={[styles.chipText, poSupplierId === s.id && styles.chipTextActive]}>
                      {s.name}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
              <Text style={styles.inputLabel}>Select Item / Material *</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 8 }}>
                {materials.map((m) => (
                  <Pressable
                    key={m.id}
                    style={[styles.chip, poMatId === m.id && styles.chipActive]}
                    onPress={() => setPoMatId(m.id)}
                  >
                    <Text style={[styles.chipText, poMatId === m.id && styles.chipTextActive]}>
                      {m.name}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
              <Text style={styles.inputLabel}>Quantity *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 1000"
                keyboardType="numeric"
                value={poQty}
                onChangeText={setPoQty}
              />
              <Text style={styles.inputLabel}>Rate per Unit (₹) *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 150"
                keyboardType="numeric"
                value={poRate}
                onChangeText={setPoRate}
              />
              <Text style={styles.inputLabel}>Commercial Terms</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 30 days payment net"
                value={poTerms}
                onChangeText={setPoTerms}
              />
            </ScrollView>
            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowPoModal(false)} />
              <Button label="Create PO" onPress={handleCreatePo} />
            </View>
          </View>
        </View>
      </Modal>

      {/* Receive GRN Modal */}
      <Modal visible={showGrnModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>Goods Inward (GRN)</Text>
              <Pressable onPress={() => setShowGrnModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            {/* Mode Switcher */}
            <View style={styles.modeToggleContainer}>
              <Pressable
                style={[styles.modeToggleBtn, grnMode === 'direct' && styles.modeToggleBtnActive]}
                onPress={() => setGrnMode('direct')}
              >
                <Text
                  style={[styles.modeToggleText, grnMode === 'direct' && styles.modeToggleTextActive]}
                >
                  Direct Inward
                </Text>
              </Pressable>
              <Pressable
                style={[styles.modeToggleBtn, grnMode === 'po' && styles.modeToggleBtnActive]}
                onPress={() => {
                  setGrnMode('po');
                  if (!activePo && orders.length > 0) {
                    const firstOpen = orders.find((o) => o.status !== 'RECEIVED') || orders[0];
                    handleSelectPoForGrn(firstOpen);
                  }
                }}
              >
                <Text
                  style={[styles.modeToggleText, grnMode === 'po' && styles.modeToggleTextActive]}
                >
                  From Purchase Order
                </Text>
              </Pressable>
            </View>

            <ScrollView style={{ maxHeight: 420 }} showsVerticalScrollIndicator={false}>
              {grnMode === 'direct' ? (
                <>
                  <Text style={styles.inputLabel}>Supplier / Vendor</Text>
                  <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 6 }}>
                    {suppliers.map((s) => (
                      <Pressable
                        key={s.id}
                        style={[styles.chip, grnSupplierId === s.id && styles.chipActive]}
                        onPress={() => setGrnSupplierId(s.id)}
                      >
                        <Text
                          style={[styles.chipText, grnSupplierId === s.id && styles.chipTextActive]}
                        >
                          {s.name}
                        </Text>
                      </Pressable>
                    ))}
                  </ScrollView>

                  <Text style={styles.inputLabel}>Material to Receive *</Text>
                  <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 6 }}>
                    {materials.map((m) => (
                      <Pressable
                        key={m.id}
                        style={[styles.chip, grnMaterialId === m.id && styles.chipActive]}
                        onPress={() => setGrnMaterialId(m.id)}
                      >
                        <Text
                          style={[styles.chipText, grnMaterialId === m.id && styles.chipTextActive]}
                        >
                          {m.name} ({m.unit || 'units'})
                        </Text>
                      </Pressable>
                    ))}
                  </ScrollView>

                  <Text style={styles.inputLabel}>
                    Received Quantity *{' '}
                    {grnMaterialId
                      ? `(${materials.find((m) => m.id === grnMaterialId)?.unit || 'units'})`
                      : ''}
                  </Text>
                  <TextInput
                    style={styles.input}
                    placeholder="e.g. 500"
                    keyboardType="numeric"
                    value={grnDirectQty}
                    onChangeText={setGrnDirectQty}
                  />

                  <Text style={styles.inputLabel}>Vendor Invoice / Challan Number</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="e.g. INV-99214 or DC-04"
                    value={invoiceNumber}
                    onChangeText={setInvoiceNumber}
                  />

                  <Text style={styles.inputLabel}>Notes / Storage Location</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="e.g. Inspected & stored in Rack B-04"
                    value={grnNotes}
                    onChangeText={setGrnNotes}
                  />
                </>
              ) : (
                <>
                  <Text style={styles.inputLabel}>Select Purchase Order *</Text>
                  {orders.length === 0 ? (
                    <Text style={[styles.detailText, { marginVertical: 8, color: colors.textSecondary }]}>
                      No purchase orders available. Switch to Direct Inward above.
                    </Text>
                  ) : (
                    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 8 }}>
                      {orders.map((po) => (
                        <Pressable
                          key={po.id}
                          style={[styles.chip, activePo?.id === po.id && styles.chipActive]}
                          onPress={() => handleSelectPoForGrn(po)}
                        >
                          <Text
                            style={[
                              styles.chipText,
                              activePo?.id === po.id && styles.chipTextActive,
                            ]}
                          >
                            {po.po_number} ({po.status})
                          </Text>
                        </Pressable>
                      ))}
                    </ScrollView>
                  )}

                  {activePo && (
                    <View
                      style={{
                        padding: 8,
                        backgroundColor: colors.background,
                        borderRadius: 8,
                        marginBottom: 10,
                      }}
                    >
                      <Text style={{ fontSize: 12, color: colors.textSecondary }}>
                        Vendor: <Text style={{ color: colors.text, fontWeight: '600' }}>{activePo.supplier_name}</Text>
                      </Text>
                    </View>
                  )}

                  <Text style={styles.inputLabel}>Supplier Invoice Number</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="e.g. INV-88219"
                    value={invoiceNumber}
                    onChangeText={setInvoiceNumber}
                  />

                  <Text style={[styles.inputLabel, { marginTop: 14 }]}>Received Quantities</Text>
                  {poItems.length === 0 ? (
                    <Text style={[styles.detailText, { marginVertical: 6, color: colors.textSecondary }]}>
                      Select a PO above to see order items.
                    </Text>
                  ) : (
                    poItems.map((item) => (
                      <View key={item.material_id} style={styles.grnItemRow}>
                        <View style={{ flex: 1 }}>
                          <Text style={{ fontWeight: '600', color: colors.text }}>
                            {item.material_name}
                          </Text>
                          <Text style={{ fontSize: 12, color: colors.textSecondary }}>
                            Ordered: {item.quantity} | Prev Received: {item.received_quantity}
                          </Text>
                        </View>
                        <TextInput
                          style={[styles.input, { width: 90, textAlign: 'center' }]}
                          keyboardType="numeric"
                          value={receivedQtyMap[item.material_id] ?? ''}
                          onChangeText={(val) =>
                            setReceivedQtyMap((prev) => ({ ...prev, [item.material_id]: val }))
                          }
                        />
                      </View>
                    ))
                  )}

                  <Text style={[styles.inputLabel, { marginTop: 10 }]}>Notes / Storage Location</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="e.g. Received at Bay 2"
                    value={grnNotes}
                    onChangeText={setGrnNotes}
                  />
                </>
              )}
            </ScrollView>

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowGrnModal(false)} />
              <Button label="Accept & Add to Stock" onPress={handleProcessGrn} />
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
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 3,
    marginBottom: spacing.md,
  },
  segmentBtn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 6,
  },
  segmentBtnActive: {
    backgroundColor: colors.surface,
  },
  segmentText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  segmentTextActive: {
    color: colors.primary,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
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
    marginBottom: 6,
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
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
  },
  detailText: {
    fontSize: 13,
    color: colors.text,
    fontWeight: '500',
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
  grnItemRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  grnTimestamp: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  grnMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  grnMetaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    flex: 1,
  },
  grnMetaText: {
    fontSize: 13,
    color: colors.textSecondary,
  },
  grnPoTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  grnPoText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#2563EB',
  },
  grnItemsBox: {
    marginTop: 10,
    padding: 8,
    backgroundColor: colors.background,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  grnItemsHeader: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
    marginBottom: 6,
    textTransform: 'uppercase',
  },
  grnItemPill: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 3,
  },
  grnItemName: {
    fontSize: 13,
    color: colors.text,
  },
  grnItemQty: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.success,
  },
  grnNotesBox: {
    marginTop: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    backgroundColor: '#F8FAFC',
    borderRadius: 6,
    borderLeftWidth: 3,
    borderLeftColor: colors.primary,
  },
  grnNotesText: {
    fontSize: 12,
    color: colors.textSecondary,
    fontStyle: 'italic',
  },
  deleteIconBtn: {
    padding: 6,
    borderRadius: 6,
    backgroundColor: '#FEE2E2',
    borderWidth: 1,
    borderColor: '#FECACA',
  },
  modeToggleContainer: {
    flexDirection: 'row',
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 3,
    marginBottom: 12,
  },
  modeToggleBtn: {
    flex: 1,
    paddingVertical: 6,
    alignItems: 'center',
    borderRadius: 6,
  },
  modeToggleBtnActive: {
    backgroundColor: colors.surface,
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 1,
  },
  modeToggleText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  modeToggleTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
});
