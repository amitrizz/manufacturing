import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { InspectionCreateScreen } from '../screens/quality/InspectionCreateScreen';
import { QualityDashboardScreen } from '../screens/quality/QualityDashboardScreen';
import { ReworkListScreen } from '../screens/quality/ReworkListScreen';
import type { QualityStackParamList } from './types';

const Stack = createNativeStackNavigator<QualityStackParamList>();

export function QualityStackNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="QualityDashboard" component={QualityDashboardScreen} options={{ title: 'Quality' }} />
      <Stack.Screen name="InspectionCreate" component={InspectionCreateScreen} options={{ title: 'Inspection' }} />
      <Stack.Screen name="ReworkList" component={ReworkListScreen} options={{ title: 'Rework' }} />
    </Stack.Navigator>
  );
}
