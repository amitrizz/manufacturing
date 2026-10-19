import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { initializeDatabase } from './src/database/initializeDatabase';
import { RootNavigator } from './src/navigation/RootNavigator';
import { useAuthStore } from './src/store/authStore';
import { useSubscriptionStore } from './src/store/subscriptionStore';
import { useThemeStore } from './src/store/themeStore';
import { useLanguageStore } from './src/store/languageStore';
import { useUiStore } from './src/store/uiStore';
import { APP_DISPLAY_NAME } from './src/constants/app';
import { colors } from './src/theme';

export default function App() {
  const [bootError, setBootError] = useState<string | null>(null);
  const setDbReady = useUiStore((s) => s.setDbReady);
  const isDbReady = useUiStore((s) => s.isDbReady);
  const hydrateOnboarding = useThemeStore((s) => s.hydrateOnboarding);
  const hydrateTheme = useThemeStore((s) => s.hydrateTheme);
  const isDark = useThemeStore((s) => s.isDark);
  const onboardingComplete = useThemeStore((s) => s.onboardingComplete);
  const hydrateLanguage = useLanguageStore((s) => s.hydrateLanguage);
  const hydrateSubscription = useSubscriptionStore((s) => s.hydrateSubscription);
  const hydrateAuth = useAuthStore((s) => s.hydrateAuth);
  const isAuthHydrated = useAuthStore((s) => s.isHydrated);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await initializeDatabase();
        await Promise.all([
          hydrateTheme(),
          hydrateLanguage(),
          hydrateOnboarding(),
          hydrateSubscription(),
          hydrateAuth(),
        ]);
        if (!cancelled) {
          setDbReady(true);
        }
      } catch (e: unknown) {
        if (!cancelled) {
          setBootError(e instanceof Error ? e.message : 'Database initialization failed');
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [hydrateAuth, hydrateLanguage, hydrateOnboarding, hydrateSubscription, hydrateTheme, setDbReady]);

  const booting = !isDbReady || onboardingComplete === null || !isAuthHydrated;

  return (
    <SafeAreaProvider>
      <StatusBar style={isDark ? 'light' : 'dark'} />
      {booting && !bootError ? (
        <View style={styles.splash}>
          <Text style={styles.splashTitle}>{APP_DISPLAY_NAME}</Text>
          <Text style={styles.splashSub}>Connecting to backend API…</Text>
          <ActivityIndicator size="large" color={colors.primary} style={{ marginTop: 24 }} />
        </View>
      ) : bootError ? (
        <View style={styles.splash}>
          <Text style={styles.errorText}>{bootError}</Text>
        </View>
      ) : (
        <RootNavigator />
      )}
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  splash: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background,
    padding: 24,
  },
  errorText: {
    color: colors.danger,
    textAlign: 'center',
  },
  splashTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.text,
  },
  splashSub: {
    marginTop: 8,
    color: colors.textSecondary,
  },
});
