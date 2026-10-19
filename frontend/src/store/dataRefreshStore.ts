import { create } from 'zustand';

type DataRefreshState = {
  revision: number;
  bumpDataRevision: () => void;
};

export const useDataRefreshStore = create<DataRefreshState>((set) => ({
  revision: 0,
  bumpDataRevision: () => set((state) => ({ revision: state.revision + 1 })),
}));

/** Call after any SQLite write so open screens reload without navigating away. */
export function notifyDataChanged(): void {
  useDataRefreshStore.getState().bumpDataRevision();
}
