import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { SearchField } from '../../components/common/SearchField';
import { deleteProduct, listProducts } from '../../database/repositories/productRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';
import type { ProductRow } from '../../types/database';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<MoreStackParamList, 'Products'>;

export function ProductListScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [products, setProducts] = useState<ProductRow[]>([]);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    const all = await listProducts();
    const q = search.trim().toLowerCase();
    if (!q) {
      setProducts(all);
      return;
    }
    setProducts(
      all.filter(
        (p) =>
          p.code.toLowerCase().includes(q) ||
          p.name.toLowerCase().includes(q) ||
          (p.description?.toLowerCase().includes(q) ?? false),
      ),
    );
  }, [search]);

  useLiveQuery(load);

  const handleDeleteProduct = (product: ProductRow) => {
    Alert.alert(
      'Delete Product',
      `Are you sure you want to delete "${product.name}" (${product.code})? This will also remove its associated BOM and finished goods records.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteProduct(product.id);
              Alert.alert('Deleted', `Product ${product.code} has been deleted.`);
              await load();
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

  return (
    <View style={styles.container}>
      {isViewOnly && (
        <ViewModeBanner
          message="Products catalog viewing mode. Creating, editing, and deleting products are disabled. Use the Management tab to make changes."
        />
      )}

      <View style={styles.topActionsRow}>
        {!isViewOnly && (
          <Button
            label="+ New Product"
            onPress={() => navigation.navigate('ProductCreate')}
            style={{ flex: 1 }}
          />
        )}
        <Button
          label="BOM Matrix"
          variant="secondary"
          onPress={() => navigation.navigate('ProductBom', { viewOnly: isViewOnly })}
          style={isViewOnly ? { flex: 1 } : undefined}
        />
      </View>

      <SearchField value={search} onChangeText={setSearch} placeholder="Search products by code/name…" />

      <FlatList
        data={products}
        keyExtractor={(p) => p.id}
        onRefresh={load}
        refreshing={false}
        contentContainerStyle={{ paddingBottom: 24, gap: spacing.xs }}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="pricetags-outline" size={36} color={colors.textMuted} />
            <Text style={styles.emptyText}>No products found</Text>
          </View>
        }
        renderItem={({ item }) => (
          <Card style={styles.productCard}>
            <View style={styles.cardHeader}>
              <View style={{ flex: 1 }}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Text style={styles.productCode}>{item.code}</Text>
                  <View style={styles.unitBadge}>
                    <Text style={styles.unitBadgeText}>{item.unit}</Text>
                  </View>
                </View>
                <Text style={styles.productName}>{item.name}</Text>
              </View>
            </View>

            {item.description ? (
              <Text style={styles.productDesc} numberOfLines={2}>
                {item.description}
              </Text>
            ) : null}

            {/* Action buttons: Edit & Delete (Hidden in viewOnly mode) */}
            {!isViewOnly && (
              <View style={styles.actionRow}>
                <Pressable
                  style={styles.editBtn}
                  onPress={() => navigation.navigate('ProductEdit', { productId: item.id })}
                >
                  <Ionicons name="create-outline" size={15} color="#0A1E38" />
                  <Text style={styles.editBtnText}>Edit</Text>
                </Pressable>

                <Pressable
                  style={styles.deleteBtn}
                  onPress={() => handleDeleteProduct(item)}
                >
                  <Ionicons name="trash-outline" size={15} color={colors.danger} />
                  <Text style={styles.deleteBtnText}>Delete</Text>
                </Pressable>
              </View>
            )}
          </Card>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: spacing.md,
    gap: spacing.sm,
  },
  topActionsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  productCard: {
    padding: 14,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    backgroundColor: colors.surface,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 1.5,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  productCode: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.primary,
    letterSpacing: 0.2,
  },
  unitBadge: {
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: '#BFDBFE',
    paddingHorizontal: 7,
    paddingVertical: 1.5,
    borderRadius: 6,
  },
  unitBadgeText: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.primary,
  },
  productName: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.text,
    marginTop: 2,
  },
  productDesc: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 4,
    lineHeight: 16,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 8,
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  editBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingVertical: 6,
    paddingHorizontal: 12,
  },
  editBtnText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: colors.text,
  },
  deleteBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FECACA',
    borderRadius: 8,
    paddingVertical: 6,
    paddingHorizontal: 12,
  },
  deleteBtnText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: colors.danger,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
    gap: 8,
  },
  emptyText: {
    fontSize: 13,
    color: colors.textMuted,
  },
});

