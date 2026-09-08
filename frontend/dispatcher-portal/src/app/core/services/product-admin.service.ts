import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AdminCatalogue, AdminProduct, SaveProductRequest } from '../models/admin-product.model';

@Injectable({ providedIn: 'root' })
export class ProductAdminService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/products`;

  getCatalogue(): Observable<AdminCatalogue> {
    return this.http.get<AdminCatalogue>(this.baseUrl);
  }

  create(request: SaveProductRequest): Observable<AdminProduct> {
    return this.http.post<AdminProduct>(this.baseUrl, request);
  }

  update(id: string, request: SaveProductRequest): Observable<AdminProduct> {
    return this.http.put<AdminProduct>(`${this.baseUrl}/${id}`, request);
  }

  setAvailability(id: string, isAvailable: boolean): Observable<AdminProduct> {
    return this.http.patch<AdminProduct>(`${this.baseUrl}/${id}/availability`, { isAvailable });
  }
}
