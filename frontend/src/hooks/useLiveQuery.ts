import { useFocusEffect } from '@react-navigation/native';
import { useCallback, useEffect, useRef } from 'react';
import { useDataRefreshStore } from '../store/dataRefreshStore';

// Global last-run timestamp shared across all useLiveQuery instances
let globalLastRun = 0;
const globalTimeouts = new Set<ReturnType<typeof setTimeout>>();

/**
 * Re-runs `load` when the screen is focused and whenever app data changes (notifyDataChanged).
 * Includes a global debounce with jitter to prevent thundering herd when multiple screens trigger simultaneously.
 */
export function useLiveQuery(load: () => void | Promise<void>, debounceMs = 800): void {
  const revision = useDataRefreshStore((s) => s.revision);
  const loadRef = useRef(load);
  loadRef.current = load;

  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isMountedRef = useRef(true);

  const run = useCallback(() => {
    if (!isMountedRef.current) return;
    
    const now = Date.now();
    const timeSinceGlobalRun = now - globalLastRun;
    
    // Add jitter (0-200ms) to prevent thundering herd
    const jitter = Math.random() * 200;
    const effectiveDebounce = debounceMs + jitter;

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      globalTimeouts.delete(timeoutRef.current);
    }

    const executeLoad = () => {
      if (!isMountedRef.current) return;
      globalLastRun = Date.now();
      void loadRef.current();
    };

    if (timeSinceGlobalRun >= effectiveDebounce) {
      executeLoad();
    } else {
      timeoutRef.current = setTimeout(executeLoad, effectiveDebounce - timeSinceGlobalRun);
      globalTimeouts.add(timeoutRef.current);
    }
  }, [debounceMs]);

  useFocusEffect(
    useCallback(() => {
      isMountedRef.current = true;
      run();
    }, [run]),
  );

  useEffect(() => {
    if (isMountedRef.current) {
      run();
    }
  }, [run, revision]);

  // Cleanup on unmount
  useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
        globalTimeouts.delete(timeoutRef.current);
      }
    };
  }, []);
}
