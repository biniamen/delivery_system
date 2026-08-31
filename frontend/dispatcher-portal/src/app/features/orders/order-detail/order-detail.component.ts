import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { forkJoin, finalize } from 'rxjs';
import { Driver } from '../../../core/models/driver.model';
import { Order } from '../../../core/models/order.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { DriverService } from '../../../core/services/driver.service';
import { OrderService } from '../../../core/services/order.service';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-order-detail',
  imports: [DatePipe, DecimalPipe, ReactiveFormsModule, RouterLink, LoadingIndicatorComponent, StatusBadgeComponent],
  templateUrl: './order-detail.component.html',
  styleUrl: './order-detail.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OrderDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly orderService = inject(OrderService);
  private readonly driverService = inject(DriverService);
  private readonly apiErrors = inject(ApiErrorService);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly order = signal<Order | null>(null);
  protected readonly drivers = signal<Driver[]>([]);
  protected readonly loading = signal(true);
  protected readonly assigning = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly successMessage = signal<string | null>(null);
  protected readonly assignmentForm = this.formBuilder.nonNullable.group({
    driverId: ['', Validators.required],
  });

  ngOnInit(): void {
    this.load();
  }

  protected load(): void {
    const orderId = this.route.snapshot.paramMap.get('id');
    if (!orderId) {
      this.errorMessage.set('The order identifier is missing.');
      this.loading.set(false);
      return;
    }

    this.loading.set(true);
    this.errorMessage.set(null);
    forkJoin({
      order: this.orderService.getById(orderId),
      drivers: this.driverService.getAvailable(),
    })
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: ({ order, drivers }) => {
          this.order.set(order);
          this.drivers.set(drivers);
          if (order.assignedDriverId) this.assignmentForm.controls.driverId.setValue(order.assignedDriverId);
        },
        error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
      });
  }

  protected assign(): void {
    const order = this.order();
    if (!order || this.assignmentForm.invalid) {
      this.assignmentForm.markAllAsTouched();
      return;
    }

    this.assigning.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);
    this.orderService
      .assignDriver(order.id, this.assignmentForm.getRawValue())
      .pipe(finalize(() => this.assigning.set(false)))
      .subscribe({
        next: (updatedOrder) => {
          this.order.set(updatedOrder);
          this.successMessage.set('Driver assignment saved. The order is ready for driver acceptance.');
        },
        error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
      });
  }

  protected canAssign(order: Order): boolean {
    return order.status === 'New' || order.status === 'Assigned';
  }

  protected selectedDriverName(driverId: string | null): string {
    return this.drivers().find((driver) => driver.id === driverId)?.displayName ?? 'Not assigned';
  }
}

