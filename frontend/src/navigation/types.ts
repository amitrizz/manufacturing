export type RootTabParamList = {
  Home: undefined;
  MyTasks: undefined;
  Management: undefined;
  Profile: undefined;
};

export type RootStackParamList = HomeStackParamList & {
  Main: undefined;
  FirstLaunch: undefined;
  Login: undefined;
};

export type HomeStackParamList = {
  Dashboard: undefined;
  Management: undefined;
  ProductionOrders: { viewOnly?: boolean } | undefined;
  ProductionOrderCreate: undefined;
  ProductionOrderDetail: { orderId: string; viewOnly?: boolean; autoOpenStartModal?: boolean };
  ProductionFloor: { viewOnly?: boolean } | undefined;
  RecordProduction: { orderId?: string; machineId?: string; viewOnly?: boolean };
  StockHome: { viewOnly?: boolean } | undefined;
  Materials: { viewOnly?: boolean } | undefined;
  MaterialDetail: { materialId: string; viewOnly?: boolean };
  PurchaseHome: { viewOnly?: boolean } | undefined;
  MachineList: { viewOnly?: boolean } | undefined;
  MachineDetail: { machineId: string; viewOnly?: boolean };
  ReportBreakdown: { machineId: string; viewOnly?: boolean };
  Staff: { viewOnly?: boolean } | undefined;
  QualityDashboard: { viewOnly?: boolean } | undefined;
  InspectionCreate: { orderId?: string; viewOnly?: boolean } | undefined;
  ReworkList: { viewOnly?: boolean } | undefined;
  Dispatch: { viewOnly?: boolean } | undefined;
  DispatchCreate: undefined;
  Reports: { viewOnly?: boolean } | undefined;
  Oee: { viewOnly?: boolean } | undefined;
  Contacts: { viewOnly?: boolean } | undefined;
  Notifications: undefined;
  Settings: undefined;
  GlobalSearch: { viewOnly?: boolean } | undefined;
  ActivityHistory: undefined;
  ProductionHub: { viewOnly?: boolean } | undefined;
  ProductionPlans: { viewOnly?: boolean } | undefined;
  ProductionPlanCreate: undefined;
  ProductionPlanDetail: { planId: string; viewOnly?: boolean };
  Products: { viewOnly?: boolean } | undefined;
  ProductBom: { productId?: string; viewOnly?: boolean };
  ProductCreate: undefined;
  ProductEdit: { productId: string; viewOnly?: boolean };
  Maintenance: { viewOnly?: boolean } | undefined;
  MaintenanceDetail: { orderId: string; viewOnly?: boolean };
  FinishedGoods: { viewOnly?: boolean } | undefined;
  RolesList: { viewOnly?: boolean } | undefined;
  PlatformWorkflow: undefined;
};

export type ProductionStackParamList = {
  ProductionHub: { viewOnly?: boolean } | undefined;
  ProductionPlans: { viewOnly?: boolean } | undefined;
  ProductionPlanCreate: undefined;
  ProductionPlanDetail: { planId: string; viewOnly?: boolean };
  ProductionOrders: { viewOnly?: boolean } | undefined;
  ProductionOrderCreate: undefined;
  ProductionOrderDetail: { orderId: string; viewOnly?: boolean; autoOpenStartModal?: boolean };
  ProductionFloor: { viewOnly?: boolean } | undefined;
  RecordProduction: { orderId?: string; machineId?: string; viewOnly?: boolean };
};

export type MachinesStackParamList = {
  MachineList: { viewOnly?: boolean } | undefined;
  MachineDetail: { machineId: string; viewOnly?: boolean };
  ReportBreakdown: { machineId: string; viewOnly?: boolean };
};

export type QualityStackParamList = {
  QualityDashboard: { viewOnly?: boolean } | undefined;
  InspectionCreate: { orderId?: string; viewOnly?: boolean } | undefined;
  ReworkList: { viewOnly?: boolean } | undefined;
};

export type MoreStackParamList = {
  MoreMenu: undefined;
  Maintenance: { viewOnly?: boolean } | undefined;
  MaintenanceDetail: { orderId: string; viewOnly?: boolean };
  Materials: { viewOnly?: boolean } | undefined;
  MaterialDetail: { materialId: string; viewOnly?: boolean };
  Products: { viewOnly?: boolean } | undefined;
  ProductBom: { productId?: string; viewOnly?: boolean };
  ProductCreate: undefined;
  ProductEdit: { productId: string; viewOnly?: boolean };
  FinishedGoods: { viewOnly?: boolean } | undefined;
  Dispatch: { viewOnly?: boolean } | undefined;
  DispatchCreate: undefined;
  Reports: { viewOnly?: boolean } | undefined;
  Oee: { viewOnly?: boolean } | undefined;
  Settings: undefined;
  GlobalSearch: { viewOnly?: boolean } | undefined;
  Notifications: undefined;
  ActivityHistory: undefined;
  PlatformWorkflow: undefined;
};
