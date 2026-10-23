import { create } from 'zustand';

type DataRefreshState = {
  revision: number;
  notifyDataChanged: () => void;
};

export const useDataRefreshStore = create<DataRefreshState>((set) => ({
  revision: 0,
  notifyDataChanged: () => set((state) => ({ revision: state.revision + 1 })),
}));

export function notifyDataChanged(): void {
  useDataRefreshStore.getState().notifyDataChanged();
}
