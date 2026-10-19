import type { RootTabParamList } from '../navigation/types';

export type TaskRoute = {
  tab: keyof RootTabParamList;
  screen: string;
  params?: Record<string, string>;
};

export type QuickActionKind = 'dispatch' | 'complete_rework';

export type ActionableTask = {
  id: string;
  category: 'Production' | 'Maintenance' | 'Quality' | 'Dispatch' | 'Machines' | 'Materials';
  title: string;
  subtitle: string;
  status: string;
  route: TaskRoute;
  quickAction?: QuickActionKind;
  referenceId: string;
};
