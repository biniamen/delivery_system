import { DatePipe, DecimalPipe } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  inject,
  OnDestroy,
  signal,
  ViewChild,
} from '@angular/core';
import * as L from 'leaflet';
import { filter, finalize, interval, Subscription } from 'rxjs';
import { DriverLocation, LocationFreshness } from '../../../core/models/driver-location.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { DriverLocationService } from '../../../core/services/driver-location.service';
import { environment } from '../../../../environments/environment';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';

interface DriverMapLayers {
  marker: L.Marker;
  accuracy: L.Circle;
}

@Component({
  selector: 'app-driver-map',
  imports: [DatePipe, DecimalPipe, LoadingIndicatorComponent],
  templateUrl: './driver-map.component.html',
  styleUrl: './driver-map.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DriverMapComponent implements AfterViewInit, OnDestroy {
  @ViewChild('map', { static: true }) private mapElement!: ElementRef<HTMLElement>;

  private readonly locationService = inject(DriverLocationService);
  private readonly apiErrors = inject(ApiErrorService);
  private readonly layers = new Map<string, DriverMapLayers>();
  private map?: L.Map;
  private refreshSubscription?: Subscription;
  private hasFittedDrivers = false;

  protected readonly drivers = signal<DriverLocation[]>([]);
  protected readonly loading = signal(true);
  protected readonly refreshing = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly lastUpdated = signal<Date | null>(null);
  protected readonly selectedDriverId = signal<string | null>(null);
  protected readonly locatedCount = computed(() => this.drivers().filter((driver) => this.hasPosition(driver)).length);
  protected readonly liveCount = computed(() => this.drivers().filter((driver) => driver.freshness === 'Live').length);
  protected readonly activeOrderCount = computed(() => this.drivers().reduce((total, driver) => total + driver.activeOrderCount, 0));
  protected readonly activeItemCount = computed(() => this.drivers().reduce((total, driver) => total + driver.activeItemCount, 0));
  protected readonly selectedDriver = computed(() =>
    this.drivers().find((driver) => driver.driverId === this.selectedDriverId()) ?? null,
  );

  ngAfterViewInit(): void {
    this.map = L.map(this.mapElement.nativeElement, {
      center: [9.0192, 38.7525],
      zoom: 13,
      zoomControl: false,
    });
    L.control.zoom({ position: 'bottomright' }).addTo(this.map);
    L.tileLayer(environment.mapTileUrl, {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(this.map);

    this.load();
    this.refreshSubscription = interval(5_000)
      .pipe(filter(() => !this.loading() && !this.refreshing()))
      .subscribe(() => this.load(true));
  }

  ngOnDestroy(): void {
    this.refreshSubscription?.unsubscribe();
    this.map?.remove();
  }

  protected load(silent = false): void {
    if (silent && this.drivers().length > 0) this.refreshing.set(true);
    else this.loading.set(true);
    this.errorMessage.set(null);

    this.locationService
      .getLive()
      .pipe(
        finalize(() => {
          this.loading.set(false);
          this.refreshing.set(false);
        }),
      )
      .subscribe({
        next: (drivers) => {
          this.drivers.set(drivers);
          if (!this.selectedDriverId() && drivers.length > 0) this.selectedDriverId.set(drivers[0].driverId);
          this.lastUpdated.set(new Date());
          this.syncMap(drivers);
        },
        error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
      });
  }

  protected hasPosition(driver: DriverLocation): boolean {
    return driver.latitude !== null && driver.longitude !== null;
  }

  protected focus(driver: DriverLocation): void {
    this.selectedDriverId.set(driver.driverId);
    if (!this.map || !this.hasPosition(driver)) return;
    this.map.flyTo([driver.latitude!, driver.longitude!], 16, { duration: 0.65 });
    this.layers.get(driver.driverId)?.marker.openTooltip();
  }

  protected freshnessLabel(freshness: LocationFreshness): string {
    return freshness === 'Stale' ? 'Offline' : freshness;
  }

  protected speedKph(driver: DriverLocation): number | null {
    return driver.speedMetersPerSecond === null ? null : driver.speedMetersPerSecond * 3.6;
  }

  private syncMap(drivers: DriverLocation[]): void {
    if (!this.map) return;
    const positioned = drivers.filter((driver) => this.hasPosition(driver));
    const visibleDriverIds = new Set(positioned.map((driver) => driver.driverId));

    for (const [driverId, layers] of this.layers) {
      if (!visibleDriverIds.has(driverId)) {
        layers.marker.remove();
        layers.accuracy.remove();
        this.layers.delete(driverId);
      }
    }

    for (const driver of positioned) {
      const point: L.LatLngExpression = [driver.latitude!, driver.longitude!];
      const existing = this.layers.get(driver.driverId);
      if (existing) {
        existing.marker.setLatLng(point).setIcon(this.pinIcon(driver.freshness));
        existing.accuracy
          .setLatLng(point)
          .setRadius(driver.accuracyMeters ?? 0)
          .setStyle(this.accuracyStyle(driver.freshness));
        continue;
      }

      const marker = L.marker(point, { icon: this.pinIcon(driver.freshness), keyboard: true }).addTo(this.map);
      const tooltip = document.createElement('span');
      tooltip.textContent = driver.displayName;
      marker.bindTooltip(tooltip, { direction: 'top', offset: [0, -18] });
      const accuracy = L.circle(point, {
        radius: driver.accuracyMeters ?? 0,
        ...this.accuracyStyle(driver.freshness),
      }).addTo(this.map);
      this.layers.set(driver.driverId, { marker, accuracy });
    }

    if (!this.hasFittedDrivers && positioned.length > 0) {
      const bounds = positioned.map<L.LatLngTuple>((driver) => [driver.latitude!, driver.longitude!]);
      this.map.fitBounds(
        L.latLngBounds(bounds),
        { padding: [64, 64], maxZoom: 15 },
      );
      this.hasFittedDrivers = true;
    }
  }

  private pinIcon(freshness: LocationFreshness): L.DivIcon {
    const modifier = freshness.toLowerCase();
    return L.divIcon({
      className: 'driver-pin-host',
      html: `<span class="driver-pin driver-pin--${modifier}" aria-hidden="true"><span></span></span>`,
      iconSize: [42, 50],
      iconAnchor: [21, 47],
      tooltipAnchor: [0, -40],
    });
  }

  private accuracyStyle(freshness: LocationFreshness): L.PathOptions {
    const isLive = freshness === 'Live';
    return {
      color: isLive ? '#0f7b7e' : '#9a6700',
      fillColor: isLive ? '#0f7b7e' : '#e69a2d',
      fillOpacity: 0.09,
      opacity: 0.45,
      weight: 1,
    };
  }
}
