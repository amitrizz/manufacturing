import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

export type SubscriptionState = 'TRIAL' | 'PAID' | 'GRACE' | 'EXPIRED';

const STORAGE_KEY_STATUS = '@mfg_sub_status';
const STORAGE_KEY_TRIAL_START = '@mfg_trial_start';

const TRIAL_DURATION_DAYS = 14;
const GRACE_PERIOD_DAYS = 7;

type SubscriptionStore = {
  status: SubscriptionState;
  daysRemaining: number;
  isReadOnly: boolean;
  hydrateSubscription: () => Promise<void>;
  simulateStatus: (status: SubscriptionState) => Promise<void>;
  renewSubscription: () => Promise<void>;
  checkCanWrite: () => boolean;
};

export const useSubscriptionStore = create<SubscriptionStore>((set, get) => ({
  status: 'TRIAL',
  daysRemaining: 14,
  isReadOnly: false,

  hydrateSubscription: async () => {
    try {
      let storedStatus = (await AsyncStorage.getItem(STORAGE_KEY_STATUS)) as SubscriptionState | null;
      let trialStartStr = await AsyncStorage.getItem(STORAGE_KEY_TRIAL_START);

      const now = Date.now();
      if (!trialStartStr) {
        trialStartStr = now.toString();
        await AsyncStorage.setItem(STORAGE_KEY_TRIAL_START, trialStartStr);
        storedStatus = 'TRIAL';
        await AsyncStorage.setItem(STORAGE_KEY_STATUS, 'TRIAL');
      }

      if (storedStatus === 'PAID') {
        set({ status: 'PAID', daysRemaining: 365, isReadOnly: false });
        return;
      }

      const trialStart = parseInt(trialStartStr, 10);
      const daysSinceStart = Math.floor((now - trialStart) / (1000 * 60 * 60 * 24));

      if (daysSinceStart <= TRIAL_DURATION_DAYS) {
        // Active Trial
        const rem = TRIAL_DURATION_DAYS - daysSinceStart;
        set({ status: 'TRIAL', daysRemaining: rem, isReadOnly: false });
      } else if (daysSinceStart <= TRIAL_DURATION_DAYS + GRACE_PERIOD_DAYS) {
        // In 7-day Grace Period
        const graceRem = TRIAL_DURATION_DAYS + GRACE_PERIOD_DAYS - daysSinceStart;
        set({ status: 'GRACE', daysRemaining: graceRem, isReadOnly: false });
      } else {
        // Grace period expired -> Read-Only Mode enforced!
        set({ status: 'EXPIRED', daysRemaining: 0, isReadOnly: true });
      }
    } catch {
      // Fallback
      set({ status: 'TRIAL', daysRemaining: 14, isReadOnly: false });
    }
  },

  simulateStatus: async (newStatus: SubscriptionState) => {
    await AsyncStorage.setItem(STORAGE_KEY_STATUS, newStatus);
    const isReadOnly = newStatus === 'EXPIRED';
    const days = newStatus === 'PAID' ? 365 : newStatus === 'GRACE' ? 3 : newStatus === 'TRIAL' ? 10 : 0;
    set({ status: newStatus, daysRemaining: days, isReadOnly });
  },

  renewSubscription: async () => {
    await AsyncStorage.setItem(STORAGE_KEY_STATUS, 'PAID');
    set({ status: 'PAID', daysRemaining: 365, isReadOnly: false });
  },

  checkCanWrite: () => {
    return !get().isReadOnly;
  },
}));
