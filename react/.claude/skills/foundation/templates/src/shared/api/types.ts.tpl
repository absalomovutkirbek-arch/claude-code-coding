/** Success envelope of the backend: `{"data": ..., "meta": {...}}`. */
export interface ApiSuccess<T, M = Record<string, unknown>> {
  data: T;
  meta: M;
}

/** Pagination meta as the API sends it. */
export interface PageMetaDto {
  page: number;
  per_page: number;
  total: number;
  total_pages: number;
}

/** A page of domain objects as the application uses it. */
export interface Page<T> {
  items: T[];
  page: number;
  perPage: number;
  total: number;
  totalPages: number;
}

export function toPage<D, T>(response: ApiSuccess<D[], PageMetaDto>, map: (dto: D) => T): Page<T> {
  return {
    items: response.data.map(map),
    page: response.meta.page,
    perPage: response.meta.per_page,
    total: response.meta.total,
    totalPages: response.meta.total_pages,
  };
}
