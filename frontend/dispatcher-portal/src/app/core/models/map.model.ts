export interface MapsClientConfiguration {
  googleMapsEnabled: boolean;
  googleWebServicesEnabled: boolean;
  provider: string;
  browserApiKey: string | null;
  mapId: string;
}

export interface RoutePoint {
  latitude: number;
  longitude: number;
}

export interface DeliveryRoute {
  orderId: string;
  originLatitude: number;
  originLongitude: number;
  destinationLatitude: number;
  destinationLongitude: number;
  distanceMeters: number;
  durationSeconds: number;
  distanceText: string;
  durationText: string;
  path: RoutePoint[];
  provider: string;
  calculatedAtUtc: string;
}

export interface GoogleMapLibraries {
  configuration: MapsClientConfiguration;
  maps: google.maps.MapsLibrary;
  marker: google.maps.MarkerLibrary;
}
