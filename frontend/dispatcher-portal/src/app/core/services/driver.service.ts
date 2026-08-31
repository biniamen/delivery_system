import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Driver } from '../models/driver.model';

@Injectable({ providedIn: 'root' })
export class DriverService {
  private readonly http = inject(HttpClient);

  getAvailable(): Observable<Driver[]> {
    return this.http.get<Driver[]>(`${environment.apiBaseUrl}/drivers/available`);
  }
}

