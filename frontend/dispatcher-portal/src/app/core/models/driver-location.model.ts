export type LocationFreshness = 'Unavailable' | 'Live' | 'Recent' | 'Stale';

export interface DriverLocation {
  driverId: string;
  displayName: string;
  freshness: LocationFreshness;
  latitude: number | null;
  longitude: number | null;
  accuracyMeters: number | null;
  headingDegrees: number | null;
  speedMetersPerSecond: number | null;
  capturedAtUtc: string | null;
  receivedAtUtc: string | null;
}
