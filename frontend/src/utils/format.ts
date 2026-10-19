export function formatNumber(n: number | null | undefined, decimals = 0): string {
  if (n === null || n === undefined || typeof n !== 'number' || isNaN(n)) {
    return '0';
  }
  return n.toLocaleString(undefined, {
    maximumFractionDigits: decimals,
    minimumFractionDigits: decimals,
  });
}

export function formatPct(n: number, decimals = 1): string {
  return `${formatNumber(n, decimals)}%`;
}

export function formatDate(ts: number | null | undefined): string {
  if (!ts || isNaN(Number(ts))) return '-';
  return new Date(ts).toLocaleDateString();
}

export function formatDateTime(ts: number | null | undefined): string {
  if (!ts || isNaN(Number(ts))) return '-';
  return new Date(ts).toLocaleString();
}

export function formatTime(ts: number | null | undefined): string {
  if (!ts || isNaN(Number(ts))) return '-';
  return new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

const STATUS_LABELS: Record<string, string> = {
  IN_PROGRESS: 'Production in progress',
  PENDING: 'Pending',
  PLANNED: 'Planned',
};

/** Human-readable label for status badges (e.g. IN_PROGRESS → Production in progress). */
export function formatStatusLabel(status: string): string {
  return STATUS_LABELS[status] ?? status.replace(/_/g, ' ');
}
