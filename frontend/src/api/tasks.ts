import { apiRequest } from './client';
import type { Task, TaskPayload, TaskQuery } from '../types';

export async function fetchTasks(query: TaskQuery = {}): Promise<Task[]> {
  const params = new URLSearchParams();
  if (query.status) params.set('status', query.status);
  if (query.search) params.set('search', query.search);
  const qs = params.toString();
  return apiRequest<Task[]>(`/tasks${qs ? `?${qs}` : ''}`);
}

export async function createTask(payload: TaskPayload): Promise<Task> {
  return apiRequest<Task>('/tasks', { method: 'POST', body: payload });
}

export async function updateTask(id: number, payload: TaskPayload): Promise<Task> {
  return apiRequest<Task>(`/tasks/${id}`, { method: 'PUT', body: payload });
}

export async function deleteTask(id: number): Promise<void> {
  return apiRequest<void>(`/tasks/${id}`, { method: 'DELETE' });
}