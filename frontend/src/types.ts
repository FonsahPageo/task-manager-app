export type TaskStatus = 'TODO' | 'IN_PROGRESS' | 'DONE';

export interface Task {
  id: number;
  title: string;
  description: string | null;
  status: TaskStatus;
  createdAt: string;
  updatedAt: string;
}

export interface AuthResponse {
  token: string;
  tokenType: 'Bearer';
  userId: number;
  fullName: string;
  email: string;
}

export interface AuthUser {
  userId: number;
  fullName: string;
  email: string;
}

export interface RegisterPayload {
  email: string;
  fullName: string;
  password: string;
}

export interface LoginPayload {
  email: string;
  password: string;
}

export interface TaskPayload {
  title: string;
  description: string | null;
  status: TaskStatus;
}

export interface ApiErrorBody {
  timestamp?: string;
  status?: number;
  error?: string;
  message?: string;
  path?: string;
  fieldErrors?: Record<string, string>;
}

export interface TaskQuery {
  status?: TaskStatus | '';
  search?: string;
}