import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Driver } from '../models/driver.model';
import { DriverService } from './driver.service';

describe('DriverService', () => {
  let service: DriverService;
  let http: HttpTestingController;

  const driver: Driver = {
    id: 'driver-id',
    email: 'hana.driver@example.com',
    displayName: 'Hana Driver',
    role: 'Driver',
    phoneNumber: '+251911222333',
    isActive: true,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(DriverService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('creates a dispatcher-managed driver account', () => {
    const request = {
      displayName: 'Hana Driver',
      email: 'hana.driver@example.com',
      phoneNumber: '+251911222333',
      temporaryPassword: 'Creavers#2026',
    };

    service.create(request).subscribe((created) => expect(created).toEqual(driver));

    const pending = http.expectOne((value) => value.url.endsWith('/drivers'));
    expect(pending.request.method).toBe('POST');
    expect(pending.request.body).toEqual(request);
    pending.flush(driver);
  });

  it('updates driver activation state', () => {
    service.setActive(driver.id, false).subscribe((updated) => expect(updated.isActive).toBe(false));

    const pending = http.expectOne((value) => value.url.endsWith(`/drivers/${driver.id}/status`));
    expect(pending.request.method).toBe('PUT');
    expect(pending.request.body).toEqual({ isActive: false });
    pending.flush({ ...driver, isActive: false });
  });
});
