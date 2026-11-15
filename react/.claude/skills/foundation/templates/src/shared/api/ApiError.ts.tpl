export type ApiErrorDetails = Record<string, unknown>;

/**
 * Every failed request, normalised. Thrown only by `shared/api/http.ts`.
 *
 * UI code branches on `code` (stable, from the backend's `error.code`), never on `message` or `status`.
 * Two codes are produced on the client: `network_error` (no response) and `http_error` (response without the envelope).
 */
export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details: ApiErrorDetails;

  constructor(status: number, code: string, message: string, details: ApiErrorDetails = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }

  /** Field messages of a `validation_failed` error, keyed by the API field name (snake_case). */
  get fieldErrors(): Record<string, string[]> {
    if (this.code !== 'validation_failed') {
      return {};
    }

    const fields: Record<string, string[]> = {};
    for (const [field, messages] of Object.entries(this.details)) {
      fields[field] = Array.isArray(messages) ? messages.map(String) : [String(messages)];
    }

    return fields;
  }
}

export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError;
}
