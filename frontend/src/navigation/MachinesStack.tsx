import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { MachineDetailScreen } from '../screens/machines/MachineDetailScreen';
import { MachineListScreen } from '../screens/machines/MachineListScreen';
import { ReportBreakdownScreen } from '../screens/machines/ReportBreakdownScreen';
import type { MachinesStackParamList } from './types';

const Stack = createNativeStackNavigator<MachinesStackParamList>();

export function MachinesStackNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="MachineList" component={MachineListScreen} options={{ title: 'Machines' }} />
      <Stack.Screen name="MachineDetail" component={MachineDetailScreen} options={{ title: 'Machine' }} />
      <Stack.Screen name="ReportBreakdown" component={ReportBreakdownScreen} options={{ title: 'Report breakdown' }} />
    </Stack.Navigator>
  );
}
