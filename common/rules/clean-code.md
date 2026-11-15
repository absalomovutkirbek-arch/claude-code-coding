# Clean code

## Principles, as concrete rules

- **Single responsibility**: a class has one reason to change. If its name needs "And" or "Manager", split it.
- **Open/closed**: add a new variant by adding a class (strategy, handler), not by adding another `if`/`switch` branch to existing business code.
- **Liskov**: an implementation must honour its interface without surprises. No "not supported" methods.
- **Interface segregation**: small interfaces named after what the caller needs. Do not add methods "for later".
- **Dependency inversion**: business code depends on interfaces it owns. Framework and infrastructure details sit behind them.
- **DRY**: remove duplicated *knowledge* (a rule, a formula, a mapping). Two pieces of code that merely look alike but change for different reasons stay separate. Extract on the third repetition, not the second.
- **KISS**: choose the simplest design that satisfies the current requirement. A plain method beats a pattern when both work.
- **YAGNI**: do not add parameters, config options, abstractions or generic layers for requirements nobody has stated.

## Naming

- Names say what, not how: `findActiveByCustomer`, not `getData2`.
- Classes are nouns, methods are verbs. Booleans read as questions: `isPaid`, `hasStock`, `canCancel`.
- One word per concept across the project. Pick `find` (nullable) / `get` (throws) / `list` (collection) / `create` / `update` / `delete` and keep them.
- Class suffix states the role: `...Action`, `...Form`, `...Dto`, `...Service`, `...Repository`, `...Handler`, `...Strategy`, `...Resource`, `...Exception`, `...Event`, `...Listener`, `...Job`.
- Use-case classes start with the verb: `CreateOrder...`, `CancelOrder...`.
- No abbreviations except domain-standard ones (`id`, `url`, `vat`).
- Code, identifiers, comments and commit messages are in English.

## Functions and classes

- A function does one thing at one level of abstraction. Aim for under 30 lines; past 50, split it.
- Maximum 3 parameters. More than that becomes a DTO.
- No boolean flag parameters that switch behaviour. Write two methods.
- Return early. Avoid nesting deeper than 2 levels.
- No hidden side effects: a method named `get...`/`find...`/`is...` never writes.
- Classes are `final` by default. Prefer composition to inheritance.
- Properties are private and typed. Expose behaviour, not state.

## Types and values

- Declare types on every parameter, return value and property. Enable strict typing where the language has it.
- No magic strings or numbers. Statuses, types and kinds are enums. Limits and thresholds are named constants or config.
- Do not return `null`, `false` or `-1` to signal an error. Throw a typed exception. `null` is allowed only for "optional value is absent" in `find...` methods.
- Do not pass associative arrays / maps as structured data between layers. Use a DTO.
- Money is never a float. Use decimal strings or integer minor units.
- Store and compute time in UTC. Convert at the edge.

## Comments

- Code explains what. Comments explain why, and only when the why is not obvious (a business rule, a workaround, a non-obvious constraint).
- No commented-out code, no change-history comments, no TODO without an owner or ticket.
- Public contracts (interfaces, service methods) document what they throw.

## Hygiene

- Leave no dead code, unused imports, debug output or unused parameters.
- Match the formatting standard of the stack and run the formatter before finishing.
- Do not reformat or rename code unrelated to the task.
