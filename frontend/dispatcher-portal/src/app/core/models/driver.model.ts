import { UserRole } from './auth.model';

export interface Driver {
  id: string;
  email: string;
  displayName: string;
  role: UserRole;
  phoneNumber: string | null;
  isActive: boolean;
}

export interface CreateDriverRequest {
  displayName: string;
  email: string;
  phoneNumber: string;
  temporaryPassword: string;
}

export interface SetDriverStatusRequest {
  isActive: boolean;
}
