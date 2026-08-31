export interface ApiProblem {
  status?: number;
  title?: string;
  detail?: string;
  traceId?: string;
  errors?: Record<string, string[]>;
}

