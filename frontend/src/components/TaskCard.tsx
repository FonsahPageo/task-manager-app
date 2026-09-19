import { Pencil, Trash2 } from 'lucide-react';
import type { Task } from '../types';
import StatusBadge from './StatusBadge';
import { formatDate, shortId } from '../utils/status';

interface TaskCardProps {
  task: Task;
  onEdit: (task: Task) => void;
  onDelete: (task: Task) => void;
}

export default function TaskCard({ task, onEdit, onDelete }: TaskCardProps) {
  return (
    <article className="group flex flex-col gap-3 rounded-xl border border-slate-200 bg-white p-4 shadow-sm transition hover:border-indigo-200 hover:shadow-md sm:p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="truncate text-base font-semibold text-slate-800" title={task.title}>
            {task.title}
          </h3>
          <p className="mt-0.5 text-xs font-medium text-slate-400">
            {shortId(task.id)} · Created {formatDate(task.createdAt)}
          </p>
        </div>
        <StatusBadge status={task.status} />
      </div>

      {task.description && (
        <p className="whitespace-pre-wrap break-words text-sm leading-relaxed text-slate-600 line-clamp-3">
          {task.description}
        </p>
      )}

      {!task.description && <p className="text-sm italic text-slate-400">No description</p>}

      <div className="mt-1 flex items-center justify-between border-t border-slate-100 pt-3">
        <span className="text-xs text-slate-400">Updated {formatDate(task.updatedAt)}</span>
        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => onEdit(task)}
            className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-semibold text-slate-600 transition hover:bg-indigo-50 hover:text-indigo-700"
          >
            <Pencil className="h-3.5 w-3.5" />
            Edit
          </button>
          <button
            type="button"
            onClick={() => onDelete(task)}
            className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-semibold text-slate-600 transition hover:bg-red-50 hover:text-red-700"
          >
            <Trash2 className="h-3.5 w-3.5" />
            Delete
          </button>
        </div>
      </div>
    </article>
  );
}