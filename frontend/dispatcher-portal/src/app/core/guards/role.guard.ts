import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { UserRole } from '../models/auth.model';
import { AuthService } from '../services/auth.service';

export function roleGuard(allowedRoles: UserRole[]): CanActivateFn {
  return () => {
    const role = inject(AuthService).user()?.role;
    return role && allowedRoles.includes(role) ? true : inject(Router).createUrlTree(['/login']);
  };
}

export const roleHomeGuard: CanActivateFn = () => {
  const role = inject(AuthService).user()?.role;
  const router = inject(Router);
  if (role === 'StoreAdmin') return router.createUrlTree(['/products']);
  if (role === 'Dispatcher') return router.createUrlTree(['/orders']);
  return router.createUrlTree(['/login']);
};
