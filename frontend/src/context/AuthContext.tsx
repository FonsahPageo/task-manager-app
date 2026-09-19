import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import type { AuthResponse, AuthUser, LoginPayload, RegisterPayload } from '../types';
import { clearSession, getStoredUser, setSession } from '../api/client';
import { loginUser as apiLogin, registerUser as apiRegister } from '../api/auth';

interface AuthContextValue {
  user: AuthUser | null;
  isAuthenticated: boolean;
  login: (payload: LoginPayload) => Promise<void>;
  register: (payload: RegisterPayload) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function userFromResponse(response: AuthResponse): AuthUser {
  return {
    userId: response.userId,
    fullName: response.fullName,
    email: response.email,
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => getStoredUser<AuthUser>());

  const login = useCallback(async (payload: LoginPayload) => {
    const response = await apiLogin(payload);
    const nextUser = userFromResponse(response);
    setSession(response.token, nextUser);
    setUser(nextUser);
  }, []);

  const register = useCallback(async (payload: RegisterPayload) => {
    const response = await apiRegister(payload);
    const nextUser = userFromResponse(response);
    setSession(response.token, nextUser);
    setUser(nextUser);
  }, []);

  const logout = useCallback(() => {
    clearSession();
    setUser(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: user !== null,
      login,
      register,
      logout,
    }),
    [user, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used inside an AuthProvider');
  }
  return ctx;
}