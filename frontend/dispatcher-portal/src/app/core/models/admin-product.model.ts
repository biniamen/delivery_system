export interface AdminCategory {
  id: string;
  name: string;
  slug: string;
}

export interface AdminProduct {
  id: string;
  categoryId: string;
  categoryName: string;
  name: string;
  description: string;
  unit: string;
  price: number;
  imageUrl: string;
  stockQuantity: number;
  isAvailable: boolean;
}

export interface AdminCatalogue {
  categories: AdminCategory[];
  products: AdminProduct[];
}

export interface SaveProductRequest {
  categoryId: string;
  name: string;
  description: string;
  unit: string;
  price: number;
  imageUrl: string;
  stockQuantity: number;
  isAvailable: boolean;
}
