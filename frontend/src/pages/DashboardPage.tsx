import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ClipboardList,
  LogOut,
  Plus,
  Search,
  X,
  ListTodo,
  Loader2,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import { ApiError } from '../api/client';
import { createTask, deleteTask, fetchTasks, updateTask } from '../api/tasks';
import type { Task, TaskPayload, TaskStatus } from '../types';
import TaskCard from '../components/TaskCard';
import TaskModal from '../components/TaskModal';
import Spinner from '../components/Spinner';
import EmptyState from '../components/EmptyState';

type StatusFilter = TaskStatus | 'ALL';

const FILTERS: { value: StatusFilter; label: string }[] = [
  { value: 'ALL', label: 'All' },
  { value: 'TODO', label: 'To Do' },
  { value: 'IN_PROGRESS', label: 'In Progress' },
  { value: 'DONE', label: 'Done' },
];

const FILTER_ICON_CLASSES: Record<string, string> = {
  ALL: 'bg-indigo-100 text-indigo-700',
  TODO: 'bg-amber-100 text-amber-700',
  IN_PROGRESS: 'bg-sky-100 text-sky-700',
  DONE: 'bg-emerald-100 text-emerald-700',
};

export default function DashboardPage() {
  const { user, logout } = useAuth();
  const { showToast } = useToast();

  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('ALL');
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<Task | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchTerm.trim()), 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const loadTasks = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const data = await fetchTasks({
        status: statusFilter === 'ALL' ? '' : statusFilter,
        search: debouncedSearch || undefined,
      });
      setTasks(data);
    } catch (err) {
      const message =
        err instanceof ApiError ? err.message : 'Failed to load tasks. Please try again.';
      setLoadError(message);
      showToast('error', message);
    } finally {
      setLoading(false);
    }
  }, [statusFilter, debouncedSearch, showToast]);

  useEffect(() => {
    void loadTasks();
  }, [loadTasks]);

  const counts = useMemo(() => {
    const todo = tasks.filter((t) => t.status === 'TODO').length;
    const inProgress = tasks.filter((t) => t.status === 'IN_PROGRESS').length;
    const done = tasks.filter((t) => t.status === 'DONE').length;
    return { todo, inProgress, done };
  }, [tasks]);

  const countForFilter = (filter: StatusFilter): number => {
    switch (filter) {
      case 'TODO':
        return counts.todo;
      case 'IN_PROGRESS':
        return counts.inProgress;
      case 'DONE':
        return counts.done;
      default:
        return tasks.length;
    }
  };

  const openCreateModal = () => {
    setEditingTask(null);
    setModalError(null);
    setModalOpen(true);
  };

  const openEditModal = (task: Task) => {
    setEditingTask(task);
    setModalError(null);
    setModalOpen(true);
  };

  const handleCloseModal = () => {
    if (submitting) return;
    setModalOpen(false);
    setEditingTask(null);
    setModalError(null);
  };

  const handleSubmitTask = async (payload: TaskPayload) => {
    setSubmitting(true);
    setModalError(null);
    try {
      if (editingTask) {
        const updated = await updateTask(editingTask.id, payload);
        setTasks((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
        showToast('success', 'Task updated successfully.');
      } else {
        const created = await createTask(payload);
        setTasks((prev) => [created, ...prev]);
        showToast('success', 'Task created successfully.');
      }
      setModalOpen(false);
      setEditingTask(null);
    } catch (err) {
      const message =
        err instanceof ApiError ? err.message : 'Could not save the task. Please try again.';
      setModalError(message);
      showToast('error', message);
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = async () => {
    if (!pendingDelete) return;
    setDeleting(true);
    try {
      await deleteTask(pendingDelete.id);
      setTasks((prev) => prev.filter((t) => t.id !== pendingDelete.id));
      showToast('success', 'Task deleted.');
      setPendingDelete(null);
    } catch (err) {
      const message =
        err instanceof ApiError ? err.message : 'Could not delete the task. Please try again.';
      showToast('error', message);
    } finally {
      setDeleting(false);
    }
  };

  const handleLogout = () => {
    logout();
    showToast('info', 'Signed out.');
  };

  const firstName = user?.fullName.split(' ')[0] ?? 'there';

  return (
    <div className="min-h-screen bg-slate-100">
      <header className="sticky top-0 z-30 border-b border-slate-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3 sm:px-6">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600">
              <ClipboardList className="h-5 w-5 text-white" />
            </div>
            <div className="hidden sm:block">
              <h1 className="text-sm font-bold text-slate-800">Task Manager</h1>
              <p className="text-xs text-slate-400">Web app</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="hidden text-right sm:block">
              <p className="text-sm font-semibold text-slate-700">{user?.fullName}</p>
              <p className="text-xs text-slate-400">{user?.email}</p>
            </div>
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-indigo-100 text-sm font-bold text-indigo-700">
              {(user?.fullName ?? 'U')
                .split(' ')
                .map((part) => part[0])
                .slice(0, 2)
                .join('')
                .toUpperCase()}
            </div>
            <button
              type="button"
              onClick={handleLogout}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
              title="Sign out"
            >
              <LogOut className="h-4 w-4" />
              <span className="hidden sm:inline">Sign out</span>
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-6 sm:px-6">
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 className="text-xl font-bold text-slate-800">Good day, {firstName}</h2>
              <p className="mt-0.5 text-sm text-slate-500">Here are your tasks for today.</p>
            </div>
            <button
              type="button"
              onClick={openCreateModal}
              className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700"
            >
              <Plus className="h-4 w-4" />
              Add Task
            </button>
          </div>

          <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex flex-wrap gap-2">
              {FILTERS.map((filter) => {
                const active = statusFilter === filter.value;
                const count = countForFilter(filter.value);
                return (
                  <button
                    key={filter.value}
                    type="button"
                    onClick={() => setStatusFilter(filter.value)}
                    className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-semibold transition ${
                      active
                        ? FILTER_ICON_CLASSES[filter.value]
                        : 'bg-white text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {filter.label}
                    <span className="text-xs opacity-70">({count})</span>
                  </button>
                );
              })}
            </div>

            <div className="relative w-full lg:w-72">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="search"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search tasks..."
                className="w-full rounded-lg border border-slate-300 bg-white py-2 pl-9 pr-8 text-sm text-slate-800 shadow-sm placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
              />
              {searchTerm && (
                <button
                  type="button"
                  onClick={() => setSearchTerm('')}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 rounded p-0.5 text-slate-400 hover:text-slate-600"
                  aria-label="Clear search"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>

          {loading && <Spinner label="Loading tasks" />}

          {!loading && loadError && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
              <p className="text-sm font-medium text-red-700">{loadError}</p>
              <button
                type="button"
                onClick={() => void loadTasks()}
                className="mt-2 inline-flex items-center gap-2 rounded-lg border border-red-200 bg-white px-3 py-1.5 text-sm font-semibold text-red-700 transition hover:bg-red-100"
              >
                <Loader2 className="h-4 w-4" />
                Try again
              </button>
            </div>
          )}

          {!loading && !loadError && tasks.length === 0 && (
            <EmptyState
              title={searchTerm || statusFilter !== 'ALL' ? 'No tasks match your filters' : 'No tasks yet'}
              subtitle={
                searchTerm || statusFilter !== 'ALL'
                  ? 'Try adjusting your search or status filter.'
                  : 'Create your first task to get started.'
              }
              action={
                searchTerm || statusFilter !== 'ALL' ? (
                  <button
                    type="button"
                    onClick={() => {
                      setSearchTerm('');
                      setStatusFilter('ALL');
                    }}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                  >
                    <ListTodo className="h-4 w-4" />
                    Clear filters
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={openCreateModal}
                    className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white transition hover:bg-indigo-700"
                  >
                    <Plus className="h-4 w-4" />
                    Create task
                  </button>
                )
              }
            />
          )}

          {!loading && tasks.length > 0 && (
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
              {tasks.map((task) => (
                <TaskCard
                  key={task.id}
                  task={task}
                  onEdit={openEditModal}
                  onDelete={(t) => setPendingDelete(t)}
                />
              ))}
            </div>
          )}
        </div>
      </main>

      <TaskModal
        open={modalOpen}
        task={editingTask}
        submitting={submitting}
        onSubmit={handleSubmitTask}
        onClose={handleCloseModal}
        error={modalError}
      />

      {pendingDelete && (
        <div className="fixed inset-0 z-40 flex items-center justify-center p-4">
          <div
            className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm"
            onClick={() => setPendingDelete(null)}
            aria-hidden="true"
          />
          <div
            role="alertdialog"
            aria-modal="true"
            className="relative z-10 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl"
          >
            <h3 className="text-base font-semibold text-slate-800">Delete task?</h3>
            <p className="mt-1.5 text-sm text-slate-500">
              &ldquo;{pendingDelete.title}&rdquo; will be permanently removed. This action cannot be
              undone.
            </p>
            <div className="mt-5 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setPendingDelete(null)}
                disabled={deleting}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => void confirmDelete()}
                disabled={deleting}
                className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-red-700 disabled:opacity-60"
              >
                {deleting && <Loader2 className="h-4 w-4 animate-spin" />}
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}