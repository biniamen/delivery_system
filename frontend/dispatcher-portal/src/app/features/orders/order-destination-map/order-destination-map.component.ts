import { DecimalPipe } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  inject,
  input,
  OnDestroy,
  signal,
  ViewChild,
} from '@angular/core';
import * as L from 'leaflet';
import { firstValueFrom } from 'rxjs';
import { DeliveryRoute, GoogleMapLibraries } from '../../../core/models/map.model';
import { DeliveryRouteService } from '../../../core/services/delivery-route.service';
import { MapPlatformService } from '../../../core/services/map-platform.service';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-order-destination-map',
  imports: [DecimalPipe],
  templateUrl: './order-destination-map.component.html',
  styleUrl: './order-destination-map.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OrderDestinationMapComponent implements AfterViewInit, OnDestroy {
  @ViewChild('destinationMap', { static: true }) private mapElement!: ElementRef<HTMLElement>;

  readonly orderId = input.required<string>();
  readonly latitude = input.required<number>();
  readonly longitude = input.required<number>();
  readonly address = input.required<string>();

  private readonly mapPlatform = inject(MapPlatformService);
  private readonly routes = inject(DeliveryRouteService);
  private leafletMap?: L.Map;
  private googleMap?: google.maps.Map;
  private googleMarkers: google.maps.marker.AdvancedMarkerElement[] = [];
  private destroyed = false;

  protected readonly route = signal<DeliveryRoute | null>(null);
  protected readonly provider = signal('OpenStreetMap');

  protected get externalMapUrl(): string {
    return `https://www.google.com/maps/search/?api=1&query=${this.latitude()},${this.longitude()}`;
  }

  ngAfterViewInit(): void {
    void this.initialize();
  }

  ngOnDestroy(): void {
    this.destroyed = true;
    this.leafletMap?.remove();
    for (const marker of this.googleMarkers) marker.map = null;
    this.googleMarkers = [];
    this.googleMap = undefined;
  }

  private async initialize(): Promise<void> {
    const [libraries, route] = await Promise.all([
      this.mapPlatform.loadGoogleMaps(),
      firstValueFrom(this.routes.getForOrder(this.orderId())).catch(() => null),
    ]);
    if (this.destroyed) return;
    this.route.set(route);
    if (libraries) this.initializeGoogleMap(libraries, route);
    else this.initializeLeafletMap(route);
  }

  private initializeGoogleMap(libraries: GoogleMapLibraries, route: DeliveryRoute | null): void {
    this.provider.set('Google Maps');
    const destination = { lat: this.latitude(), lng: this.longitude() };
    const map = new libraries.maps.Map(this.mapElement.nativeElement, {
      center: destination,
      zoom: 16,
      mapId: libraries.configuration.mapId,
      clickableIcons: false,
      fullscreenControl: true,
      mapTypeControl: false,
      streetViewControl: false,
      gestureHandling: 'cooperative',
    });
    this.googleMap = map;

    const destinationPin = new libraries.marker.PinElement({
      background: '#e24d48',
      borderColor: '#ffffff',
      glyphColor: '#ffffff',
      scale: 1.1,
    });
    this.googleMarkers.push(
      new libraries.marker.AdvancedMarkerElement({
        map,
        position: destination,
        title: `Customer destination: ${this.address()}`,
        content: destinationPin.element,
      }),
    );

    if (!route || route.path.length < 2) return;
    const path = route.path.map((point) => ({ lat: point.latitude, lng: point.longitude }));
    new libraries.maps.Polyline({
      map,
      path,
      strokeColor: '#0f6b6d',
      strokeOpacity: 0.95,
      strokeWeight: 6,
      geodesic: true,
    });
    const driverPin = new libraries.marker.PinElement({
      background: '#0f7b7e',
      borderColor: '#ffffff',
      glyphColor: '#ffffff',
      glyphText: 'D',
    });
    this.googleMarkers.push(
      new libraries.marker.AdvancedMarkerElement({
        map,
        position: { lat: route.originLatitude, lng: route.originLongitude },
        title: 'Current driver position',
        content: driverPin.element,
      }),
    );
    const bounds = new google.maps.LatLngBounds();
    for (const point of path) bounds.extend(point);
    bounds.extend(destination);
    map.fitBounds(bounds, 58);
  }

  private initializeLeafletMap(route: DeliveryRoute | null): void {
    const destination = L.latLng(this.latitude(), this.longitude());
    const map = L.map(this.mapElement.nativeElement, {
      center: destination,
      zoom: 16,
      zoomControl: false,
      attributionControl: true,
    });
    this.leafletMap = map;
    L.control.zoom({ position: 'bottomright' }).addTo(map);
    L.tileLayer(environment.mapTileUrl, {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);

    const marker = L.marker(destination, {
      icon: L.divIcon({
        className: 'destination-marker',
        html: '<span class="destination-marker__pin" aria-hidden="true"><span>●</span></span>',
        iconSize: [38, 38],
        iconAnchor: [19, 35],
      }),
    }).addTo(map);
    marker.bindTooltip(this.address(), { direction: 'top', offset: [0, -28] });

    if (!route || route.path.length < 2) return;
    const points = route.path.map<L.LatLngTuple>((point) => [point.latitude, point.longitude]);
    L.polyline(points, { color: '#0f6b6d', opacity: 0.95, weight: 6 }).addTo(map);
    L.circleMarker([route.originLatitude, route.originLongitude], {
      color: '#fff',
      fillColor: '#0f7b7e',
      fillOpacity: 1,
      radius: 9,
      weight: 4,
    }).bindTooltip('Current driver position').addTo(map);
    map.fitBounds(L.latLngBounds([...points, destination]), { padding: [58, 58], maxZoom: 16 });
  }
}
