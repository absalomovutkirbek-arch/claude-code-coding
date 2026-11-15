/**
 * Holds the access token for `shared/api/http.ts`.
 *
 * Kept in memory on purpose: where the token persists (httpOnly cookie, refresh flow) is a project decision
 * and is implemented here, in one place. Nothing else reads or stores tokens.
 */
let accessToken: string | null = null;

export const tokenStore = {
  get(): string | null {
    return accessToken;
  },
  set(token: string): void {
    accessToken = token;
  },
  clear(): void {
    accessToken = null;
  },
};
