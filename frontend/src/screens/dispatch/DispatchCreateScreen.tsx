import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen } from '../../components/common/Screen';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { createDispatchOrder, dispatchOrder } from '../../api/repositories/dispatchRepository';
import { listFinishedGoods } from '../../api/repositories/finishedGoodsRepository';
import { createCustomer, listCustomers } from '../../api/repositories/customerRepository';
import type { CustomerRow, FinishedGoodsRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<MoreStackParamList, 'DispatchCreate'>;

export function DispatchCreateScreen({ navigation }: Props) {
  const [customers, setCustomers] = useState<CustomerRow[]>([]);
  const [finishedGoods, setFinishedGoods] = useState<FinishedGoodsRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  // Form State
  const [dispatchNumber, setDispatchNumber] = useState(
    () => `DSP-${Date.now().toString().slice(-6)}`,
  );
  const [selectedCustomerId, setSelectedCustomerId] = useState<string | null>(null);
  const [isChangingCustomer, setIsChangingCustomer] = useState(false);
  const [customerSearch, setCustomerSearch] = useState('');
  const [manualCustomerMode, setManualCustomerMode] = useState(false);
  const [manualCustomerName, setManualCustomerName] = useState('');

  const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
  const [quantity, setQuantity] = useState('10');
  const [vehicleNumber, setVehicleNumber] = useState('');
  const [driverName, setDriverName] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [notes, setNotes] = useState('');

  // Quick Add Customer Modal State
  const [showAddCustModal, setShowAddCustModal] = useState(false);
  const [newCustName, setNewCustName] = useState('');
  const [newCustCompany, setNewCustCompany] = useState('');
  const [newCustPhone, setNewCustPhone] = useState('');
  const [newCustEmail, setNewCustEmail] = useState('');
  const [newCustAddress, setNewCustAddress] = useState('');
  const [newCustGst, setNewCustGst] = useState('');
  const [savingCust, setSavingCust] = useState(false);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [custs, goods] = await Promise.all([
        listCustomers().catch(() => []),
        listFinishedGoods().catch(() => []),
      ]);
      setCustomers(custs);
      setFinishedGoods(goods);

      // Default to first customer if available
      if (custs.length > 0 && !selectedCustomerId) {
        setSelectedCustomerId(custs[0].id);
        const addr = custs[0].delivery_address || custs[0].address || '';
        if (addr) setDeliveryAddress(addr);
      }

      // Default to first product that has available stock
      const inStockGood = goods.find((g) => (g.available_quantity || 0) > 0) || goods[0];
      if (inStockGood && !selectedProductId) {
        setSelectedProductId(inStockGood.product_id);
      }
    } finally {
      setLoading(false);
    }
  }, [selectedCustomerId, selectedProductId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const selectedCustomer = useMemo(
    () => customers.find((c) => c.id === selectedCustomerId) || null,
    [customers, selectedCustomerId],
  );

  const filteredCustomers = useMemo(() => {
    if (!customerSearch.trim()) return customers;
    const q = customerSearch.trim().toLowerCase();
    return customers.filter(
      (c) =>
        (c.name || '').toLowerCase().includes(q) ||
        (c.company || '').toLowerCase().includes(q) ||
        (c.phone || '').toLowerCase().includes(q) ||
        (c.gst_number || '').toLowerCase().includes(q) ||
        (c.delivery_address || '').toLowerCase().includes(q),
    );
  }, [customers, customerSearch]);

  const selectedProduct = useMemo(
    () => finishedGoods.find((g) => g.product_id === selectedProductId) || null,
    [finishedGoods, selectedProductId],
  );

  const availableStock = selectedProduct ? (selectedProduct.available_quantity || 0) : 0;
  const numQty = parseFloat(quantity) || 0;
  const remainingStock = Math.max(0, availableStock - numQty);
  const isOverStock = numQty > availableStock && availableStock > 0;

  const handleSelectCustomer = (c: CustomerRow) => {
    setSelectedCustomerId(c.id);
    setManualCustomerMode(false);
    setManualCustomerName('');
    setIsChangingCustomer(false);
    const addr = c.delivery_address || c.address || '';
    if (addr) {
      setDeliveryAddress(addr);
    }
  };

  const resolvedCustomerName = useMemo(() => {
    if (manualCustomerMode) {
      return manualCustomerName.trim();
    }
    if (selectedCustomer) {
      return selectedCustomer.company
        ? `${selectedCustomer.name} (${selectedCustomer.company})`
        : selectedCustomer.name;
    }
    return manualCustomerName.trim();
  }, [manualCustomerMode, manualCustomerName, selectedCustomer]);

  const handleSaveQuickCustomer = async () => {
    if (!newCustName.trim() || !newCustCompany.trim()) {
      Alert.alert('Required Fields', 'Please enter customer name and company name.');
      return;
    }

    try {
      setSavingCust(true);
      const newId = await createCustomer({
        name: newCustName.trim(),
        company: newCustCompany.trim(),
        phone: newCustPhone.trim() || undefined,
        email: newCustEmail.trim() || undefined,
        delivery_address: newCustAddress.trim() || undefined,
        gst_number: newCustGst.trim() || undefined,
      });

      // Reload customers and assign the newly created one
      const updatedList = await listCustomers();
      setCustomers(updatedList);
      setSelectedCustomerId(newId);
      setManualCustomerMode(false);
      setIsChangingCustomer(false);
      if (newCustAddress.trim()) {
        setDeliveryAddress(newCustAddress.trim());
      }

      setShowAddCustModal(false);
      setNewCustName('');
      setNewCustCompany('');
      setNewCustPhone('');
      setNewCustEmail('');
      setNewCustAddress('');
      setNewCustGst('');

      Alert.alert('Customer Assigned', `Customer "${newCustCompany.trim()}" added and assigned to this dispatch.`);
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not save customer');
    } finally {
      setSavingCust(false);
    }
  };

  const handleSubmit = async (dispatchImmediately = false) => {
    if (!dispatchNumber.trim()) {
      Alert.alert('Required', 'Please enter a dispatch/challan number.');
      return;
    }
    if (!resolvedCustomerName) {
      Alert.alert('Customer Required', 'Please assign a customer or enter buyer details.');
      return;
    }
    if (!selectedProductId) {
      Alert.alert('Product Required', 'Please select a finished product from warehouse.');
      return;
    }
    if (isNaN(numQty) || numQty <= 0) {
      Alert.alert('Invalid Quantity', 'Please enter a valid quantity greater than 0.');
      return;
    }

    try {
      setSubmitting(true);
      const newOrderId = await createDispatchOrder({
        dispatch_number: dispatchNumber.trim(),
        customer_name: resolvedCustomerName,
        customer_id: !manualCustomerMode && selectedCustomerId ? selectedCustomerId : undefined,
        product_id: selectedProductId,
        quantity: numQty,
        delivery_address: deliveryAddress.trim() || undefined,
        vehicle_number: vehicleNumber.trim() || undefined,
        driver_name: driverName.trim() || undefined,
        notes: notes.trim() || undefined,
      });

      if (dispatchImmediately) {
        await dispatchOrder(newOrderId);
      }

      Alert.alert(
        'Success',
        dispatchImmediately
          ? `Dispatch order ${dispatchNumber} created and marked DISPATCHED! Inventory has been deducted.`
          : `Dispatch order ${dispatchNumber} created and marked READY for shipment.`,
        [
          {
            text: 'OK',
            onPress: () => navigation.goBack(),
          },
        ],
      );
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create dispatch order');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Screen scroll contentContainerStyle={styles.container}>
      {/* Header Banner */}
      <View style={styles.headerBox}>
        <Ionicons name="paper-plane-outline" size={24} color={colors.primary} />
        <View style={{ flex: 1 }}>
          <Text style={styles.headerTitle}>New Delivery Challan & Dispatch</Text>
          <Text style={styles.headerSubtitle}>
            Assign buyer, allocate warehouse stock, and create transport challan
          </Text>
        </View>
      </View>

      {/* Dispatch / Challan Number */}
      <View style={styles.sectionHeaderRow}>
        <Text style={styles.sectionTitle}>Challan Details</Text>
        <Pressable
          style={styles.genBtn}
          onPress={() => setDispatchNumber(`DSP-${Date.now().toString().slice(-6)}`)}
        >
          <Ionicons name="refresh-outline" size={13} color={colors.primary} />
          <Text style={styles.genBtnText}>Generate New</Text>
        </Pressable>
      </View>
      <TextInput
        style={styles.input}
        value={dispatchNumber}
        onChangeText={setDispatchNumber}
        placeholder="e.g. DSP-001234"
      />

      {/* 1. CUSTOMER / BUYER ASSIGNMENT */}
      <View style={{ marginTop: 18 }}>
        <View style={styles.sectionHeaderRow}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name="business" size={16} color={colors.primary} />
            <Text style={styles.sectionTitle}>1. Assign Customer / Buyer *</Text>
          </View>
          {selectedCustomer && !isChangingCustomer && !manualCustomerMode && (
            <View style={styles.badgeAssigned}>
              <Ionicons name="checkmark-circle" size={13} color="#15803D" />
              <Text style={styles.badgeAssignedText}>Assigned</Text>
            </View>
          )}
        </View>

        {/* State A: Customer is currently assigned */}
        {selectedCustomer && !isChangingCustomer && !manualCustomerMode ? (
          <Card style={styles.assignedCustCard}>
            <View style={styles.assignedCustHeader}>
              <View style={styles.custAvatar}>
                <Ionicons name="business" size={20} color="#FFFFFF" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.assignedCustName}>{selectedCustomer.name}</Text>
                {selectedCustomer.company ? (
                  <Text style={styles.assignedCustCompany}>{selectedCustomer.company}</Text>
                ) : null}
              </View>
              <Pressable
                style={styles.changeCustBtn}
                onPress={() => setIsChangingCustomer(true)}
              >
                <Ionicons name="swap-horizontal" size={14} color="#0A1E38" />
                <Text style={styles.changeCustBtnText}>Change</Text>
              </Pressable>
            </View>

            <View style={styles.custDetailsGrid}>
              {selectedCustomer.contact_person || selectedCustomer.phone ? (
                <View style={styles.custDetailItem}>
                  <Ionicons name="call-outline" size={13} color="#64748B" />
                  <Text style={styles.custDetailText}>
                    {[selectedCustomer.contact_person, selectedCustomer.phone]
                      .filter(Boolean)
                      .join(' • ')}
                  </Text>
                </View>
              ) : null}

              {selectedCustomer.gst_number ? (
                <View style={styles.custDetailItem}>
                  <Ionicons name="document-text-outline" size={13} color="#64748B" />
                  <Text style={styles.custDetailText}>
                    GSTIN: <Text style={{ fontWeight: '700' }}>{selectedCustomer.gst_number}</Text>
                  </Text>
                </View>
              ) : null}

              <View style={styles.custDetailItem}>
                <Ionicons name="location-outline" size={13} color="#64748B" />
                <Text style={styles.custDetailText} numberOfLines={2}>
                  {selectedCustomer.delivery_address ||
                    selectedCustomer.address ||
                    'Standard delivery address'}
                </Text>
              </View>
            </View>

            <View style={styles.autoFilledNote}>
              <Ionicons name="sparkles" size={13} color="#0369A1" />
              <Text style={styles.autoFilledNoteText}>
                Destination address auto-synced with customer delivery records
              </Text>
            </View>
          </Card>
        ) : null}

        {/* State B: Customer Selection / Directory / Search View */}
        {(!selectedCustomer || isChangingCustomer) && !manualCustomerMode ? (
          <View style={styles.selectorContainer}>
            {/* Search Bar + Add Button Row */}
            <View style={styles.customerActionRow}>
              <View style={styles.searchBar}>
                <Ionicons name="search" size={15} color="#64748B" />
                <TextInput
                  style={styles.searchBarInput}
                  placeholder="Search registered customers..."
                  value={customerSearch}
                  onChangeText={setCustomerSearch}
                  placeholderTextColor="#94A3B8"
                />
                {customerSearch ? (
                  <Pressable onPress={() => setCustomerSearch('')}>
                    <Ionicons name="close-circle" size={15} color="#94A3B8" />
                  </Pressable>
                ) : null}
              </View>

              <Pressable
                style={styles.quickAddBtn}
                onPress={() => setShowAddCustModal(true)}
              >
                <Ionicons name="add" size={16} color="#FFFFFF" />
                <Text style={styles.quickAddBtnText}>Add</Text>
              </Pressable>
            </View>

            {/* List of Customers */}
            {filteredCustomers.length === 0 ? (
              <View style={styles.emptyCustBox}>
                <Ionicons name="people-outline" size={32} color="#94A3B8" />
                <Text style={styles.emptyCustTitle}>
                  {customers.length === 0 ? 'No Customers Registered' : 'No Matching Customer Found'}
                </Text>
                <Text style={styles.emptyCustDesc}>
                  Create your first customer to assign them to this delivery challan.
                </Text>
                <Pressable
                  style={styles.createCustCta}
                  onPress={() => setShowAddCustModal(true)}
                >
                  <Ionicons name="person-add" size={15} color="#FFFFFF" />
                  <Text style={styles.createCustCtaText}>+ Register New Customer</Text>
                </Pressable>
              </View>
            ) : (
              <View style={{ gap: 8, marginTop: 8 }}>
                {filteredCustomers.map((c) => {
                  const isSelected = selectedCustomerId === c.id;
                  return (
                    <Pressable
                      key={c.id}
                      style={[
                        styles.customerCard,
                        isSelected && styles.customerCardSelected,
                      ]}
                      onPress={() => handleSelectCustomer(c)}
                    >
                      <Ionicons
                        name={isSelected ? 'checkmark-circle' : 'radio-button-off'}
                        size={20}
                        color={isSelected ? colors.primary : '#94A3B8'}
                      />
                      <View style={{ flex: 1 }}>
                        <Text style={styles.custCardName}>{c.name}</Text>
                        <Text style={styles.custCardCompany}>
                          {c.company || 'Enterprise Buyer'}
                          {c.phone ? ` • ${c.phone}` : ''}
                        </Text>
                        {c.delivery_address ? (
                          <Text style={styles.custCardAddress} numberOfLines={1}>
                            📍 {c.delivery_address}
                          </Text>
                        ) : null}
                      </View>
                      {c.gst_number ? (
                        <View style={styles.gstTag}>
                          <Text style={styles.gstTagText}>GST</Text>
                        </View>
                      ) : null}
                    </Pressable>
                  );
                })}
              </View>
            )}

            {/* Cancel Change button if already had a customer */}
            {selectedCustomer && isChangingCustomer ? (
              <Pressable
                style={styles.cancelChangeBtn}
                onPress={() => setIsChangingCustomer(false)}
              >
                <Text style={styles.cancelChangeBtnText}>Cancel & Keep Current Customer</Text>
              </Pressable>
            ) : null}

            {/* Manual Entry Toggle */}
            <Pressable
              style={styles.manualEntryToggle}
              onPress={() => {
                setManualCustomerMode(true);
                setSelectedCustomerId(null);
              }}
            >
              <Ionicons name="create-outline" size={14} color="#64748B" />
              <Text style={styles.manualEntryToggleText}>
                Or enter unregistered / one-time buyer manually
              </Text>
            </Pressable>
          </View>
        ) : null}

        {/* State C: Manual Customer Mode */}
        {manualCustomerMode ? (
          <View style={styles.manualModeBox}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={styles.label}>Buyer / Consignee Name *</Text>
              <Pressable
                onPress={() => {
                  setManualCustomerMode(false);
                  if (customers.length > 0) {
                    setSelectedCustomerId(customers[0].id);
                  }
                }}
              >
                <Text style={styles.switchLink}>Switch to Registered Customers</Text>
              </Pressable>
            </View>
            <TextInput
              style={styles.input}
              placeholder="e.g. Apex Industrial Solutions Ltd"
              value={manualCustomerName}
              onChangeText={setManualCustomerName}
              autoFocus
            />
          </View>
        ) : null}
      </View>

      {/* 2. FINISHED GOODS SELECTION */}
      <View style={{ marginTop: 20 }}>
        <Text style={styles.sectionTitle}>2. Select Product from Warehouse *</Text>
        {finishedGoods.length === 0 ? (
          <Card style={styles.emptyNotice}>
            <Ionicons name="cube-outline" size={20} color={colors.warning} />
            <Text style={styles.emptyNoticeText}>
              No finished goods available in warehouse. Complete production and QA first.
            </Text>
          </Card>
        ) : (
          <View style={{ gap: 8, marginTop: 6 }}>
            {finishedGoods.map((item) => {
              const isSelected = selectedProductId === item.product_id;
              const stock = item.available_quantity || 0;
              return (
                <Pressable
                  key={item.id}
                  style={[
                    styles.productCard,
                    isSelected && styles.productCardSelected,
                  ]}
                  onPress={() => setSelectedProductId(item.product_id)}
                >
                  <Ionicons
                    name={isSelected ? 'radio-button-on' : 'radio-button-off'}
                    size={20}
                    color={isSelected ? colors.primary : colors.border}
                  />
                  <View style={{ flex: 1 }}>
                    <Text style={styles.productCode}>{item.product_code || 'Product'}</Text>
                    <Text style={styles.productName}>{item.product_name || 'Finished Item'}</Text>
                  </View>
                  <View
                    style={[
                      styles.stockBadge,
                      stock > 0 ? styles.stockBadgeAvailable : styles.stockBadgeZero,
                    ]}
                  >
                    <Text
                      style={[
                        styles.stockBadgeText,
                        stock > 0 ? styles.stockBadgeTextAvailable : styles.stockBadgeTextZero,
                      ]}
                    >
                      {stock} in stock
                    </Text>
                  </View>
                </Pressable>
              );
            })}
          </View>
        )}
      </View>

      {/* 3. DISPATCH QUANTITY */}
      <View style={{ marginTop: 18 }}>
        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
          <Text style={styles.sectionTitle}>3. Dispatch Quantity *</Text>
          {selectedProduct && (
            <Text style={styles.stockStatusHint}>
              Warehouse Stock: <Text style={{ fontWeight: '800' }}>{availableStock}</Text> pcs
            </Text>
          )}
        </View>

        <TextInput
          style={[styles.input, isOverStock && styles.inputWarning]}
          value={quantity}
          onChangeText={setQuantity}
          keyboardType="numeric"
          placeholder="e.g. 20"
        />

        {/* Quick Fill Buttons */}
        {availableStock > 0 && (
          <View style={styles.quickFillRow}>
            {[5, 10, 20, availableStock].map((val, idx) => (
              <Pressable
                key={idx}
                style={styles.quickFillBtn}
                onPress={() => setQuantity(String(val))}
              >
                <Text style={styles.quickFillText}>
                  {val === availableStock ? `Max (${val})` : `+${val}`}
                </Text>
              </Pressable>
            ))}
          </View>
        )}

        {/* Stock Impact Preview */}
        {selectedProduct && (
          <View style={styles.impactBox}>
            <Ionicons name="information-circle-outline" size={16} color="#0369A1" />
            <Text style={styles.impactText}>
              Available: <Text style={styles.bold}>{availableStock}</Text> · Dispatching:{' '}
              <Text style={styles.bold}>{numQty}</Text> · Remaining Stock:{' '}
              <Text style={styles.bold}>{remainingStock}</Text>
            </Text>
          </View>
        )}
      </View>

      {/* 4. DELIVERY & TRANSPORT LOGISTICS */}
      <View style={{ marginTop: 18 }}>
        <Text style={styles.sectionTitle}>4. Transport & Delivery Logistics</Text>

        <Text style={[styles.label, { marginTop: 6 }]}>Delivery / Destination Address</Text>
        <TextInput
          style={styles.input}
          placeholder="Client site, dock, or delivery warehouse"
          value={deliveryAddress}
          onChangeText={setDeliveryAddress}
        />

        <View style={{ flexDirection: 'row', gap: 10, marginTop: 10 }}>
          <View style={{ flex: 1 }}>
            <Text style={styles.label}>Vehicle Number</Text>
            <TextInput
              style={styles.input}
              placeholder="e.g. MH 12 AB 1234"
              value={vehicleNumber}
              onChangeText={setVehicleNumber}
            />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.label}>Driver Name / Mobile</Text>
            <TextInput
              style={styles.input}
              placeholder="e.g. Ramesh (Driver)"
              value={driverName}
              onChangeText={setDriverName}
            />
          </View>
        </View>

        <Text style={[styles.label, { marginTop: 10 }]}>Dispatch Notes / PO Reference</Text>
        <TextInput
          style={[styles.input, { height: 60, textAlignVertical: 'top' }]}
          placeholder="e.g. Handle with care, Buyer PO Ref #8841"
          value={notes}
          onChangeText={setNotes}
          multiline
        />
      </View>

      {/* ACTION BUTTONS */}
      <View style={{ gap: 10, marginTop: 24, marginBottom: 40 }}>
        <Button
          label={submitting ? 'Creating Challan...' : 'Save as Ready for Dispatch'}
          variant="secondary"
          disabled={submitting}
          onPress={() => handleSubmit(false)}
        />
        <Button
          label={submitting ? 'Processing Dispatch...' : 'Save & Dispatch Now (Deduct Stock)'}
          variant="primary"
          disabled={submitting}
          onPress={() => handleSubmit(true)}
        />
      </View>

      {/* QUICK ADD CUSTOMER MODAL */}
      <Modal
        visible={showAddCustModal}
        animationType="slide"
        transparent
        onRequestClose={() => setShowAddCustModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <Ionicons name="person-add" size={20} color={colors.primary} />
                <Text style={styles.modalTitle}>Register New Customer</Text>
              </View>
              <Pressable onPress={() => setShowAddCustModal(false)}>
                <Ionicons name="close" size={22} color={colors.textSecondary} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false} style={{ maxHeight: 420 }}>
              <Text style={styles.label}>Customer / Contact Name *</Text>
              <TextInput
                style={styles.modalInput}
                placeholder="e.g. Rajesh Kumar"
                value={newCustName}
                onChangeText={setNewCustName}
              />

              <Text style={styles.label}>Company / Organization Name *</Text>
              <TextInput
                style={styles.modalInput}
                placeholder="e.g. Bharat Motors Ltd"
                value={newCustCompany}
                onChangeText={setNewCustCompany}
              />

              <View style={{ flexDirection: 'row', gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.label}>Phone Number</Text>
                  <TextInput
                    style={styles.modalInput}
                    placeholder="e.g. 9876543210"
                    value={newCustPhone}
                    onChangeText={setNewCustPhone}
                    keyboardType="phone-pad"
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.label}>GSTIN Number</Text>
                  <TextInput
                    style={styles.modalInput}
                    placeholder="e.g. 27AAAAA0000A1Z5"
                    value={newCustGst}
                    onChangeText={setNewCustGst}
                    autoCapitalize="characters"
                  />
                </View>
              </View>

              <Text style={styles.label}>Email Address</Text>
              <TextInput
                style={styles.modalInput}
                placeholder="e.g. procurement@bharatmotors.com"
                value={newCustEmail}
                onChangeText={setNewCustEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />

              <Text style={styles.label}>Delivery / Warehouse Address</Text>
              <TextInput
                style={[styles.modalInput, { height: 60, textAlignVertical: 'top' }]}
                placeholder="e.g. Plot 15, MIDC Phase 2, Chakan, Pune 410501"
                value={newCustAddress}
                onChangeText={setNewCustAddress}
                multiline
              />
            </ScrollView>

            <View style={styles.modalActions}>
              <Pressable
                style={styles.modalCancelBtn}
                onPress={() => setShowAddCustModal(false)}
                disabled={savingCust}
              >
                <Text style={styles.modalCancelText}>Cancel</Text>
              </Pressable>
              <Pressable
                style={styles.modalSaveBtn}
                onPress={handleSaveQuickCustomer}
                disabled={savingCust}
              >
                {savingCust ? (
                  <ActivityIndicator size="small" color="#FFFFFF" />
                ) : (
                  <>
                    <Ionicons name="checkmark" size={16} color="#FFFFFF" />
                    <Text style={styles.modalSaveText}>Save & Assign</Text>
                  </>
                )}
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: spacing.md,
    backgroundColor: colors.background,
  },
  headerBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#EEF2FF',
    padding: 14,
    borderRadius: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#C7D2FE',
  },
  headerTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#312E81',
  },
  headerSubtitle: {
    fontSize: 11.5,
    color: '#4338CA',
    marginTop: 2,
    lineHeight: 16,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.text,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  label: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginBottom: 4,
  },
  genBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  genBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.primary,
  },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: colors.text,
    backgroundColor: colors.surface,
  },
  inputWarning: {
    borderColor: colors.warning,
    backgroundColor: '#FFFBEB',
  },

  // Assigned Customer Card
  assignedCustCard: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#0A1E38',
    padding: 14,
    marginTop: 6,
  },
  assignedCustHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  custAvatar: {
    width: 38,
    height: 38,
    borderRadius: 8,
    backgroundColor: '#0A1E38',
    alignItems: 'center',
    justifyContent: 'center',
  },
  assignedCustName: {
    fontSize: 15,
    fontWeight: '800',
    color: colors.text,
  },
  assignedCustCompany: {
    fontSize: 12,
    color: colors.primary,
    fontWeight: '600',
    marginTop: 1,
  },
  changeCustBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: '#E2E8F0',
  },
  changeCustBtnText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#0A1E38',
  },
  custDetailsGrid: {
    marginTop: 10,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    gap: 6,
  },
  custDetailItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  custDetailText: {
    fontSize: 12,
    color: '#475569',
    flex: 1,
  },
  autoFilledNote: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    marginTop: 10,
  },
  autoFilledNoteText: {
    fontSize: 11,
    color: '#0369A1',
    fontWeight: '600',
    flex: 1,
  },
  badgeAssigned: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  badgeAssignedText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#15803D',
  },

  // Selector View
  selectorContainer: {
    marginTop: 6,
  },
  customerActionRow: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
  },
  searchBar: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 10,
    height: 40,
    gap: 8,
  },
  searchBarInput: {
    flex: 1,
    fontSize: 13,
    color: colors.text,
  },
  quickAddBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.primary,
    paddingHorizontal: 12,
    height: 40,
    borderRadius: 8,
  },
  quickAddBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  customerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: colors.surface,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  customerCardSelected: {
    borderColor: colors.primary,
    backgroundColor: '#F0F9FF',
  },
  custCardName: {
    fontSize: 13.5,
    fontWeight: '800',
    color: colors.text,
  },
  custCardCompany: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginTop: 1,
  },
  custCardAddress: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 2,
  },
  gstTag: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  gstTagText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#475569',
  },
  emptyCustBox: {
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 18,
    alignItems: 'center',
    marginTop: 8,
  },
  emptyCustTitle: {
    fontSize: 13.5,
    fontWeight: '700',
    color: colors.text,
    marginTop: 6,
  },
  emptyCustDesc: {
    fontSize: 11.5,
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 2,
    marginBottom: 12,
  },
  createCustCta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  createCustCtaText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  cancelChangeBtn: {
    alignItems: 'center',
    paddingVertical: 8,
    marginTop: 6,
  },
  cancelChangeBtnText: {
    fontSize: 11.5,
    color: colors.primary,
    fontWeight: '700',
  },
  manualEntryToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    justifyContent: 'center',
    paddingVertical: 8,
    marginTop: 4,
  },
  manualEntryToggleText: {
    fontSize: 11.5,
    color: '#64748B',
    fontWeight: '600',
  },
  manualModeBox: {
    backgroundColor: colors.surface,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
    marginTop: 6,
  },
  switchLink: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.primary,
  },

  // Finished Goods Product
  productCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: colors.surface,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  productCardSelected: {
    borderColor: colors.primary,
    backgroundColor: '#F0F9FF',
  },
  productCode: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.text,
  },
  productName: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  stockBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  stockBadgeAvailable: {
    backgroundColor: '#DCFCE7',
  },
  stockBadgeZero: {
    backgroundColor: '#F1F5F9',
  },
  stockBadgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  stockBadgeTextAvailable: {
    color: '#15803D',
  },
  stockBadgeTextZero: {
    color: '#64748B',
  },
  stockStatusHint: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  quickFillRow: {
    flexDirection: 'row',
    gap: 6,
    marginTop: 6,
  },
  quickFillBtn: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: '#E2E8F0',
  },
  quickFillText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.text,
  },
  impactBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F0F9FF',
    padding: 8,
    borderRadius: 6,
    marginTop: 8,
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  impactText: {
    fontSize: 11,
    color: '#0369A1',
    flex: 1,
  },
  bold: {
    fontWeight: '800',
  },
  emptyNotice: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#FFFBEB',
    padding: 12,
    borderRadius: 8,
    borderColor: '#FDE68A',
  },
  emptyNoticeText: {
    fontSize: 12,
    color: '#B45309',
    flex: 1,
  },

  // Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    padding: spacing.md,
  },
  modalContent: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 18,
    maxHeight: '90%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.text,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 13,
    color: colors.text,
    backgroundColor: '#F8FAFC',
    marginBottom: 10,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
    marginTop: 14,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  modalCancelBtn: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
  },
  modalCancelText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  modalSaveBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    paddingHorizontal: 18,
    paddingVertical: 10,
    borderRadius: 8,
  },
  modalSaveText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#FFFFFF',
  },
});
