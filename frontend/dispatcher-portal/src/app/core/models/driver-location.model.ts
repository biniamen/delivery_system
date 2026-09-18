export type LocationFreshness = 'Unavailable' | 'Live' | 'Recent' | 'Stale';

export interface DriverLoadOrder {
  orderId: string;
  orderNumber: string;
  status: 'New' | 'Assigned' | 'Accepted' | 'PickedUp' | 'Delivered' | 'DeliveryConfirmed' | 'Cancelled';
  itemCount: number;
  total: number;
  deliveryAddress: string;
  deliveryLatitude: number | null;
  deliveryLongitude: number | null;
}

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
  activeOrderCount: number;
  activeItemCount: number;
  activeOrders: DriverLoadOrder[];
}
