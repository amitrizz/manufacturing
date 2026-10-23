import { create } from 'zustand';

type UiState = {
  isDbReady: boolean;
  setDbReady: (ready: boolean) => void;
};

export const useUiStore = create<UiState>((set) => ({
  isDbReady: false,
  setDbReady: (ready: boolean) => set({ isDbReady: ready }),
}));
