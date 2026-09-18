import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { finalize } from 'rxjs';
import { CreateDriverRequest, Driver } from '../../../core/models/driver.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { DriverService } from '../../../core/services/driver.service';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';

@Component({
  selector: 'app-driver-management',
  imports: [ReactiveFormsModule, LoadingIndicatorComponent],
  templateUrl: './driver-management.component.html',
  styleUrl: './driver-management.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DriverManagementComponent {
  private readonly drivers = inject(DriverService);
  private readonly apiErrors = inject(ApiErrorService);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly accounts = signal<Driver[]>([]);
  protected readonly loading = signal(true);
  protected readonly saving = signal(false);
  protected readonly updatingDriverId = signal<string | null>(null);
  protected readonly passwordVisible = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly successMessage = signal<string | null>(null);
  protected readonly activeCount = computed(() => this.accounts().filter((driver) => driver.isActive).length);
  protected readonly inactiveCount = computed(() => this.accounts().length - this.activeCount());

  protected readonly form = this.formBuilder.nonNullable.group({
    displayName: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(100)]],
    email: ['', [Validators.required, Validators.email, Validators.maxLength(254)]],
    phoneNumber: ['', [Validators.required, Validators.pattern(/^(?:\+251|0)?9\d{8}$/)]],
    temporaryPassword: [
      '',
      [
        Validators.required,
        Validators.minLength(10),
        Validators.maxLength(100),
        Validators.pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$/),
      ],
    ],
  });

  constructor() {
    this.load();
  }

  protected load(): void {
    this.loading.set(true);
    this.errorMessage.set(null);
    this.drivers.list().pipe(finalize(() => this.loading.set(false))).subscribe({
      next: (accounts) => this.accounts.set(accounts),
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected create(): void {
    this.errorMessage.set(null);
    this.successMessage.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving.set(true);
    const request: CreateDriverRequest = this.form.getRawValue();
    this.drivers.create(request).pipe(finalize(() => this.saving.set(false))).subscribe({
      next: (created) => {
        this.accounts.update((accounts) =>
          [...accounts, created].sort((left, right) => left.displayName.localeCompare(right.displayName)),
        );
        this.successMessage.set(`${created.displayName} can now sign in to the driver app.`);
        this.form.reset({
          displayName: '',
          email: '',
          phoneNumber: '',
          temporaryPassword: '',
        });
      },
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected setActive(driver: Driver, isActive: boolean): void {
    this.errorMessage.set(null);
    this.successMessage.set(null);
    this.updatingDriverId.set(driver.id);
    this.drivers.setActive(driver.id, isActive).pipe(finalize(() => this.updatingDriverId.set(null))).subscribe({
      next: (updated) => {
        this.accounts.update((accounts) => accounts.map((item) => item.id === updated.id ? updated : item));
        this.successMessage.set(
          updated.isActive
            ? `${updated.displayName} is active and available for assignment.`
            : `${updated.displayName} is no longer available for assignment.`,
        );
      },
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected togglePasswordVisibility(): void {
    this.passwordVisible.update((visible) => !visible);
  }
}
