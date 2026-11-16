---
name: new-feature
description: Create a new feature folder (one backend module or business area) with its routes and public API, and register it in the router. Use when a screen or resource does not belong to any existing feature.
argument-hint: "[feature-name] [short purpose]"
---

# New feature

Create the feature `$ARGUMENTS`.

## 1. Decide whether a new feature is right

A feature is a business area, usually one backend module (`billing`, `order`, `catalog`), not a single component and not a technical grouping. If the screen works with a resource an existing feature already owns, add it there instead and say so.

Feature name: the backend module's name, lowercase, singular where the backend is (`billing`, `order`).

## 2. Preconditions

- `src/shared/api/http.ts` exists. If not, run `/foundation` first.
- Read "Project facts" in `CLAUDE.md` for the UI kit, i18n and commands.

## 3. Create

1. `src/features/<feature>/routes.tsx`:

```tsx
import type { RouteObject } from 'react-router-dom';

/** Routes of the billing feature. Pages are loaded lazily, so each page is its own chunk. */
export const billingRoutes: RouteObject[] = [];
```

2. `src/features/<feature>/index.ts`:

```ts
/**
 * Public API of the billing feature. Other features and the app shell import only from here.
 */
export { billingRoutes } from './routes';
```

3. Register in `src/app/router.tsx`: `...billingRoutes` inside the router's route array (inside the protected layout route if the area needs a session).
4. `src/features/<feature>/errors.ts` with an empty `Record<string, string>` for the feature's error-code texts, once the first endpoint is connected.

Do not create empty layer folders. They appear with their first file.

## 4. Next steps

- Connect the backend resource with `/new-api-resource`.
- Add screens with `/new-page` and forms with `/new-form`.

## 5. Report

List created files and the router change, and name the next step.
