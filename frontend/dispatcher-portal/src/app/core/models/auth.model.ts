export type UserRole = 'Customer' | 'Dispatcher' | 'Driver';

export interface AuthenticatedUser {
  id: string;
  email: string;
  displayName: string;
  role: UserRole;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthSession {
  accessToken: string;
  expiresAtUtc: string;
  user: AuthenticatedUser;
}

