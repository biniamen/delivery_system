import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login/login.component').then((module) => module.LoginComponent),
  },
  {
    path: '',
    canActivate: [authGuard, roleGuard(['Dispatcher'])],
    loadComponent: () => import('./layout/shell/shell.component').then((module) => module.ShellComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'orders' },
      {
        path: 'orders',
        title: 'Order queue | Creavers Dispatch',
        loadComponent: () =>
          import('./features/orders/order-queue/order-queue.component').then((module) => module.OrderQueueComponent),
      },
      {
        path: 'drivers',
        title: 'Live drivers | Creavers Dispatch',
        loadComponent: () =>
          import('./features/drivers/driver-map/driver-map.component').then((module) => module.DriverMapComponent),
      },
      {
        path: 'orders/:id',
        title: 'Order detail | Creavers Dispatch',
        loadComponent: () =>
          import('./features/orders/order-detail/order-detail.component').then((module) => module.OrderDetailComponent),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
