import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CreateDriverRequest, Driver } from '../models/driver.model';

@Injectable({ providedIn: 'root' })
export class DriverService {
  private readonly http = inject(HttpClient);

  list(): Observable<Driver[]> {
    return this.http.get<Driver[]>(`${environment.apiBaseUrl}/drivers`);
  }

  getAvailable(forOrderId?: string): Observable<Driver[]> {
    const options = forOrderId ? { params: { forOrderId } } : {};
    return this.http.get<Driver[]>(`${environment.apiBaseUrl}/drivers/available`, options);
  }

  create(request: CreateDriverRequest): Observable<Driver> {
    return this.http.post<Driver>(`${environment.apiBaseUrl}/drivers`, request);
  }

  setActive(driverId: string, isActive: boolean): Observable<Driver> {
    return this.http.put<Driver>(`${environment.apiBaseUrl}/drivers/${driverId}/status`, { isActive });
  }
}
