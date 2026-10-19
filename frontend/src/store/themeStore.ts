import AsyncStorage from '@react-native-async-storage/async-storage';
import { Appearance } from 'react-native';
import { create } from 'zustand';
import { applyThemeColors, lightColors, type ThemeColors } from '../theme/colors';

const ONBOARDING_KEY = 'onboarding_complete';
const THEME_MODE_KEY = 'app_theme_mode';

export type ThemeMode = 'Light' | 'Dark' | 'System';

type ThemeState = {
  themeMode: ThemeMode;
  isDark: boolean;
  colors: ThemeColors;
  onboardingComplete: boolean | null;
  setThemeMode: (mode: ThemeMode) => Promise<void>;
  hydrateTheme: () => Promise<void>;
  hydrateOnboarding: () => Promise<void>;
  completeOnboarding: () => Promise<void>;
};

function resolveIsDark(mode: ThemeMode): boolean {
  if (mode === 'Dark') return true;
  if (mode === 'Light') return false;
  return Appearance.getColorScheme() === 'dark';
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  themeMode: 'Light',
  isDark: false,
  colors: lightColors,
  onboardingComplete: null,

  setThemeMode: async (mode: ThemeMode) => {
    const isDark = resolveIsDark(mode);
    const activeColors = applyThemeColors(isDark);
    set({ themeMode: mode, isDark, colors: activeColors });
    try {
      await AsyncStorage.setItem(THEME_MODE_KEY, mode);
    } catch {
      // Ignore storage error
    }
  },

  hydrateTheme: async () => {
    try {
      const savedMode = (await AsyncStorage.getItem(THEME_MODE_KEY)) as ThemeMode | null;
      const mode = savedMode && ['Light', 'Dark', 'System'].includes(savedMode) ? savedMode : 'Light';
      const isDark = resolveIsDark(mode);
      const activeColors = applyThemeColors(isDark);
      set({ themeMode: mode, isDark, colors: activeColors });
    } catch {
      const isDark = false;
      const activeColors = applyThemeColors(isDark);
      set({ themeMode: 'Light', isDark, colors: activeColors });
    }
  },

  hydrateOnboarding: async () => {
    try {
      const value = await AsyncStorage.getItem(ONBOARDING_KEY);
      set({ onboardingComplete: value === 'true' });
    } catch {
      set({ onboardingComplete: false });
    }
  },

  completeOnboarding: async () => {
    try {
      await AsyncStorage.setItem(ONBOARDING_KEY, 'true');
    } catch {
      // Ignore
    }
    set({ onboardingComplete: true });
  },
}));
