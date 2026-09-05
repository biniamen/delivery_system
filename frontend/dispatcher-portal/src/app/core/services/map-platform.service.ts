import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { importLibrary, setOptions } from '@googlemaps/js-api-loader';
import { catchError, firstValueFrom, of, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import { GoogleMapLibraries, MapsClientConfiguration } from '../models/map.model';

const fallbackConfiguration: MapsClientConfiguration = {
  googleMapsEnabled: false,
  googleWebServicesEnabled: false,
  provider: 'OpenStreetMap',
  browserApiKey: null,
  mapId: 'DEMO_MAP_ID',
};

@Injectable({ providedIn: 'root' })
export class MapPlatformService {
  private readonly http = inject(HttpClient);
  private readonly configuration$ = this.http
    .get<MapsClientConfiguration>(`${environment.apiBaseUrl}/maps/browser-configuration`)
    .pipe(
      catchError(() => of(fallbackConfiguration)),
      shareReplay({ bufferSize: 1, refCount: false }),
    );

  private googleLibraries?: Promise<GoogleMapLibraries | null>;

  loadGoogleMaps(): Promise<GoogleMapLibraries | null> {
    this.googleLibraries ??= this.initializeGoogleMaps();
    return this.googleLibraries;
  }

  private async initializeGoogleMaps(): Promise<GoogleMapLibraries | null> {
    const configuration = await firstValueFrom(this.configuration$);
    if (!configuration.googleMapsEnabled || !configuration.browserApiKey) return null;

    setOptions({
      key: configuration.browserApiKey,
      v: 'weekly',
      language: 'en',
      region: 'ET',
      mapIds: [configuration.mapId],
      authReferrerPolicy: 'origin',
    });

    try {
      const [maps, marker] = await Promise.all([
        importLibrary('maps'),
        importLibrary('marker'),
      ]);
      return { configuration, maps, marker };
    } catch {
      return null;
    }
  }
}
