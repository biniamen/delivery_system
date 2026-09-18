import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard, roleHomeGuard } from './core/guards/role.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login/login.component').then((module) => module.LoginComponent),
  },
  {
    path: '',
    canActivate: [authGuard, roleGuard(['Dispatcher', 'StoreAdmin'])],
    loadComponent: () => import('./layout/shell/shell.component').then((module) => module.ShellComponent),
    children: [
      {
        path: '',
        pathMatch: 'full',
        canActivate: [roleHomeGuard],
        loadComponent: () => import('./shared/components/empty-state/empty-state.component').then((module) => module.EmptyStateComponent),
      },
      {
        path: 'orders',
        canActivate: [roleGuard(['Dispatcher'])],
        title: 'Order queue | Creavers Dispatch',
        loadComponent: () =>
          import('./features/orders/order-queue/order-queue.component').then((module) => module.OrderQueueComponent),
      },
      {
        path: 'drivers',
        canActivate: [roleGuard(['Dispatcher'])],
        title: 'Live drivers | Creavers Dispatch',
        loadComponent: () =>
          import('./features/drivers/driver-map/driver-map.component').then((module) => module.DriverMapComponent),
      },
      {
        path: 'driver-accounts',
        canActivate: [roleGuard(['Dispatcher'])],
        title: 'Driver accounts | Creavers Dispatch',
        loadComponent: () =>
          import('./features/drivers/driver-management/driver-management.component').then(
            (module) => module.DriverManagementComponent,
          ),
      },
      {
        path: 'products',
        canActivate: [roleGuard(['StoreAdmin'])],
        title: 'Product operations | Creavers',
        loadComponent: () =>
          import('./features/products/product-management/product-management.component').then(
            (module) => module.ProductManagementComponent,
          ),
      },
      {
        path: 'orders/:id',
        canActivate: [roleGuard(['Dispatcher'])],
        title: 'Order detail | Creavers Dispatch',
        loadComponent: () =>
          import('./features/orders/order-detail/order-detail.component').then((module) => module.OrderDetailComponent),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
