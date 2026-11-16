---
paths:
  - "src/**/schemas/**/*.ts"
  - "src/**/*Form.tsx"
  - "src/shared/forms/**/*.ts"
---

# React: forms (zod schema, react-hook-form, server errors)

## Schema

```ts
export const createTransferSchema = z
  .object({
    fromWalletId: walletId,
    toWalletId: walletId,
    amount: z.string().trim().refine((value) => (toMinorUnits(value) ?? 0) > 0, 'Enter an amount greater than zero.'),
  })
  .refine((values) => values.fromWalletId !== values.toWalletId, {
    path: ['toWalletId'],
    message: 'Source and destination wallets must be different.',
  });

export type CreateTransferFormValues = z.infer<typeof createTransferSchema>;

export const createTransferDefaults: CreateTransferFormValues = { fromWalletId: '', toWalletId: '', amount: '' };

export function toCreateTransferInput(values: CreateTransferFormValues): CreateTransferInput { /* strings -> typed input */ }
```

- One schema file per form: `schemas/<verb><Entity>.schema.ts`. It exports the schema, the form values type, the defaults and `to<Verb><Entity>Input()`.
- Form values are what the inputs hold: strings for text and number inputs, booleans for checkboxes. Conversion to numbers, minor units and enums happens once, in `toInput()`.
- The schema checks format only and mirrors the backend's request validation: required, length, pattern, range, cross-field format rules (with `path` pointing at the field). It is a convenience for the user; the backend stays the authority.
- Business rules (balance, ownership, uniqueness, state) are not re-implemented in the browser. They come back as error codes.
- Messages are complete sentences telling the user what to enter.
- Amounts are parsed with `toMinorUnits()`. Never `parseFloat` and multiply.

## Form component

```tsx
const createTransfer = useCreateTransfer();
const { register, handleSubmit, setError, reset, formState: { errors } } = useForm<CreateTransferFormValues>({
  resolver: zodResolver(createTransferSchema),
  defaultValues: createTransferDefaults,
});

const submit = handleSubmit((values) =>
  createTransfer.mutate(toCreateTransferInput(values), {
    onSuccess: (transfer) => { reset(); onCreated?.(transfer); },
    onError: (error) => applyServerErrors(error, setError, { fields: ['fromWalletId', 'toWalletId', 'amount'], messages: transferErrorMessages }),
  }),
);
```

- `useForm` with `zodResolver` and explicit `defaultValues`. No hand-written `useState` per field, no manual validation in `onSubmit`.
- Submit calls the feature's mutation hook. The form never calls an API function or `http` directly.
- Server errors go through `applyServerErrors()`: `validation_failed` details land under their fields (API `snake_case` names are matched to the camelCase fields), every other code shows as a form-level message from the feature's `errors.ts` under `errors.root.server`.
- `<form onSubmit={submit} noValidate>`: validation messages come from the schema, not from the browser.
- Each field: `<label htmlFor>`, the input with `{...register('name')}`, `aria-invalid`, and the message in an element with `role="alert"`. With a UI kit, wrap this once in a `shared/ui` field component and use `Controller` for controlled inputs.
- The submit button is disabled while the mutation `isPending` and says so. Never disable it just because the form is invalid: the user must be able to submit and see what is wrong.
- After success: reset or close, and report through a callback prop. The mutation hook invalidates the affected queries.
- Edit forms load the entity with the feature's query hook and pass it as `values` (or `defaultValues` after it loaded); they do not copy it into state.
