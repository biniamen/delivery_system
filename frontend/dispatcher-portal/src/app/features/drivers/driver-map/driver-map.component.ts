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
import { DeliveryRoute, GoogleMapLibraries } from '../../../core/models/map.model';
import { ApiErrorService } from '../../../core/services/api-error.service';
import { DeliveryRouteService } from '../../../core/services/delivery-route.service';
import { DriverLocationService } from '../../../core/services/driver-location.service';
import { MapPlatformService } from '../../../core/services/map-platform.service';
import { environment } from '../../../../environments/environment';
import { LoadingIndicatorComponent } from '../../../shared/components/loading-indicator/loading-indicator.component';

interface LeafletDriverLayers {
  marker: L.Marker;
  accuracy: L.Circle;
}

interface GoogleDriverLayers {
  marker: google.maps.marker.AdvancedMarkerElement;
  accuracy: google.maps.Circle;
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
  private readonly routeService = inject(DeliveryRouteService);
  private readonly mapPlatform = inject(MapPlatformService);
  private readonly apiErrors = inject(ApiErrorService);
  private readonly leafletLayers = new Map<string, LeafletDriverLayers>();
  private readonly googleLayers = new Map<string, GoogleDriverLayers>();
  private leafletMap?: L.Map;
  private googleMap?: google.maps.Map;
  private googleLibraries?: GoogleMapLibraries;
  private googleRoute?: google.maps.Polyline;
  private googleDestination?: google.maps.marker.AdvancedMarkerElement;
  private leafletRoute?: L.Polyline;
  private leafletDestination?: L.Marker;
  private refreshSubscription?: Subscription;
  private routeSubscription?: Subscription;
  private hasFittedDrivers = false;
  private destroyed = false;

  protected readonly drivers = signal<DriverLocation[]>([]);
  protected readonly loading = signal(true);
  protected readonly refreshing = signal(false);
  protected readonly errorMessage = signal<string | null>(null);
  protected readonly lastUpdated = signal<Date | null>(null);
  protected readonly selectedDriverId = signal<string | null>(null);
  protected readonly selectedRoute = signal<DeliveryRoute | null>(null);
  protected readonly provider = signal('OpenStreetMap');
  protected readonly locatedCount = computed(() =>
    this.drivers().filter((driver) => this.hasPosition(driver)).length,
  );
  protected readonly liveCount = computed(() =>
    this.drivers().filter((driver) => driver.freshness === 'Live').length,
  );
  protected readonly activeOrderCount = computed(() =>
    this.drivers().reduce((total, driver) => total + driver.activeOrderCount, 0),
  );
  protected readonly activeItemCount = computed(() =>
    this.drivers().reduce((total, driver) => total + driver.activeItemCount, 0),
  );
  protected readonly selectedDriver = computed(() =>
    this.drivers().find((driver) => driver.driverId === this.selectedDriverId()) ?? null,
  );

  ngAfterViewInit(): void {
    void this.initialize();
  }

