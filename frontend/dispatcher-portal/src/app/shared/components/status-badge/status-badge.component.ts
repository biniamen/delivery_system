import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { OrderStatus } from '../../../core/models/order.model';

@Component({
  selector: 'app-status-badge',
  templateUrl: './status-badge.component.html',
  styleUrl: './status-badge.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StatusBadgeComponent {
  readonly status = input.required<OrderStatus>();
  protected readonly cssClass = computed(() => `badge badge--${this.status().toLowerCase()}`);
  protected readonly label = computed(() => {
    if (this.status() === 'PickedUp') return 'Picked up';
    if (this.status() === 'DeliveryConfirmed') return 'Confirmed received';
    return this.status();
  });
}
