import { create } from 'zustand';
import type { DatePreset } from '../utils/dateRange';

type FilterState = {
  dashboardDatePreset: DatePreset;
  customRangeStart: number | null;
  customRangeEnd: number | null;
  setDashboardDatePreset: (preset: DatePreset) => void;
  setCustomRange: (start: number, end: number) => void;
};

export const useFilterStore = create<FilterState>((set) => ({
  dashboardDatePreset: 'today',
  customRangeStart: null,
  customRangeEnd: null,
  setDashboardDatePreset: (preset) => set({ dashboardDatePreset: preset }),
  setCustomRange: (start, end) =>
    set({ customRangeStart: start, customRangeEnd: end, dashboardDatePreset: 'custom' }),
}));
