import { apiRequest } from './client';
import type { AuthResponse, LoginPayload, RegisterPayload } from '../types';

export async function registerUser(payload: RegisterPayload): Promise<AuthResponse> {
  return apiRequest<AuthResponse>('/auth/register', {
    method: 'POST',
    body: payload,
    authenticated: false,
  });
}

export async function loginUser(payload: LoginPayload): Promise<AuthResponse> {
  return apiRequest<AuthResponse>('/auth/login', {
    method: 'POST',
    body: payload,
    authenticated: false,
  });
}