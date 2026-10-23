import { useNavigation } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';
import { useCallback, useState } from 'react';
import {
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Card } from '../../components/common/Card';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { getDatabaseStats, type DatabaseStats } from '../../api/repositories/statsRepository';
import { colors, spacing } from '../../theme';

type ViewTab = 'pipeline' | 'roles' | 'checklist';

type PipelineStage = {
  id: string;
  stageNumber: number;
  title: string;
  badge: string;
  summary: string;
  color: string;
  bgColor: string;
  icon: keyof typeof Ionicons.glyphMap;
  keySteps: {
    title: string;
    description: string;
    whyItMatters: string;
    route: string;
    actionLabel: string;
    countKey?: keyof DatabaseStats;
    unit?: string;
  }[];
};

const PIPELINE_STAGES: PipelineStage[] = [
  {
    id: 'foundation',
    stageNumber: 1,
    title: 'Plant Foundation',
    badge: 'Stage 1 • Infrastructure',
    summary: 'Configure where work physically takes place and the team executing it.',
    color: '#0284C7',
    bgColor: '#E0F2FE',
    icon: 'business-outline',
    keySteps: [
      {
        title: 'Production Lines',
        description: 'Set up assembly, machining, and fabrication lines (e.g. Line A, Line B).',
        whyItMatters: 'Every machine and production order must belong to a line.',
        route: 'ProductionFloor',
        actionLabel: 'Open Floor & Lines',
        countKey: 'lines',
        unit: 'lines',
      },
      {
        title: 'Machine Fleet & Workstations',
        description: 'Add CNCs, presses, drills, and packaging units assigned to specific lines.',
        whyItMatters: 'Machines operate across 3 shifts (Morning, Evening, Night) to execute orders.',
        route: 'MachineList',
        actionLabel: 'Manage Machines',
        countKey: 'machines',
        unit: 'machines',
      },
      {
        title: 'Staff & Machine Operators',
        description: 'Register employees, operators, supervisors, and shift allocations.',
        whyItMatters: 'Output recording and shift allocation require active personnel records.',
        route: 'Staff',
        actionLabel: 'Manage Staff',
        countKey: 'staff',
        unit: 'staff',
      },
    ],
  },
  {
    id: 'supply',
    stageNumber: 2,
    title: 'Supply & Raw Materials',
    badge: 'Stage 2 • Inward Logistics',
    summary: 'Source, stock, and monitor raw materials before manufacturing starts.',
    color: '#D97706',
    bgColor: '#FEF3C7',
    icon: 'cube-outline',
    keySteps: [
      {
        title: 'Authorized Suppliers',
        description: 'Store contact details, tax IDs, and payment terms for material vendors.',
        whyItMatters: 'Purchase orders and material intake receipts connect directly to suppliers.',
        route: 'Contacts',
        actionLabel: 'View Suppliers',
        countKey: 'suppliers',
        unit: 'suppliers',
      },
      {
        title: 'Raw Material Inventory',
        description: 'Catalog sheet metal, plastic pellets, hardware with min/max stock alert levels.',
        whyItMatters: 'Prevents factory downtime by warning when stock dips below safe thresholds.',
        route: 'StockHome',
        actionLabel: 'View Inventory',
        countKey: 'materials',
        unit: 'items',
      },
      {
        title: 'Purchase Requests & POs',
        description: 'Raise purchase requests, approve orders, and record goods received notes (GRN).',
        whyItMatters: 'Restocks inventory automatically with audit trails and cost tracking.',
        route: 'PurchaseHome',
        actionLabel: 'Open Procurement',
      },
    ],
  },
  {
    id: 'engineering',
    stageNumber: 3,
    title: 'Products & BOM (Recipe)',
    badge: 'Stage 3 • Product Definition',
    summary: 'Define finished goods and their exact Bill of Materials (BOM).',
    color: '#7C3AED',
    bgColor: '#F5F3FF',
    icon: 'layers-outline',
    keySteps: [
      {
        title: 'Catalog Finished Products',
        description: 'Define the finished assemblies and products your factory sells.',
        whyItMatters: 'Forms the master catalog for planning, orders, and customer dispatch.',
        route: 'Products',
        actionLabel: 'View Products',
        countKey: 'products',
        unit: 'products',
      },
      {
        title: 'Bill of Materials (BOM)',
        description: 'Link each finished product to the exact raw materials required to make 1 unit.',
        whyItMatters: 'When an order is created, the system auto-calculates total material consumption.',
        route: 'Products',
        actionLabel: 'Configure BOM',
      },
    ],
  },
  {
    id: 'execution',
    stageNumber: 4,
    title: 'Production Planning & Execution',
    badge: 'Stage 4 • Shop Floor',
    summary: 'Schedule targets, release orders to machines, and log output per shift.',
    color: '#16A34A',
    bgColor: '#DCFCE7',
    icon: 'flash-outline',
    keySteps: [
      {
        title: 'Production Plans',
        description: 'Schedule multi-day or monthly production quotas on dedicated lines.',
        whyItMatters: 'Aligns production capacity with client sales commitments.',
        route: 'ProductionHub',
        actionLabel: 'Production Hub',
      },
      {
        title: 'Production Orders',
        description: 'Create active batches assigned to specific machines and target quantities.',
        whyItMatters: 'Floor workers cannot record output without an active order in progress.',
        route: 'ProductionOrders',
        actionLabel: 'View Orders',
        countKey: 'productionOrders',
        unit: 'orders',
      },
      {
        title: '3-Shift Output Recording',
        description: 'Log pieces completed by worker and shift (Morning, Evening, Night).',
        whyItMatters: 'Tracks exact machine efficiency, rejects, and worker productivity live.',
        route: 'ProductionFloor',
        actionLabel: 'Live Floor Output',
      },
    ],
  },
  {
    id: 'quality',
    stageNumber: 5,
    title: 'Quality & Machine Maintenance',
    badge: 'Stage 5 • Assurance & Uptime',
    summary: 'Ensure zero defects and keep equipment running at peak OEE.',
    color: '#059669',
    bgColor: '#ECFDF5',
    icon: 'shield-checkmark-outline',
    keySteps: [
      {
        title: 'Quality Inspections (QA)',
        description: 'Inspect sample pieces against tolerance criteria (PASS, FAIL, REWORK).',
        whyItMatters: 'Prevents defective batches from reaching finished inventory or clients.',
        route: 'QualityDashboard',
        actionLabel: 'QA Dashboard',
        countKey: 'inspections',
        unit: 'inspections',
      },
      {
        title: 'Maintenance & Downtime Tickets',
        description: 'Log mechanical breakdowns, electrical issues, and preventive service orders.',
        whyItMatters: 'Calculates true machine availability and logs downtime reasons for OEE.',
        route: 'Maintenance',
        actionLabel: 'Open Maintenance',
      },
    ],
  },
  {
    id: 'fulfillment',
    stageNumber: 6,
    title: 'Finished Goods & Dispatch',
    badge: 'Stage 6 • Revenue & Shipping',
    summary: 'Store completed items in warehouse, package, and dispatch to customers.',
    color: '#4F46E5',
    bgColor: '#EEF2FF',
    icon: 'paper-plane-outline',
    keySteps: [
      {
        title: 'Finished Goods Warehouse',
        description: 'Track available inventory of inspected, ready-to-sell products.',
        whyItMatters: 'Know exact available-to-promise inventory for sales orders.',
        route: 'FinishedGoods',
        actionLabel: 'Finished Goods',
        countKey: 'finishedGoods',
        unit: 'items',
      },
      {
        title: 'Customer Directory',
        description: 'Manage buyer addresses, contact persons, GST numbers, and delivery zones.',
        whyItMatters: 'Ensures delivery challans and shipments reach correct destinations.',
        route: 'Contacts',
        actionLabel: 'View Customers',
        countKey: 'customers',
        unit: 'customers',
      },
      {
        title: 'Dispatch Orders & Challans',
        description: 'Create delivery challans, deduct inventory, and mark orders fulfilled.',
        whyItMatters: 'Closes the loop from raw material intake to final customer fulfillment.',
        route: 'Dispatch',
        actionLabel: 'Open Dispatch',
        countKey: 'dispatches',
        unit: 'shipments',
      },
    ],
  },
];

