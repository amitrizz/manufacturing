import { TextStyle } from 'react-native';
import { colors } from './colors';

export const typography = {
  h1: {
    fontSize: 26,
    fontWeight: '700' as TextStyle['fontWeight'],
    color: colors.text,
    lineHeight: 32,
    letterSpacing: -0.4,
  },
  h2: {
    fontSize: 20,
    fontWeight: '700' as TextStyle['fontWeight'],
    color: colors.text,
    lineHeight: 26,
    letterSpacing: -0.3,
  },
  h3: {
    fontSize: 16,
    fontWeight: '600' as TextStyle['fontWeight'],
    color: colors.text,
    lineHeight: 22,
    letterSpacing: -0.2,
  },
  body: {
    fontSize: 15,
    fontWeight: '400' as TextStyle['fontWeight'],
    color: colors.text,
    lineHeight: 22,
  },
  bodyMedium: {
    fontSize: 15,
    fontWeight: '500' as TextStyle['fontWeight'],
    color: colors.text,
    lineHeight: 22,
  },
  bodySmall: {
    fontSize: 13,
    fontWeight: '400' as TextStyle['fontWeight'],
    color: colors.textSecondary,
    lineHeight: 18,
  },
  caption: {
    fontSize: 11,
    fontWeight: '500' as TextStyle['fontWeight'],
    color: colors.textMuted,
    lineHeight: 15,
    letterSpacing: 0.2,
  },
  label: {
    fontSize: 12,
    fontWeight: '700' as TextStyle['fontWeight'],
    color: colors.textSecondary,
    lineHeight: 16,
    letterSpacing: 0.4,
    textTransform: 'uppercase' as TextStyle['textTransform'],
  },
} as const;

