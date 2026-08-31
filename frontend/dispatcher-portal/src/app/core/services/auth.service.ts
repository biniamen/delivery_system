import { HttpClient } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthSession, LoginRequest } from '../models/auth.model';

const SESSION_KEY = 'creavers.dispatch.session';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly sessionState = signal<AuthSession | null>(this.readSession());

  readonly user = computed(() => this.sessionState()?.user ?? null);
  readonly isAuthenticated = computed(() => this.sessionState() !== null);

  get accessToken(): string | null {
    return this.sessionState()?.accessToken ?? null;
  }

  login(request: LoginRequest): Observable<AuthSession> {
    return this.http.post<AuthSession>(`${environment.apiBaseUrl}/auth/login`, request).pipe(
      tap((session) => {
        sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
        this.sessionState.set(session);
      }),
    );
  }

  logout(): void {
    sessionStorage.removeItem(SESSION_KEY);
    this.sessionState.set(null);
    void this.router.navigate(['/login']);
  }

  private readSession(): AuthSession | null {
    const serialized = sessionStorage.getItem(SESSION_KEY);
    if (!serialized) return null;

    try {
      const session = JSON.parse(serialized) as AuthSession;
      if (Date.parse(session.expiresAtUtc) <= Date.now()) {
        sessionStorage.removeItem(SESSION_KEY);
        return null;
      }
      return session;
    } catch {
      sessionStorage.removeItem(SESSION_KEY);
      return null;
    }
  }
}

