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
import { SearchField } from '../../components/common/SearchField';
import {
  createCustomer,
  deleteCustomer,
  listCustomers,
  updateCustomer,
} from '../../database/repositories/customerRepository';
import {
  createSupplier,
  deleteSupplier,
  listSuppliers,
  updateSupplier,
} from '../../database/repositories/supplierRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors, spacing, typography } from '../../theme';
import type { CustomerRow, SupplierRow } from '../../types/database';

type Tab = 'customers' | 'suppliers';

export function ContactsScreen() {
  const [tab, setTab] = useState<Tab>('customers');
  const [search, setSearch] = useState('');
  const [customers, setCustomers] = useState<CustomerRow[]>([]);
  const [suppliers, setSuppliers] = useState<SupplierRow[]>([]);
  const [loading, setLoading] = useState(false);

  // Modal states
  const [showAddCustomer, setShowAddCustomer] = useState(false);
  const [showAddSupplier, setShowAddSupplier] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState<CustomerRow | null>(null);
  const [editingSupplier, setEditingSupplier] = useState<SupplierRow | null>(null);

  // Customer Form
  const [custName, setCustName] = useState('');
  const [custCompany, setCustCompany] = useState('');
  const [custPhone, setCustPhone] = useState('');
  const [custEmail, setCustEmail] = useState('');
  const [custAddress, setCustAddress] = useState('');
  const [custGst, setCustGst] = useState('');

  // Supplier Form
  const [suppName, setSuppName] = useState('');
  const [suppContact, setSuppContact] = useState('');
  const [suppPhone, setSuppPhone] = useState('');
  const [suppEmail, setSuppEmail] = useState('');
  const [suppItems, setSuppItems] = useState('');
  const [suppGst, setSuppGst] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      if (tab === 'customers') {
        const list = await listCustomers(search);
        setCustomers(list);
      } else {
        const list = await listSuppliers(search);
        setSuppliers(list);
      }
    } finally {
      setLoading(false);
    }
  }, [tab, search]);

  useLiveQuery(loadData);

  const handleOpenAddCustomer = () => {
    setEditingCustomer(null);
    setCustName('');
    setCustCompany('');
    setCustPhone('');
    setCustEmail('');
    setCustAddress('');
    setCustGst('');
    setShowAddCustomer(true);
  };

  const handleOpenEditCustomer = (c: CustomerRow) => {
    setEditingCustomer(c);
    setCustName(c.name);
    setCustCompany(c.company);
    setCustPhone(c.phone || '');
    setCustEmail(c.email || '');
    setCustAddress(c.delivery_address || '');
    setCustGst(c.gst_number || '');
    setShowAddCustomer(true);
  };

  const handleDeleteCustomer = (c: CustomerRow) => {
    Alert.alert(
      'Delete Customer',
      `Are you sure you want to delete ${c.name} (${c.company})?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteCustomer(c.id);
              Alert.alert('Deleted', 'Customer deleted successfully.');
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete customer');
            }
          },
        },
      ],
    );
  };

  const handleOpenAddSupplier = () => {
    setEditingSupplier(null);
    setSuppName('');
    setSuppContact('');
    setSuppPhone('');
    setSuppEmail('');
    setSuppItems('');
    setSuppGst('');
    setShowAddSupplier(true);
  };

  const handleOpenEditSupplier = (s: SupplierRow) => {
    setEditingSupplier(s);
    setSuppName(s.name);
    setSuppContact(s.contact_person || '');
    setSuppPhone(s.phone || '');
    setSuppEmail(s.email || '');
    setSuppItems(s.supplied_items || '');
    setSuppGst(s.gst_number || '');
    setShowAddSupplier(true);
  };

  const handleDeleteSupplier = (s: SupplierRow) => {
    Alert.alert(
      'Delete Supplier',
      `Are you sure you want to delete supplier ${s.name}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteSupplier(s.id);
              Alert.alert('Deleted', 'Supplier deleted successfully.');
              await loadData();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete supplier');
            }
          },
        },
      ],
    );
  };

  const handleSaveCustomer = async () => {
    if (!custName.trim() || !custCompany.trim()) {
      Alert.alert('Required Fields', 'Please enter customer name and company.');
      return;
    }
    try {
      if (editingCustomer) {
        await updateCustomer(editingCustomer.id, {
          name: custName,
          company: custCompany,
          phone: custPhone,
          email: custEmail,
          delivery_address: custAddress,
          gst_number: custGst,
        });
      } else {
        await createCustomer({
          name: custName,
          company: custCompany,
          phone: custPhone,
          email: custEmail,
          delivery_address: custAddress,
          gst_number: custGst,
        });
      }
      setShowAddCustomer(false);
      setEditingCustomer(null);
      setCustName('');
      setCustCompany('');
      setCustPhone('');
      setCustEmail('');
      setCustAddress('');
      setCustGst('');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not save customer');
    }
  };

  const handleSaveSupplier = async () => {
    if (!suppName.trim()) {
      Alert.alert('Required Field', 'Please enter supplier name.');
      return;
    }
    try {
      if (editingSupplier) {
        await updateSupplier(editingSupplier.id, {
          name: suppName,
          contact_person: suppContact,
          phone: suppPhone,
          email: suppEmail,
          supplied_items: suppItems,
          gst_number: suppGst,
        });
      } else {
        await createSupplier({
          name: suppName,
          contact_person: suppContact,
          phone: suppPhone,
          email: suppEmail,
          supplied_items: suppItems,
          gst_number: suppGst,
        });
      }
      setShowAddSupplier(false);
      setEditingSupplier(null);
      setSuppName('');
      setSuppContact('');
      setSuppPhone('');
      setSuppEmail('');
      setSuppItems('');
      setSuppGst('');
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not save supplier');
    }
  };

  return (
    <Screen>
      {/* Segmented Switcher */}
      <View style={styles.segmentContainer}>
        <Pressable
          style={[styles.segmentBtn, tab === 'customers' && styles.segmentBtnActive]}
          onPress={() => setTab('customers')}
        >
          <Text style={[styles.segmentText, tab === 'customers' && styles.segmentTextActive]}>
            Customers ({customers.length})
          </Text>
        </Pressable>
        <Pressable
          style={[styles.segmentBtn, tab === 'suppliers' && styles.segmentBtnActive]}
          onPress={() => setTab('suppliers')}
        >
          <Text style={[styles.segmentText, tab === 'suppliers' && styles.segmentTextActive]}>
            Suppliers ({suppliers.length})
          </Text>
        </Pressable>
      </View>

      {/* Search and Action Row */}
      <View style={styles.actionRow}>
        <View style={{ flex: 1 }}>
          <SearchField
            value={search}
            onChangeText={setSearch}
            placeholder={tab === 'customers' ? 'Search customers...' : 'Search suppliers...'}
          />
        </View>
        <Button
          label={tab === 'customers' ? '+ Customer' : '+ Supplier'}
          onPress={() => {
            if (tab === 'customers') handleOpenAddCustomer();
            else handleOpenAddSupplier();
          }}
          style={styles.addBtn}
        />
      </View>

      {/* List */}
      {tab === 'customers' ? (
        <FlatList
          data={customers}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No customers found</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  <Text style={styles.cardSubtitle}>{item.company}</Text>
                </View>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Pressable
                    style={styles.cardActionBtn}
                    onPress={() => handleOpenEditCustomer(item)}
                    hitSlop={6}
                  >
                    <Ionicons name="create-outline" size={15} color={colors.primary} />
                  </Pressable>
                  <Pressable
                    style={[styles.cardActionBtn, { borderColor: '#FECACA', backgroundColor: '#FEF2F2' }]}
                    onPress={() => handleDeleteCustomer(item)}
                    hitSlop={6}
                  >
                    <Ionicons name="trash-outline" size={15} color={colors.danger} />
                  </Pressable>
                </View>
              </View>
              {item.phone ? (
                <View style={styles.infoRow}>
                  <Ionicons name="call-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>{item.phone}</Text>
                </View>
              ) : null}
              {item.email ? (
                <View style={styles.infoRow}>
                  <Ionicons name="mail-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>{item.email}</Text>
                </View>
              ) : null}
              {item.delivery_address ? (
                <View style={styles.infoRow}>
                  <Ionicons name="location-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText} numberOfLines={2}>
                    {item.delivery_address}
                  </Text>
                </View>
              ) : null}
              {item.gst_number ? (
                <View style={styles.infoRow}>
                  <Ionicons name="document-text-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>GST: {item.gst_number}</Text>
                </View>
              ) : null}
            </Card>
          )}
        />
      ) : (
        <FlatList
          data={suppliers}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 24 }}
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyText}>No suppliers found</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.cardItem}>
              <View style={styles.cardHeader}>
                <View>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  {item.contact_person ? (
                    <Text style={styles.cardSubtitle}>Contact: {item.contact_person}</Text>
                  ) : null}
                </View>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Pressable
                    style={styles.cardActionBtn}
                    onPress={() => handleOpenEditSupplier(item)}
                    hitSlop={6}
                  >
                    <Ionicons name="create-outline" size={15} color={colors.primary} />
                  </Pressable>
                  <Pressable
                    style={[styles.cardActionBtn, { borderColor: '#FECACA', backgroundColor: '#FEF2F2' }]}
                    onPress={() => handleDeleteSupplier(item)}
                    hitSlop={6}
                  >
                    <Ionicons name="trash-outline" size={15} color={colors.danger} />
                  </Pressable>
                </View>
              </View>
              {item.supplied_items ? (
                <View style={styles.infoRow}>
                  <Ionicons name="cube-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>Items: {item.supplied_items}</Text>
                </View>
              ) : null}
              {item.phone ? (
                <View style={styles.infoRow}>
                  <Ionicons name="call-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>{item.phone}</Text>
                </View>
              ) : null}
              {item.email ? (
                <View style={styles.infoRow}>
                  <Ionicons name="mail-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>{item.email}</Text>
                </View>
              ) : null}
              {item.gst_number ? (
                <View style={styles.infoRow}>
                  <Ionicons name="document-text-outline" size={14} color={colors.textSecondary} />
                  <Text style={styles.infoText}>GST: {item.gst_number}</Text>
                </View>
              ) : null}
            </Card>
          )}
        />
      )}

      {/* Add / Edit Customer Modal */}
      <Modal visible={showAddCustomer} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>{editingCustomer ? 'Edit Customer' : 'Add New Customer'}</Text>
              <Pressable onPress={() => { setShowAddCustomer(false); setEditingCustomer(null); }}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>
            <ScrollView style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>Contact Person *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Ramesh Patel"
                value={custName}
                onChangeText={setCustName}
              />
              <Text style={styles.inputLabel}>Company Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. AutoTech Components"
                value={custCompany}
                onChangeText={setCustCompany}
              />
              <Text style={styles.inputLabel}>Phone Number</Text>
              <TextInput
                style={styles.input}
                placeholder="+91 ..."
                keyboardType="phone-pad"
                value={custPhone}
                onChangeText={setCustPhone}
              />
              <Text style={styles.inputLabel}>Email Address</Text>
              <TextInput
                style={styles.input}
                placeholder="email@company.com"
                keyboardType="email-address"
                value={custEmail}
                onChangeText={setCustEmail}
              />
              <Text style={styles.inputLabel}>Delivery Address</Text>
              <TextInput
                style={[styles.input, { height: 60 }]}
                placeholder="Full plant/warehouse delivery address"
                multiline
                value={custAddress}
                onChangeText={setCustAddress}
              />
              <Text style={styles.inputLabel}>GST Number</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 27AAAAA0000A1Z5"
                autoCapitalize="characters"
                value={custGst}
                onChangeText={setCustGst}
              />
            </ScrollView>
            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => { setShowAddCustomer(false); setEditingCustomer(null); }} />
              <Button label={editingCustomer ? 'Update Customer' : 'Save Customer'} onPress={handleSaveCustomer} />
            </View>
          </View>
        </View>
      </Modal>

      {/* Add / Edit Supplier Modal */}
      <Modal visible={showAddSupplier} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>{editingSupplier ? 'Edit Supplier' : 'Add New Supplier'}</Text>
              <Pressable onPress={() => { setShowAddSupplier(false); setEditingSupplier(null); }}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>
            <ScrollView style={{ maxHeight: 420 }}>
              <Text style={styles.inputLabel}>Supplier / Vendor Name *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Jindal Steel Works"
                value={suppName}
                onChangeText={setSuppName}
              />
              <Text style={styles.inputLabel}>Contact Person</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Vikas Sharma"
                value={suppContact}
                onChangeText={setSuppContact}
              />
              <Text style={styles.inputLabel}>Phone Number</Text>
              <TextInput
                style={styles.input}
                placeholder="+91 ..."
                keyboardType="phone-pad"
                value={suppPhone}
                onChangeText={setSuppPhone}
              />
              <Text style={styles.inputLabel}>Email Address</Text>
              <TextInput
                style={styles.input}
                placeholder="vendor@supplies.com"
                keyboardType="email-address"
                value={suppEmail}
                onChangeText={setSuppEmail}
              />
              <Text style={styles.inputLabel}>Supplied Items / Materials</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Steel Rods, O-Rings, Fasteners"
                value={suppItems}
                onChangeText={setSuppItems}
              />
              <Text style={styles.inputLabel}>GST Number</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. 27AAAAA0000A1Z5"
                autoCapitalize="characters"
                value={suppGst}
                onChangeText={setSuppGst}
              />
            </ScrollView>
            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => { setShowAddSupplier(false); setEditingSupplier(null); }} />
              <Button label={editingSupplier ? 'Update Supplier' : 'Save Supplier'} onPress={handleSaveSupplier} />
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
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  addBtn: {
    paddingHorizontal: 12,
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
    backgroundColor: colors.successBg,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.success,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 4,
  },
  infoText: {
    fontSize: 13,
    color: colors.textSecondary,
    flex: 1,
  },
  empty: {
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    color: colors.textMuted,
    fontSize: 15,
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
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  cardActionBtn: {
    width: 32,
    height: 32,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
