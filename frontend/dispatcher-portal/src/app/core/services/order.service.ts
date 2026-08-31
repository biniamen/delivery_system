import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AssignDriverRequest, Order, OrderStatus, OrderSummary } from '../models/order.model';

@Injectable({ providedIn: 'root' })
export class OrderService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/orders`;

  list(status?: OrderStatus): Observable<OrderSummary[]> {
    const params = status ? new HttpParams().set('status', status) : undefined;
    return this.http.get<OrderSummary[]>(this.baseUrl, { params });
  }

  getById(id: string): Observable<Order> {
    return this.http.get<Order>(`${this.baseUrl}/${id}`);
  }

  assignDriver(id: string, request: AssignDriverRequest): Observable<Order> {
    return this.http.put<Order>(`${this.baseUrl}/${id}/assignment`, request);
  }
}