  ngOnDestroy(): void {
    this.destroyed = true;
    this.refreshSubscription?.unsubscribe();
    this.routeSubscription?.unsubscribe();
    this.clearRouteLayers();
    this.leafletMap?.remove();
    for (const layers of this.googleLayers.values()) {
      layers.marker.map = null;
      layers.accuracy.setMap(null);
    }
    this.googleLayers.clear();
    this.googleMap = undefined;
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
          if (!drivers.some((driver) => driver.driverId === this.selectedDriverId())) {
            this.selectedDriverId.set(drivers[0]?.driverId ?? null);
          }
          this.lastUpdated.set(new Date());
          this.syncMap(drivers);
          this.loadSelectedRoute();
        },
        error: (error: unknown) => this.errorMessage.set(this.apiErrors.getMessage(error)),
      });
  }

  protected hasPosition(driver: DriverLocation): boolean {
    return driver.latitude !== null && driver.longitude !== null;
  }

  protected focus(driver: DriverLocation): void {
    this.selectedDriverId.set(driver.driverId);
    this.loadSelectedRoute();
    if (!this.hasPosition(driver)) return;
    if (this.googleMap) {
      this.googleMap.panTo({ lat: driver.latitude!, lng: driver.longitude! });
      this.googleMap.setZoom(16);
    } else {
      this.leafletMap?.flyTo([driver.latitude!, driver.longitude!], 16, { duration: 0.65 });
      this.leafletLayers.get(driver.driverId)?.marker.openTooltip();
    }
  }

  protected freshnessLabel(freshness: LocationFreshness): string {
    return freshness === 'Stale' ? 'Offline' : freshness;
  }

  protected speedKph(driver: DriverLocation): number | null {
    return driver.speedMetersPerSecond === null ? null : driver.speedMetersPerSecond * 3.6;
  }

  private async initialize(): Promise<void> {
    const libraries = await this.mapPlatform.loadGoogleMaps();
    if (this.destroyed) return;
    if (libraries) this.initializeGoogleMap(libraries);
    else this.initializeLeafletMap();
    this.load();
    this.refreshSubscription = interval(5_000)
      .pipe(filter(() => !this.loading() && !this.refreshing()))
      .subscribe(() => this.load(true));
  }

  private initializeGoogleMap(libraries: GoogleMapLibraries): void {
    this.googleLibraries = libraries;
    this.provider.set('Google Maps');
    this.googleMap = new libraries.maps.Map(this.mapElement.nativeElement, {
      center: { lat: 9.0192, lng: 38.7525 },
      zoom: 13,
      mapId: libraries.configuration.mapId,
      clickableIcons: false,
      fullscreenControl: true,
      mapTypeControl: false,
      streetViewControl: false,
      gestureHandling: 'cooperative',
    });
  }

  private initializeLeafletMap(): void {
    const map = L.map(this.mapElement.nativeElement, {
      center: [9.0192, 38.7525],
      zoom: 13,
      zoomControl: false,
    });
    this.leafletMap = map;
    L.control.zoom({ position: 'bottomright' }).addTo(map);
    L.tileLayer(environment.mapTileUrl, {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);
  }

  private syncMap(drivers: DriverLocation[]): void {
    if (this.googleMap && this.googleLibraries) this.syncGoogleMap(drivers);
    else this.syncLeafletMap(drivers);
  }

  private syncGoogleMap(drivers: DriverLocation[]): void {
    const map = this.googleMap;
    const libraries = this.googleLibraries;
    if (!map || !libraries) return;
    const positioned = drivers.filter((driver) => this.hasPosition(driver));
    const visibleDriverIds = new Set(positioned.map((driver) => driver.driverId));

    for (const [driverId, layers] of this.googleLayers) {
      if (!visibleDriverIds.has(driverId)) {
        layers.marker.map = null;
        layers.accuracy.setMap(null);
        this.googleLayers.delete(driverId);
      }
    }

    for (const driver of positioned) {
      const position = { lat: driver.latitude!, lng: driver.longitude! };
      const existing = this.googleLayers.get(driver.driverId);
      if (existing) {
        existing.marker.position = position;
        existing.marker.content = this.googleDriverPin(driver, libraries).element;
        existing.accuracy.setCenter(position);
        existing.accuracy.setRadius(driver.accuracyMeters ?? 0);
        existing.accuracy.setOptions(this.googleAccuracyStyle(driver.freshness));
        continue;
      }

      const marker = new libraries.marker.AdvancedMarkerElement({
        map,
        position,
        title: `${driver.displayName} · ${this.freshnessLabel(driver.freshness)}`,
        content: this.googleDriverPin(driver, libraries).element,
      });
      const accuracy = new libraries.maps.Circle({
        map,
        center: position,
        radius: driver.accuracyMeters ?? 0,
        ...this.googleAccuracyStyle(driver.freshness),
      });
      marker.addListener('click', () => this.focus(driver));
      this.googleLayers.set(driver.driverId, { marker, accuracy });
    }

    if (!this.hasFittedDrivers && positioned.length > 0) {
      const bounds = new google.maps.LatLngBounds();
      for (const driver of positioned) bounds.extend({ lat: driver.latitude!, lng: driver.longitude! });
      map.fitBounds(bounds, 64);
      this.hasFittedDrivers = true;
    }
  }

  private syncLeafletMap(drivers: DriverLocation[]): void {
    const map = this.leafletMap;
    if (!map) return;
    const positioned = drivers.filter((driver) => this.hasPosition(driver));
    const visibleDriverIds = new Set(positioned.map((driver) => driver.driverId));

    for (const [driverId, layers] of this.leafletLayers) {
      if (!visibleDriverIds.has(driverId)) {
        layers.marker.remove();
        layers.accuracy.remove();
        this.leafletLayers.delete(driverId);
      }
    }

    for (const driver of positioned) {
      const point: L.LatLngExpression = [driver.latitude!, driver.longitude!];
      const existing = this.leafletLayers.get(driver.driverId);
      if (existing) {
        existing.marker.setLatLng(point).setIcon(this.leafletPinIcon(driver.freshness));
        existing.accuracy
          .setLatLng(point)
          .setRadius(driver.accuracyMeters ?? 0)
          .setStyle(this.leafletAccuracyStyle(driver.freshness));
        continue;
      }

      const marker = L.marker(point, {
        icon: this.leafletPinIcon(driver.freshness),
        keyboard: true,
      }).addTo(map);
      const tooltip = document.createElement('span');
      tooltip.textContent = driver.displayName;
      marker.bindTooltip(tooltip, { direction: 'top', offset: [0, -18] });
      marker.on('click', () => this.focus(driver));
      const accuracy = L.circle(point, {
        radius: driver.accuracyMeters ?? 0,
        ...this.leafletAccuracyStyle(driver.freshness),
      }).addTo(map);
      this.leafletLayers.set(driver.driverId, { marker, accuracy });
    }

    if (!this.hasFittedDrivers && positioned.length > 0) {
      const bounds = positioned.map<L.LatLngTuple>((driver) => [driver.latitude!, driver.longitude!]);
      map.fitBounds(L.latLngBounds(bounds), { padding: [64, 64], maxZoom: 15 });
      this.hasFittedDrivers = true;
    }
  }

  private loadSelectedRoute(): void {
    this.routeSubscription?.unsubscribe();
    const orderId = this.selectedDriver()?.activeOrders[0]?.orderId;
    if (!orderId) {
      this.selectedRoute.set(null);
      this.clearRouteLayers();
      return;
    }
    this.routeSubscription = this.routeService.getForOrder(orderId).subscribe({
      next: (route) => {
        this.selectedRoute.set(route);
        this.syncRoute(route);
      },
      error: () => {
        this.selectedRoute.set(null);
        this.clearRouteLayers();
      },
    });
  }

  private syncRoute(route: DeliveryRoute | null): void {
    this.clearRouteLayers();
    if (!route || route.path.length < 2) return;
    if (this.googleMap && this.googleLibraries) {
      const libraries = this.googleLibraries;
      const path = route.path.map((point) => ({ lat: point.latitude, lng: point.longitude }));
      this.googleRoute = new libraries.maps.Polyline({
        map: this.googleMap,
        path,
        strokeColor: '#0f6b6d',
        strokeOpacity: 0.95,
        strokeWeight: 6,
        geodesic: true,
      });
      const destinationPin = new libraries.marker.PinElement({
        background: '#e24d48',
        borderColor: '#ffffff',
        glyphColor: '#ffffff',
      });
      this.googleDestination = new libraries.marker.AdvancedMarkerElement({
        map: this.googleMap,
        position: { lat: route.destinationLatitude, lng: route.destinationLongitude },
        title: 'Customer destination',
        content: destinationPin.element,
      });
      return;
    }

    const map = this.leafletMap;
    if (!map) return;
    const path = route.path.map<L.LatLngTuple>((point) => [point.latitude, point.longitude]);
    this.leafletRoute = L.polyline(path, {
      color: '#0f6b6d',
      opacity: 0.95,
      weight: 6,
    }).addTo(map);
    this.leafletDestination = L.marker(
      [route.destinationLatitude, route.destinationLongitude],
      { icon: this.destinationIcon() },
    ).bindTooltip('Customer destination').addTo(map);
  }

  private clearRouteLayers(): void {
    this.googleRoute?.setMap(null);
    if (this.googleDestination) this.googleDestination.map = null;
    this.leafletRoute?.remove();
    this.leafletDestination?.remove();
    this.googleRoute = undefined;
    this.googleDestination = undefined;
    this.leafletRoute = undefined;
    this.leafletDestination = undefined;
  }

  private googleDriverPin(
    driver: DriverLocation,
    libraries: GoogleMapLibraries,
  ): google.maps.marker.PinElement {
    const live = driver.freshness === 'Live';
    return new libraries.marker.PinElement({
      background: live ? '#0f7b7e' : driver.freshness === 'Recent' ? '#e69a2d' : '#8997a5',
      borderColor: '#ffffff',
      glyphColor: '#ffffff',
      glyphText: driver.displayName.charAt(0).toUpperCase(),
      scale: this.selectedDriverId() === driver.driverId ? 1.2 : 1,
    });
  }

  private googleAccuracyStyle(freshness: LocationFreshness): google.maps.CircleOptions {
    const live = freshness === 'Live';
    return {
      strokeColor: live ? '#0f7b7e' : '#9a6700',
      strokeOpacity: 0.45,
      strokeWeight: 1,
      fillColor: live ? '#0f7b7e' : '#e69a2d',
      fillOpacity: 0.09,
    };
  }

  private leafletPinIcon(freshness: LocationFreshness): L.DivIcon {
    const modifier = freshness.toLowerCase();
    return L.divIcon({
      className: 'driver-pin-host',
      html: `<span class="driver-pin driver-pin--${modifier}" aria-hidden="true"><span></span></span>`,
      iconSize: [42, 50],
      iconAnchor: [21, 47],
      tooltipAnchor: [0, -40],
    });
  }

  private destinationIcon(): L.DivIcon {
    return L.divIcon({
      className: 'driver-pin-host',
      html: '<span class="route-destination" aria-hidden="true">●</span>',
      iconSize: [34, 42],
      iconAnchor: [17, 38],
    });
  }

  private leafletAccuracyStyle(freshness: LocationFreshness): L.PathOptions {
    const live = freshness === 'Live';
    return {
      color: live ? '#0f7b7e' : '#9a6700',
      fillColor: live ? '#0f7b7e' : '#e69a2d',
      fillOpacity: 0.09,
      opacity: 0.45,
      weight: 1,
    };
  }
}
