/** Semantic colors aligned with modern manufacturing enterprise aesthetics. */
export const lightColors = {
  // Brand & Accents
  primary: '#1D4ED8', // Vibrant executive cobalt blue
  primaryDark: '#1E3A8A', // Deep navy cobalt
  primaryLight: '#3B82F6', // Crisp royal blue
  accent: '#0EA5E9', // Ocean blue accent

  // Neutral Canvas & Surfaces
  background: '#F8FAFC', // Slate-50 clean canvas
  surface: '#FFFFFF', // Pure white cards & modals
  surfaceSubtle: '#F1F5F9', // Slate-100 for secondary backgrounds
  border: '#E2E8F0', // Slate-200 clean hairline border
  borderSubtle: '#EDF2F7',

  // Typography Tokens
  text: '#0F172A', // Slate-900 high contrast dark charcoal
  textSecondary: '#475569', // Slate-600 readable secondary
  textMuted: '#94A3B8', // Slate-400 placeholder & micro-captions

  // Status Colors (WCAG AAA contrast friendly)
  success: '#059669', // Emerald green
  successBg: '#ECFDF5',
  warning: '#D97706', // Warm amber
  warningBg: '#FFFBEB',
  danger: '#DC2626', // Vibrant crimson / rose red
  dangerBg: '#FEF2F2',
  info: '#0284C7', // Sky blue
  infoBg: '#F0F9FF',

  // Machine Status Tokens
  machineRunning: '#059669',
  machineIdle: '#64748B',
  machineBreakdown: '#DC2626',
  machineMaintenance: '#D97706',
  machineOffline: '#475569',

  // Inventory Levels
  materialAvailable: '#059669',
  materialNearMinimum: '#D97706',
  materialShortage: '#DC2626',

  // Priorities
  priorityLow: '#64748B',
  priorityMedium: '#0284C7',
  priorityHigh: '#D97706',
  priorityCritical: '#DC2626',
};

export const darkColors: typeof lightColors = {
  // Brand & Accents
  primary: '#3B82F6', // Crisp royal blue (high contrast in dark)
  primaryDark: '#1D4ED8',
  primaryLight: '#60A5FA',
  accent: '#38BDF8',

  // Neutral Canvas & Surfaces
  background: '#0B1120', // Deep obsidian slate background
  surface: '#1E293B', // Slate 800 cards & modals
  surfaceSubtle: '#0F172A', // Slate 900
  border: '#334155', // Slate 700 border
  borderSubtle: '#1E293B',

  // Typography Tokens
  text: '#F8FAFC', // Slate 50 clean white text
  textSecondary: '#94A3B8', // Slate 400
  textMuted: '#64748B', // Slate 500

  // Status Colors (WCAG AAA contrast friendly)
  success: '#10B981',
  successBg: 'rgba(16, 185, 129, 0.15)',
  warning: '#F59E0B',
  warningBg: 'rgba(245, 158, 11, 0.15)',
  danger: '#EF4444',
  dangerBg: 'rgba(239, 68, 68, 0.15)',
  info: '#38BDF8',
  infoBg: 'rgba(56, 189, 248, 0.15)',

  // Machine Status Tokens
  machineRunning: '#10B981',
  machineIdle: '#94A3B8',
  machineBreakdown: '#EF4444',
  machineMaintenance: '#F59E0B',
  machineOffline: '#64748B',

  // Inventory Levels
  materialAvailable: '#10B981',
  materialNearMinimum: '#F59E0B',
  materialShortage: '#EF4444',

  // Priorities
  priorityLow: '#94A3B8',
  priorityMedium: '#38BDF8',
  priorityHigh: '#F59E0B',
  priorityCritical: '#EF4444',
};

export type ThemeColors = typeof lightColors;

/** Global mutable color registry to sync with existing static imports. */
export const colors: ThemeColors = { ...lightColors };

/** Applies active theme palette to global color object */
export function applyThemeColors(isDark: boolean): ThemeColors {
  const target = isDark ? darkColors : lightColors;
  Object.assign(colors, target);
  return target;
}
