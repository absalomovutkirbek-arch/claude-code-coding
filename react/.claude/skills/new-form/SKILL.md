---
name: new-form
description: Build a form as a full slice - zod schema with form values, defaults and input mapping, react-hook-form component, server error mapping, and tests. Use for any create or edit form or other user input that is sent to the backend.
argument-hint: "[feature] [FormName] [fields] [which mutation it calls]"
---

# New form

Build the form `$ARGUMENTS`.

Reference, under `.claude/skills/new-api-resource/reference/src/features/billing/`: `schemas/createTransfer.schema.ts.tpl`, `components/CreateTransferForm.tsx.tpl` and their tests.

## 1. Clarify

State in a few lines and confirm anything unclear with the developer:

- Fields: label, type of control, required or optional, limits. They must match the backend's request validation; read it if you can.
- Which mutation hook is called. If it is missing, run `/new-api-resource` first.
- Which error codes the endpoint can return and the text for each.
- What happens after success (close, navigate, reset, message).
- For an edit form: where the initial values come from.

## 2. Build in this order

1. `schemas/<verb><Entity>.schema.ts`:
   - the zod schema with format rules and user-facing messages;
   - `type <Verb><Entity>FormValues = z.infer<typeof schema>`;
   - `<verb><Entity>Defaults`;
   - `to<Verb><Entity>Input(values)` that converts strings to the typed API input (numbers, minor units through `toMinorUnits()`, enums, trimmed strings, empty optional strings to `null`).
2. Texts for the endpoint's business error codes in the feature's `errors.ts`.
3. `components/<Verb><Entity>Form.tsx`:
   - `useForm` with `zodResolver(schema)` and `defaultValues`;
   - submit through the mutation hook: `mutation.mutate(toInput(values), { onSuccess, onError })`;
   - `onError`: `applyServerErrors(error, setError, { fields: [...], messages })`;
   - each field with `<label htmlFor>`, `aria-invalid`, and its message with `role="alert"`;
   - the form-level message from `errors.root?.server`;
   - submit button disabled and relabelled while `isPending`.
4. Edit form: the page loads the entity with the query hook and renders the form only when data is there, passing initial values as a prop that the form maps to `defaultValues` (`fromEntity(entity)` in the schema file).

## 3. Rules

- The schema checks format only. Do not re-implement business rules (balance, uniqueness, ownership) in the browser; show the backend's answer.
- No `useState` per field, no validation inside `onSubmit`, no API call from the component.
- Never disable the submit button because the form is invalid.
- With a UI kit: use its inputs through `Controller` or the kit's react-hook-form adapter, and its field wrapper for labels and errors.
- Select options for enums are built from the model's `as const` object with a label map typed as `Record<Enum, string>`.

## 4. Test

`schemas/<name>.schema.test.ts`:

- valid values parse, and `toInput()` produces the exact API input;
- each rejecting rule fails and reports under the right field.

`components/<Name>Form.test.tsx` with `renderWithProviders()` and MSW:

- invalid input shows the messages and sends no request;
- valid input sends the expected wire body (captured in the handler) and calls the success callback;
- a business error code shows its text;
- a `validation_failed` response puts the message under the field.

## 5. Verify and report

1. `npm run typecheck`, `npm run lint`, `npx vitest run src/features/<feature>`.
2. Report: fields and their rules, the mutation used, error codes handled with their texts, what was assumed.
