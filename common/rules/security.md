# Security

- **Authentication and authorization**: every endpoint declares who may call it. Check ownership of the specific record, not only the role ("this user may edit *this* order"). Deny by default.
- **Input**: treat every external value as hostile: body, query, headers, files, webhooks, queue payloads. Validate at the edge and whitelist fields; never bind raw input to models (mass assignment).
- **SQL**: parameterized queries only. Sort and filter fields come from a whitelist.
- **Output**: return data through Resources so internal fields never leak. Escape output in HTML contexts.
- **Secrets**: only in environment variables or a secret manager. Never in code, config files in git, logs, error messages or test fixtures. Never read or print `.env` contents.
- **Passwords and tokens**: hash passwords with the framework's adaptive hasher. Tokens are random, stored hashed where possible, and expire.
- **Files**: validate type and size, generate the stored file name yourself, store outside the web root.
- **Rate limiting**: on authentication, OTP/SMS, password reset and any endpoint that costs money.
- **Webhooks and callbacks**: verify the signature before trusting the payload. Make handlers idempotent.
- **Errors**: no stack traces, SQL or internal paths in responses outside debug mode.
- **Dependencies**: add a new package only when needed, from a maintained source, pinned by the lock file. Mention every new dependency in the summary.
- **Personal data**: collect the minimum, do not log it, and mask it where full values are not required.
