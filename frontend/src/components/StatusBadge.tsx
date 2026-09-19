import type { TaskStatus } from '../types';
import { statusLabel } from '../utils/status';

const STYLES: Record<TaskStatus, string> = {
  TODO: 'bg-amber-50 text-amber-700 ring-amber-200',
  IN_PROGRESS: 'bg-sky-50 text-sky-700 ring-sky-200',
  DONE: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
};

const DOT: Record<TaskStatus, string> = {
  TODO: 'bg-amber-500',
  IN_PROGRESS: 'bg-sky-500',
  DONE: 'bg-emerald-500',
};

export default function StatusBadge({ status }: { status: TaskStatus }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ring-inset ${STYLES[status]}`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${DOT[status]}`} />
      {statusLabel(status)}
    </span>
  );
}