export type OrderStatus = 'New' | 'Assigned' | 'Accepted' | 'PickedUp' | 'Delivered' | 'Cancelled';
export type PaymentMethod = 'DemoCash' | 'DemoCard';

export interface OrderSummary {
  id: string;
  orderNumber: string;
  contactName: string;
  status: OrderStatus;
  total: number;
  assignedDriverId: string | null;
  createdAtUtc: string;
}

export interface OrderLine {
  productId: string;
  productName: string;
  unit: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

export interface OrderStatusHistory {
  status: OrderStatus;
  changedByUserId: string;
  changedAtUtc: string;
  note: string | null;
}

export interface Order {
  id: string;
  orderNumber: string;
  customerId: string;
  assignedDriverId: string | null;
  contactName: string;
  phoneNumber: string;
  deliveryAddress: string;
  paymentMethod: PaymentMethod;
  status: OrderStatus;
  subtotal: number;
  deliveryFee: number;
  total: number;
  createdAtUtc: string;
  updatedAtUtc: string;
  lines: OrderLine[];
  statusHistory: OrderStatusHistory[];
}

export interface AssignDriverRequest {
  driverId: string;
}

