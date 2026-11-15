import { setupServer } from 'msw/node';

/** Mock backend for tests. Each test registers the handlers it needs with `server.use(...)`. */
export const server = setupServer();
