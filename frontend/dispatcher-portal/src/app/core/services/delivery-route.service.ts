import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { DeliveryRoute } from '../models/map.model';

@Injectable({ providedIn: 'root' })
export class DeliveryRouteService {
  private readonly http = inject(HttpClient);

  getForOrder(orderId: string): Observable<DeliveryRoute | null> {
    return this.http.get<DeliveryRoute | null>(
      `${environment.apiBaseUrl}/maps/orders/${orderId}/route`,
    );
  }
}
