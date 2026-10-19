import type { NavigationProp, ParamListBase } from '@react-navigation/native';

export function navigateToActivityReference(
  navigation: NavigationProp<ParamListBase>,
  referenceType: string | null | undefined,
  referenceId: string | null | undefined,
): boolean {
  if (!referenceType || !referenceId) {
    return false;
  }

  const navTo = (screen: string, params?: Record<string, unknown>) => {
    try {
      navigation.navigate(screen, params);
    } catch {
      navigation.navigate('Home', { screen, params });
    }
  };

  switch (referenceType.toLowerCase()) {
    case 'production_order':
    case 'order':
      navTo('ProductionOrderDetail', { orderId: referenceId });
      return true;
    case 'maintenance_order':
      navTo('MachineList');
      return true;
    case 'rework_order':
      navTo('ReworkList');
      return true;
    case 'quality_inspection':
      navTo('QualityDashboard');
      return true;
    case 'dispatch_order':
    case 'dispatch':
      navTo('Dispatch');
      return true;
    case 'machine':
      navTo('MachineDetail', { machineId: referenceId });
      return true;
    case 'material':
      navTo('MaterialDetail', { materialId: referenceId });
      return true;
    case 'customer':
    case 'supplier':
      navTo('Contacts');
      return true;
    case 'purchase_order':
    case 'purchase_request':
    case 'grn':
      navTo('PurchaseHome');
      return true;
    case 'staff':
      navTo('Staff');
      return true;
    default:
      return false;
  }
}
