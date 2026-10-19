import { useFocusEffect } from '@react-navigation/native';
import { useCallback, useEffect } from 'react';
import { useDataRefreshStore } from '../store/dataRefreshStore';

/**
 * Re-runs `load` when the screen is focused and whenever app data changes (notifyDataChanged).
 */
export function useLiveQuery(load: () => void | Promise<void>): void {
  const revision = useDataRefreshStore((s) => s.revision);

  const run = useCallback(() => {
    void load();
  }, [load]);

  useFocusEffect(
    useCallback(() => {
      run();
    }, [run]),
  );

  useEffect(() => {
    run();
  }, [run, revision]);
}
