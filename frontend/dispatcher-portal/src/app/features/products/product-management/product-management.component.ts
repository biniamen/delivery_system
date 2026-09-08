import { CurrencyPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { finalize } from 'rxjs';
import { AdminCatalogue, AdminProduct, SaveProductRequest } from '../../../core/models/admin-product.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { ProductAdminService } from '../../../core/services/product-admin.service';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';

type AvailabilityFilter = 'all' | 'available' | 'unavailable';

@Component({
  selector: 'app-product-management',
  imports: [CurrencyPipe, ReactiveFormsModule, LoadingIndicatorComponent],
  templateUrl: './product-management.component.html',
  styleUrl: './product-management.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProductManagementComponent {
  private readonly products = inject(ProductAdminService);
  private readonly apiErrors = inject(ApiErrorService);
  private readonly formBuilder = inject(FormBuilder);

  protected readonly catalogue = signal<AdminCatalogue>({ categories: [], products: [] });
  protected readonly loading = signal(true);
  protected readonly saving = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly successMessage = signal<string | null>(null);
  protected readonly selectedProductId = signal<string | null>(null);
  protected readonly searchQuery = signal('');
  protected readonly availabilityFilter = signal<AvailabilityFilter>('all');

  protected readonly availableCount = computed(() =>
    this.catalogue().products.filter((product) => product.isAvailable).length,
  );
  protected readonly unavailableCount = computed(() => this.catalogue().products.length - this.availableCount());
  protected readonly lowStockCount = computed(() =>
    this.catalogue().products.filter((product) => product.stockQuantity > 0 && product.stockQuantity <= 10).length,
  );
  protected readonly visibleProducts = computed(() => {
    const query = this.searchQuery().trim().toLowerCase();
    const filter = this.availabilityFilter();
    return this.catalogue().products.filter((product) => {
      const matchesQuery = !query ||
        product.name.toLowerCase().includes(query) ||
        product.categoryName.toLowerCase().includes(query) ||
        product.description.toLowerCase().includes(query);
      const matchesAvailability = filter === 'all' ||
        (filter === 'available' && product.isAvailable) ||
        (filter === 'unavailable' && !product.isAvailable);
      return matchesQuery && matchesAvailability;
    });
  });

  protected readonly form = this.formBuilder.nonNullable.group({
    categoryId: ['', Validators.required],
    name: ['', [Validators.required, Validators.maxLength(150)]],
    description: ['', [Validators.required, Validators.maxLength(500)]],
    unit: ['', [Validators.required, Validators.maxLength(50)]],
    price: [0, [Validators.required, Validators.min(0)]],
    imageUrl: ['/assets/products/product.webp', [Validators.required, Validators.maxLength(500)]],
    stockQuantity: [0, [Validators.required, Validators.min(0)]],
    isAvailable: [false],
  });

  constructor() {
    this.load();
  }

  protected load(): void {
    this.loading.set(true);
    this.errorMessage.set(null);
    this.products.getCatalogue().pipe(finalize(() => this.loading.set(false))).subscribe({
      next: (catalogue) => {
        this.catalogue.set(catalogue);
        if (!this.form.controls.categoryId.value && catalogue.categories.length > 0) {
          this.form.controls.categoryId.setValue(catalogue.categories[0].id);
        }
      },
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected createNew(): void {
    const categoryId = this.catalogue().categories[0]?.id ?? '';
    this.selectedProductId.set(null);
    this.successMessage.set(null);
    this.form.reset({
      categoryId,
      name: '',
      description: '',
      unit: '',
      price: 0,
      imageUrl: '/assets/products/product.webp',
      stockQuantity: 0,
      isAvailable: false,
    });
  }

  protected edit(product: AdminProduct): void {
    this.selectedProductId.set(product.id);
    this.successMessage.set(null);
    this.form.reset({
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      unit: product.unit,
      price: product.price,
      imageUrl: product.imageUrl,
      stockQuantity: product.stockQuantity,
      isAvailable: product.isAvailable,
    });
    document.querySelector('.editor-card')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  protected save(): void {
    this.errorMessage.set(null);
    this.successMessage.set(null);
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const request: SaveProductRequest = this.form.getRawValue();
    const selectedId = this.selectedProductId();
    this.saving.set(true);
    const operation = selectedId ? this.products.update(selectedId, request) : this.products.create(request);
    operation.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: (saved) => {
        this.successMessage.set(`${saved.name} was saved successfully.`);
        this.selectedProductId.set(saved.id);
        this.load();
      },
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected toggleAvailability(product: AdminProduct): void {
    this.errorMessage.set(null);
    this.products.setAvailability(product.id, !product.isAvailable).subscribe({
      next: (updated) => {
        this.catalogue.update((catalogue) => ({
          ...catalogue,
          products: catalogue.products.map((item) => item.id === updated.id ? updated : item),
        }));
        this.successMessage.set(
          updated.isAvailable ? `${updated.name} is visible to customers.` : `${updated.name} is now hidden.`,
        );
      },
      error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
    });
  }

  protected setFilter(filter: AvailabilityFilter): void {
    this.availabilityFilter.set(filter);
  }

  protected stockClass(product: AdminProduct): string {
    if (product.stockQuantity === 0) return 'out';
    if (product.stockQuantity <= 10) return 'low';
    return 'healthy';
  }
}