type RolePlaybook = {
  role: string;
  title: string;
  avatar: string;
  color: string;
  bgColor: string;
  primaryResponsibility: string;
  dailyRoutine: string[];
  keyScreens: { label: string; route: string }[];
};

const ROLE_PLAYBOOKS: RolePlaybook[] = [
  {
    role: 'FACTORY_MANAGER',
    title: 'Plant Owner & General Manager',
    avatar: '👔',
    color: '#0A1E38',
    bgColor: '#E2E8F0',
    primaryResponsibility: 'Monitors overall factory output, OEE, downtime costs, and subscription status.',
    dailyRoutine: [
      'Check Home Dashboard for active production orders & overall output (pcs)',
      'Review Low Stock Alerts and approve high-priority purchase requests',
      'Inspect OEE analytics and machine availability trends',
      'Oversee monthly production plans and customer fulfillment timelines',
    ],
    keyScreens: [
      { label: 'Home Dashboard', route: 'Dashboard' },
      { label: 'Production Hub', route: 'ProductionHub' },
      { label: 'OEE Analytics', route: 'Oee' },
      { label: 'Costing & Reports', route: 'Reports' },
    ],
  },
  {
    role: 'SUPERVISOR',
    title: 'Production Floor Supervisor',
    avatar: '👷',
    color: '#0284C7',
    bgColor: '#E0F2FE',
    primaryResponsibility: 'Assigns operators to machines across 3 shifts and ensures target production is met.',
    dailyRoutine: [
      'Review active orders on the Floor and assign workers to Morning, Evening, and Night shifts',
      'Oversee hourly piece counts and assist operators with material feeds',
      'Log machine breakdown tickets immediately to alert the maintenance crew',
      'Hand over shift output counts to incoming shift supervisor',
    ],
    keyScreens: [
      { label: 'Floor & Shifts', route: 'ProductionFloor' },
      { label: 'Production Orders', route: 'ProductionOrders' },
      { label: 'Machine Fleet', route: 'MachineList' },
      { label: 'Maintenance Tickets', route: 'Maintenance' },
    ],
  },
  {
    role: 'STORE_KEEPER',
    title: 'Inventory & Store Incharge',
    avatar: '📦',
    color: '#D97706',
    bgColor: '#FEF3C7',
    primaryResponsibility: 'Manages raw material stock levels, receives incoming shipments, and raises POs.',
    dailyRoutine: [
      'Inspect Raw Material stock list for items below minimum threshold',
      'Raise Purchase Requests for low stock materials',
      'Receive supplier deliveries and log Goods Received Notes (GRN) to update stock',
      'Verify finished goods quantities transferred from the production floor',
    ],
    keyScreens: [
      { label: 'Stock & Inventory', route: 'StockHome' },
      { label: 'Purchases & POs', route: 'PurchaseHome' },
      { label: 'Finished Goods', route: 'FinishedGoods' },
      { label: 'Suppliers Directory', route: 'Contacts' },
    ],
  },
  {
    role: 'QUALITY_INSPECTOR',
    title: 'Quality Assurance (QA) Inspector',
    avatar: '🔬',
    color: '#16A34A',
    bgColor: '#DCFCE7',
    primaryResponsibility: 'Tests sample pieces, approves orders for production start, and inspects finished batches.',
    dailyRoutine: [
      'Review pending production orders waiting for QA approval',
      'Perform dimensional & leak testing on batch samples',
      'Mark batches as PASS, REWORK, or SCRAP with specific defect notes',
      'Release passed batches into the Finished Goods warehouse for shipping',
    ],
    keyScreens: [
      { label: 'Quality Dashboard', route: 'QualityDashboard' },
      { label: 'New Inspection', route: 'InspectionCreate' },
      { label: 'Rework Queue', route: 'ReworkList' },
    ],
  },
  {
    role: 'DISPATCH_MANAGER',
    title: 'Shipping & Dispatch Incharge',
    avatar: '🚚',
    color: '#4F46E5',
    bgColor: '#EEF2FF',
    primaryResponsibility: 'Generates delivery challans, packages inspected products, and coordinates customer transit.',
    dailyRoutine: [
      'Check Finished Goods inventory for completed orders ready to ship',
      'Generate Delivery Challans with vehicle number, driver details, and customer address',
      'Supervise loading and record dispatch confirmation to deduct FG stock',
      'Share dispatch notes and tracking details with the sales desk',
    ],
    keyScreens: [
      { label: 'Dispatch Hub', route: 'Dispatch' },
      { label: 'Create Challan', route: 'DispatchCreate' },
      { label: 'Finished Goods', route: 'FinishedGoods' },
      { label: 'Customer Directory', route: 'Contacts' },
    ],
  },
];

