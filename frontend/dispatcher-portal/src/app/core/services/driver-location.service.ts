import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { DriverLocation } from '../models/driver-location.model';

@Injectable({ providedIn: 'root' })
export class DriverLocationService {
  private readonly http = inject(HttpClient);

  getLive(): Observable<DriverLocation[]> {
    return this.http.get<DriverLocation[]>(`${environment.apiBaseUrl}/driver-locations/live`);
  }
}
