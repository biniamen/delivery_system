import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { AuthSession } from '../models/auth.model';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;
  let http: HttpTestingController;

  beforeEach(() => {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideRouter([])],
    });
    service = TestBed.inject(AuthService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('stores a successful dispatcher session', () => {
    const session: AuthSession = {
      accessToken: 'test-token',
      expiresAtUtc: new Date(Date.now() + 60_000).toISOString(),
      user: {
        id: 'dispatcher-id',
        email: 'dispatcher@example.com',
        displayName: 'Dispatcher',
        role: 'Dispatcher',
      },
    };

    service.login({ email: 'dispatcher@example.com', password: 'valid-password' }).subscribe();
    http.expectOne((request) => request.url.endsWith('/auth/login')).flush(session);

    expect(service.isAuthenticated()).toBe(true);
    expect(service.user()?.role).toBe('Dispatcher');
  });
});