export function PlatformWorkflowScreen() {
  const navigation = useNavigation<NavigationProp<ParamListBase>>();
  const [activeTab, setActiveTab] = useState<ViewTab>('pipeline');
  const [stats, setStats] = useState<DatabaseStats | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const loadStats = useCallback(async () => {
    try {
      setRefreshing(true);
      const data = await getDatabaseStats();
      setStats(data);
    } catch (e) {
      console.error('Failed to load database stats:', e);
    } finally {
      setRefreshing(false);
    }
  }, []);

  useLiveQuery(loadStats);

  // Setup completion calculation
  const totalStages = 9;
  let completedCount = 0;
  if (stats) {
    if (stats.lines > 0) completedCount++;
    if (stats.machines > 0) completedCount++;
    if (stats.staff > 0) completedCount++;
    if (stats.suppliers > 0) completedCount++;
    if (stats.materials > 0) completedCount++;
    if (stats.products > 0) completedCount++;
    if (stats.productionOrders > 0) completedCount++;
    if (stats.inspections > 0) completedCount++;
    if (stats.finishedGoods > 0 || stats.dispatches > 0) completedCount++;
  }
  const completionPercent = Math.round((completedCount / totalStages) * 100);

  return (
    <View style={styles.container}>
      {/* Header Banner */}
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <Pressable style={styles.backBtn} onPress={() => navigation.goBack()}>
            <Ionicons name="arrow-back" size={20} color="#0A1E38" />
          </Pressable>
          <View style={{ flex: 1 }}>
            <Text style={styles.headerTitle}>Platform Working & Blueprint</Text>
            <Text style={styles.headerSubtitle}>
              Interactive visual guide to complete factory operations
            </Text>
          </View>
        </View>

        {/* View Switcher Tabs */}
        <View style={styles.tabsRow}>
          <Pressable
            style={[styles.tabBtn, activeTab === 'pipeline' && styles.tabBtnActive]}
            onPress={() => setActiveTab('pipeline')}
          >
            <Ionicons
              name="git-commit-outline"
              size={14}
              color={activeTab === 'pipeline' ? '#0A1E38' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'pipeline' && styles.tabTextActive]}>
              Factory Pipeline
            </Text>
          </Pressable>

          <Pressable
            style={[styles.tabBtn, activeTab === 'roles' && styles.tabBtnActive]}
            onPress={() => setActiveTab('roles')}
          >
            <Ionicons
              name="people-outline"
              size={14}
              color={activeTab === 'roles' ? '#0A1E38' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'roles' && styles.tabTextActive]}>
              Team Roles
            </Text>
          </Pressable>

          <Pressable
            style={[styles.tabBtn, activeTab === 'checklist' && styles.tabBtnActive]}
            onPress={() => setActiveTab('checklist')}
          >
            <Ionicons
              name="checkmark-circle-outline"
              size={14}
              color={activeTab === 'checklist' ? '#0A1E38' : colors.textSecondary}
            />
            <Text style={[styles.tabText, activeTab === 'checklist' && styles.tabTextActive]}>
              Live Setup ({completionPercent}%)
            </Text>
          </Pressable>
        </View>
      </View>

      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={loadStats} tintColor={colors.primary} />
        }
      >
        {/* TAB 1: VISUAL FACTORY PIPELINE */}
        {activeTab === 'pipeline' && (
          <View style={{ gap: spacing.md }}>
            {/* Interactive Visual Flow Bar */}
            <Card style={styles.flowCard}>
              <Text style={styles.flowCardTitle}>Visual End-to-End Factory Lifecycle</Text>
              <Text style={styles.flowCardSubtitle}>
                Data flows from physical setup to raw material intake, order production, and customer dispatch:
              </Text>

              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.flowScroll}>
                {PIPELINE_STAGES.map((st, idx) => (
                  <View key={st.id} style={styles.flowNodeWrapper}>
                    <View style={[styles.flowNode, { borderColor: st.color, backgroundColor: st.bgColor }]}>
                      <Ionicons name={st.icon} size={16} color={st.color} />
                      <Text style={[styles.flowNodeText, { color: st.color }]}>
                        {st.stageNumber}. {st.title}
                      </Text>
                    </View>
                    {idx < PIPELINE_STAGES.length - 1 && (
                      <Ionicons name="arrow-forward" size={14} color="#94A3B8" style={{ marginHorizontal: 4 }} />
                    )}
                  </View>
                ))}
              </ScrollView>
            </Card>

            {/* Stages Cards */}
            {PIPELINE_STAGES.map((stage) => (
              <Card key={stage.id} style={styles.stageCard}>
                {/* Stage Header */}
                <View style={styles.stageHeader}>
                  <View style={[styles.stageIconBox, { backgroundColor: stage.bgColor }]}>
                    <Ionicons name={stage.icon} size={20} color={stage.color} />
                  </View>
                  <View style={{ flex: 1 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                      <Text style={styles.stageTitle}>
                        Stage {stage.stageNumber}: {stage.title}
                      </Text>
                      <View style={[styles.stageBadge, { backgroundColor: stage.bgColor }]}>
                        <Text style={[styles.stageBadgeText, { color: stage.color }]}>
                          {stage.badge}
                        </Text>
                      </View>
                    </View>
                    <Text style={styles.stageSummary}>{stage.summary}</Text>
                  </View>
                </View>

                {/* Sub-steps in this stage */}
                <View style={styles.stepsContainer}>
                  {stage.keySteps.map((step, sIdx) => {
                    const count = step.countKey && stats ? stats[step.countKey] : undefined;

                    return (
                      <View key={sIdx} style={styles.stepRow}>
                        <View style={styles.stepBulletColumn}>
                          <View style={[styles.stepBullet, { backgroundColor: stage.color }]} />
                          {sIdx < stage.keySteps.length - 1 && <View style={styles.stepLine} />}
                        </View>

                        <View style={styles.stepDetails}>
                          <View style={styles.stepTitleRow}>
                            <Text style={styles.stepTitleText}>{step.title}</Text>
                            {count !== undefined && (
                              <View
                                style={[
                                  styles.liveCountBadge,
                                  count > 0 ? styles.liveCountBadgeActive : styles.liveCountBadgeZero,
                                ]}
                              >
                                <Text
                                  style={[
                                    styles.liveCountText,
                                    count > 0 ? styles.liveCountTextActive : styles.liveCountTextZero,
                                  ]}
                                >
                                  {count} {step.unit}
                                </Text>
                              </View>
                            )}
                          </View>

                          <Text style={styles.stepDescText}>{step.description}</Text>

                          <View style={styles.whyMattersBox}>
                            <Ionicons name="sparkles-outline" size={12} color="#0369A1" />
                            <Text style={styles.whyMattersText}>
                              <Text style={{ fontWeight: '700' }}>Why: </Text>
                              {step.whyItMatters}
                            </Text>
                          </View>

                          <Pressable
                            style={[styles.launchBtn, { backgroundColor: stage.bgColor }]}
                            onPress={() => navigation.navigate(step.route)}
                          >
                            <Ionicons name="open-outline" size={13} color={stage.color} />
                            <Text style={[styles.launchBtnText, { color: stage.color }]}>
                              {step.actionLabel}
                            </Text>
                          </Pressable>
                        </View>
                      </View>
                    );
                  })}
                </View>
              </Card>
            ))}
          </View>
        )}

        {/* TAB 2: ROLE PLAYBOOKS */}
        {activeTab === 'roles' && (
          <View style={{ gap: spacing.md }}>
            <Card style={styles.roleIntroCard}>
              <Ionicons name="people" size={24} color={colors.primary} />
              <View style={{ flex: 1 }}>
                <Text style={styles.roleIntroTitle}>Role-Based Operational Playbooks</Text>
                <Text style={styles.roleIntroDesc}>
                  See how different factory personnel interact with this platform daily:
                </Text>
              </View>
            </Card>

            {ROLE_PLAYBOOKS.map((p) => (
              <Card key={p.role} style={styles.roleCard}>
                <View style={styles.roleHeader}>
                  <Text style={styles.roleAvatar}>{p.avatar}</Text>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.roleName}>{p.title}</Text>
                    <Text style={styles.roleResp}>{p.primaryResponsibility}</Text>
                  </View>
                </View>

                {/* Routine */}
                <View style={styles.routineSection}>
                  <Text style={styles.routineTitle}>Standard Daily Routine:</Text>
                  {p.dailyRoutine.map((r, rIdx) => (
                    <View key={rIdx} style={styles.routineRow}>
                      <Ionicons name="checkmark-circle" size={14} color="#16A34A" />
                      <Text style={styles.routineText}>{r}</Text>
                    </View>
                  ))}
                </View>

                {/* Quick Launch Buttons for this Role */}
                <View style={styles.roleScreensSection}>
                  <Text style={styles.roleScreensTitle}>Core Workspaces:</Text>
                  <View style={styles.roleScreensRow}>
                    {p.keyScreens.map((s, sIdx) => (
                      <Pressable
                        key={sIdx}
                        style={[styles.roleScreenChip, { backgroundColor: p.bgColor }]}
                        onPress={() => navigation.navigate(s.route)}
                      >
                        <Text style={[styles.roleScreenChipText, { color: p.color }]}>
                          {s.label} →
                        </Text>
                      </Pressable>
                    ))}
                  </View>
                </View>
              </Card>
            ))}
          </View>
        )}

        {/* TAB 3: LIVE PLANT READINESS CHECKLIST */}
        {activeTab === 'checklist' && (
          <View style={{ gap: spacing.md }}>
            {/* Progress Card */}
            <Card style={styles.progressCard}>
              <View style={styles.progressHeader}>
                <View>
                  <Text style={styles.progressCardTitle}>Plant Readiness Score</Text>
                  <Text style={styles.progressCardSubtitle}>
                    {completedCount} of {totalStages} foundation modules configured
                  </Text>
                </View>
                <View style={styles.progressCircle}>
                  <Text style={styles.progressCircleText}>{completionPercent}%</Text>
                </View>
              </View>

              <View style={styles.progressBarTrack}>
                <View style={[styles.progressBarFill, { width: `${completionPercent}%` }]} />
              </View>

              <Text style={styles.progressNote}>
                {completionPercent === 100
                  ? '🎉 All core plant modules configured! Your factory is fully operational.'
                  : 'Complete the pending modules below to start full live production tracking.'}
              </Text>
            </Card>

            {/* Checklist Items */}
            <Card style={styles.checklistCard}>
              {[
                {
                  id: 'lines',
                  label: '1. Production Lines',
                  count: stats?.lines ?? 0,
                  unit: 'lines',
                  route: 'ProductionFloor',
                  action: '+ Add Line',
                },
                {
                  id: 'machines',
                  label: '2. Machines & Workstations',
                  count: stats?.machines ?? 0,
                  unit: 'machines',
                  route: 'MachineList',
                  action: '+ Add Machine',
                },
                {
                  id: 'staff',
                  label: '3. Staff & Machine Operators',
                  count: stats?.staff ?? 0,
                  unit: 'workers',
                  route: 'Staff',
                  action: '+ Add Staff',
                },
                {
                  id: 'suppliers',
                  label: '4. Raw Material Suppliers',
                  count: stats?.suppliers ?? 0,
                  unit: 'suppliers',
                  route: 'Contacts',
                  action: '+ Add Supplier',
                },
                {
                  id: 'materials',
                  label: '5. Raw Materials & Stock Intake',
                  count: stats?.materials ?? 0,
                  unit: 'materials',
                  route: 'StockHome',
                  action: '+ Add Item',
                },
                {
                  id: 'products',
                  label: '6. Finished Products & BOM',
                  count: stats?.products ?? 0,
                  unit: 'products',
                  route: 'Products',
                  action: '+ Add Product',
                },
                {
                  id: 'orders',
                  label: '7. Active Production Orders',
                  count: stats?.productionOrders ?? 0,
                  unit: 'orders',
                  route: 'ProductionOrders',
                  action: '+ New Order',
                },
                {
                  id: 'inspections',
                  label: '8. Quality Inspections (QA)',
                  count: stats?.inspections ?? 0,
                  unit: 'inspections',
                  route: 'QualityDashboard',
                  action: 'Inspect Order',
                },
                {
                  id: 'dispatches',
                  label: '9. Finished Goods & Dispatch',
                  count: (stats?.finishedGoods ?? 0) + (stats?.dispatches ?? 0),
                  unit: 'items / shipments',
                  route: stats?.finishedGoods ? 'FinishedGoods' : 'Dispatch',
                  action: stats?.finishedGoods ? 'View Goods' : '+ Dispatch Order',
                },
              ].map((item) => {
                const isReady = item.count > 0;
                return (
                  <View key={item.id} style={styles.checklistItemRow}>
                    <View style={styles.checklistLeft}>
                      <Ionicons
                        name={isReady ? 'checkmark-circle' : 'alert-circle'}
                        size={20}
                        color={isReady ? '#16A34A' : '#F59E0B'}
                      />
                      <View>
                        <Text style={styles.checklistLabel}>{item.label}</Text>
                        <Text
                          style={[
                            styles.checklistStatusText,
                            { color: isReady ? '#15803D' : '#D97706' },
                          ]}
                        >
                          {isReady ? `${item.count} ${item.unit} active` : 'Not configured yet'}
                        </Text>
                      </View>
                    </View>

                    <Pressable
                      style={[styles.checklistBtn, isReady ? styles.checklistBtnReady : styles.checklistBtnPending]}
                      onPress={() => navigation.navigate(item.route)}
                    >
                      <Text
                        style={[
                          styles.checklistBtnText,
                          { color: isReady ? '#0284C7' : '#FFFFFF' },
                        ]}
                      >
                        {item.action}
                      </Text>
                    </Pressable>
                  </View>
                );
              })}
            </Card>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: spacing.md,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  headerTop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: spacing.sm,
  },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0A1E38',
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  tabsRow: {
    flexDirection: 'row',
    backgroundColor: '#F1F5F9',
    padding: 3,
    borderRadius: 8,
    marginTop: 4,
  },
  tabBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    paddingVertical: 7,
    borderRadius: 6,
  },
  tabBtnActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
    elevation: 2,
  },
  tabText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  tabTextActive: {
    color: '#0A1E38',
    fontWeight: '800',
  },
  content: {
    padding: spacing.md,
    paddingBottom: 40,
  },
  flowCard: {
    padding: 12,
    backgroundColor: '#FFFFFF',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  flowCardTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0A1E38',
  },
  flowCardSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
    marginBottom: 8,
  },
  flowScroll: {
    flexDirection: 'row',
    marginVertical: 4,
  },
  flowNodeWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  flowNode: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 6,
    borderWidth: 1,
  },
  flowNodeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  stageCard: {
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  stageHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 12,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  stageIconBox: {
    width: 40,
    height: 40,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stageTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0A1E38',
  },
  stageBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  stageBadgeText: {
    fontSize: 9,
    fontWeight: '700',
  },
  stageSummary: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  stepsContainer: {
    gap: 10,
  },
  stepRow: {
    flexDirection: 'row',
    gap: 10,
  },
  stepBulletColumn: {
    alignItems: 'center',
    width: 14,
    paddingTop: 3,
  },
  stepBullet: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  stepLine: {
    width: 1.5,
    flex: 1,
    backgroundColor: '#E2E8F0',
    marginTop: 4,
  },
  stepDetails: {
    flex: 1,
  },
  stepTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  stepTitleText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0A1E38',
  },
  liveCountBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  liveCountBadgeActive: {
    backgroundColor: '#DCFCE7',
  },
  liveCountBadgeZero: {
    backgroundColor: '#FEF3C7',
  },
  liveCountText: {
    fontSize: 10,
    fontWeight: '700',
  },
  liveCountTextActive: {
    color: '#15803D',
  },
  liveCountTextZero: {
    color: '#B45309',
  },
  stepDescText: {
    fontSize: 11,
    color: '#475569',
    marginTop: 2,
    lineHeight: 15,
  },
  whyMattersBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F0F9FF',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 5,
    marginTop: 4,
  },
  whyMattersText: {
    fontSize: 10,
    color: '#0369A1',
    flex: 1,
  },
  launchBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    alignSelf: 'flex-start',
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 6,
    marginTop: 6,
  },
  launchBtnText: {
    fontSize: 11,
    fontWeight: '700',
  },
  roleIntroCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
    backgroundColor: '#FFFFFF',
    borderColor: '#BAE6FD',
  },
  roleIntroTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0A1E38',
  },
  roleIntroDesc: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  roleCard: {
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  roleHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 10,
  },
  roleAvatar: {
    fontSize: 28,
  },
  roleName: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0A1E38',
  },
  roleResp: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  routineSection: {
    backgroundColor: '#F8FAFC',
    padding: 10,
    borderRadius: 8,
    gap: 6,
    marginBottom: 10,
  },
  routineTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0A1E38',
    marginBottom: 2,
  },
  routineRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
  },
  routineText: {
    fontSize: 11,
    color: '#334155',
    flex: 1,
    lineHeight: 15,
  },
  roleScreensSection: {
    gap: 6,
  },
  roleScreensTitle: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  roleScreensRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  roleScreenChip: {
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 6,
  },
  roleScreenChipText: {
    fontSize: 11,
    fontWeight: '700',
  },
  progressCard: {
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderColor: '#BAE6FD',
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  progressCardTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0A1E38',
  },
  progressCardSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  progressCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#0284C7',
    alignItems: 'center',
    justifyContent: 'center',
  },
  progressCircleText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  progressBarTrack: {
    height: 6,
    backgroundColor: '#E2E8F0',
    borderRadius: 3,
    overflow: 'hidden',
    marginVertical: 4,
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#0284C7',
    borderRadius: 3,
  },
  progressNote: {
    fontSize: 11,
    color: '#475569',
    marginTop: 6,
    lineHeight: 15,
  },
  checklistCard: {
    padding: 0,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
  },
  checklistItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    gap: 8,
  },
  checklistLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    flex: 1,
  },
  checklistLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0A1E38',
  },
  checklistStatusText: {
    fontSize: 10,
    fontWeight: '600',
    marginTop: 1,
  },
  checklistBtn: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  checklistBtnReady: {
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  checklistBtnPending: {
    backgroundColor: colors.primary,
  },
  checklistBtnText: {
    fontSize: 11,
    fontWeight: '700',
  },
});
