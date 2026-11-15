import axios, { type AxiosRequestConfig } from 'axios';

import { tokenStore } from '@/shared/auth/tokenStore';

import { ApiError, type ApiErrorDetails } from './ApiError';
import type { ApiSuccess } from './types';

/**
 * The only module that talks to the network.
 *
 * Feature code calls it from `features/<feature>/api/*.api.ts` and nowhere else.
 * Every method resolves with the success envelope and rejects with an `ApiError`.
 */
const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? '/api/v1',
  headers: { Accept: 'application/json' },
});

let onUnauthorized: (() => void) | null = null;

/** Registered once by the app shell, e.g. to redirect to the login page. */
export function setUnauthorizedHandler(handler: () => void): void {
  onUnauthorized = handler;
}

client.interceptors.request.use((config) => {
  const token = tokenStore.get();
  if (token !== null) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error: unknown) => {
    const apiError = toApiError(error);
    if (apiError.status === 401) {
      onUnauthorized?.();
    }

    return Promise.reject(apiError);
  },
);

function toApiError(error: unknown): ApiError {
  if (!axios.isAxiosError(error) || error.response === undefined) {
    return new ApiError(0, 'network_error', 'The server cannot be reached. Check your connection and try again.');
  }

  const { status, data } = error.response;
  const body = isRecord(data) && isRecord(data.error) ? data.error : null;
  if (body !== null && typeof body.code === 'string') {
    const message = typeof body.message === 'string' ? body.message : 'The request failed.';
    const details = isRecord(body.details) ? (body.details as ApiErrorDetails) : {};

    return new ApiError(status, body.code, message, details);
  }

  return new ApiError(status, 'http_error', `The request failed with status ${status}.`);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

type Query = Record<string, string | number | boolean | undefined>;

async function request<T, M>(config: AxiosRequestConfig): Promise<ApiSuccess<T, M>> {
  const response = await client.request<ApiSuccess<T, M>>(config);

  return response.data;
}

export const http = {
  get<T, M = Record<string, unknown>>(url: string, params?: Query): Promise<ApiSuccess<T, M>> {
    return request<T, M>({ method: 'GET', url, params });
  },
  post<T>(url: string, body?: unknown): Promise<ApiSuccess<T>> {
    return request<T, Record<string, unknown>>({ method: 'POST', url, data: body });
  },
  put<T>(url: string, body?: unknown): Promise<ApiSuccess<T>> {
    return request<T, Record<string, unknown>>({ method: 'PUT', url, data: body });
  },
  patch<T>(url: string, body?: unknown): Promise<ApiSuccess<T>> {
    return request<T, Record<string, unknown>>({ method: 'PATCH', url, data: body });
  },
  async delete(url: string): Promise<void> {
    await client.request({ method: 'DELETE', url });
  },
};
