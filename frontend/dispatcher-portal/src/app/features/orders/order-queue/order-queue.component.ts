import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { filter, finalize, interval, Subscription } from 'rxjs';
import { OrderStatus, OrderSummary } from '../../../core/models/order.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { OrderService } from '../../../core/services/order.service';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-order-queue',
  imports: [DatePipe, DecimalPipe, RouterLink, EmptyStateComponent, LoadingIndicatorComponent, StatusBadgeComponent],
  templateUrl: './order-queue.component.html',
  styleUrl: './order-queue.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OrderQueueComponent implements OnInit, OnDestroy {
  private readonly orderService = inject(OrderService);
  private readonly apiErrors = inject(ApiErrorService);

  protected readonly orders = signal<OrderSummary[]>([]);
  protected readonly selectedStatus = signal<OrderStatus | ''>('');
  protected readonly loading = signal(true);
  protected readonly refreshing = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly lastUpdated = signal<Date | null>(null);
  protected readonly newOrderCount = computed(() => this.orders().filter((order) => order.status === 'New').length);
  protected readonly activeOrderCount = computed(() =>
    this.orders().filter((order) => !['Delivered', 'DeliveryConfirmed', 'Cancelled'].includes(order.status)).length,
  );
  protected readonly deliveredOrderCount = computed(() =>
    this.orders().filter((order) => ['Delivered', 'DeliveryConfirmed'].includes(order.status)).length,
  );
  protected readonly statuses: Array<OrderStatus | ''> = [
    '',
    'New',
    'Assigned',
    'Accepted',
    'PickedUp',
    'Delivered',
    'DeliveryConfirmed',
    'Cancelled',
  ];
  private readonly refreshSubscription = interval(10_000)
    .pipe(filter(() => !this.loading() && !this.refreshing()))
    .subscribe(() => this.load(true));

  ngOnInit(): void {
    this.load();
  }

  ngOnDestroy(): void {
    this.refreshSubscription.unsubscribe();
  }

  protected changeStatus(status: string): void {
    this.selectedStatus.set(status as OrderStatus | '');
    this.load();
  }

  protected load(silent = false): void {
    if (silent && this.orders().length > 0) this.refreshing.set(true);
    else this.loading.set(true);
    this.errorMessage.set(null);
    const selectedStatus = this.selectedStatus() || undefined;

    this.orderService
      .list(selectedStatus)
      .pipe(
        finalize(() => {
          this.loading.set(false);
          this.refreshing.set(false);
        }),
      )
      .subscribe({
        next: (orders) => {
          this.orders.set(orders);
          this.lastUpdated.set(new Date());
        },
        error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
      });
  }

  protected statusLabel(status: OrderStatus | ''): string {
    if (!status) return 'All statuses';
    if (status === 'PickedUp') return 'Picked up';
    if (status === 'DeliveryConfirmed') return 'Confirmed received';
    return status;
  }
}
