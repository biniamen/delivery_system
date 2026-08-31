import { HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { ApiProblem } from '../models/api-problem.model';

@Injectable({ providedIn: 'root' })
export class ApiErrorService {
  getMessage(error: unknown): string {
    if (!(error instanceof HttpErrorResponse)) return 'Something went wrong. Please try again.';

    const problem = error.error as ApiProblem | undefined;
    const fieldMessage = problem?.errors ? Object.values(problem.errors).flat()[0] : undefined;
    return fieldMessage ?? problem?.detail ?? problem?.title ?? this.fallbackForStatus(error.status);
  }

  private fallbackForStatus(status: number): string {
    if (status === 0) return 'The service is unavailable. Check your connection and try again.';
    if (status === 401) return 'Your sign-in details were not accepted.';
    if (status === 403) return 'You do not have permission to perform this action.';
    if (status === 404) return 'The requested record could not be found.';
    return 'The request could not be completed. Please try again.';
  }
}

