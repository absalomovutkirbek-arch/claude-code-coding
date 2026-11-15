# Design patterns

A pattern is used when its trigger condition is met, and not before. When in doubt, write the plain version first.

## Decision table

| Situation | Use | Do not use when |
| --- | --- | --- |
| A use case has 3+ ordered steps, or steps that are reused, reordered or toggled per case | **Pipeline (Chain of Responsibility)**: one handler class per step, one context object | 1-2 steps. Write private methods in the service |
| 2+ interchangeable ways to do the same job, chosen at runtime (payment provider, pricing rule, export format) | **Strategy**: one interface, one class per variant, one resolver | Only one variant exists today. Write it directly; extract when the second arrives |
| Object creation needs a decision or several steps | **Factory** | A constructor call is enough |
| Something happened and other parts must react (notify, audit, sync) | **Domain event + listeners** | The reaction is part of the use case itself and must succeed or fail with it |
| Slow or retryable work (email, external API, report) | **Queued job** | The caller needs the result in the same request |
| The same filtering rule is combined in several queries | **Query object / scope / specification** inside the repository | A single query uses it |
| A third-party API or SDK | **Adapter / gateway** behind an interface owned by the module | Never skip this. External services are always wrapped |
| Cross-cutting behaviour around a service (cache, logging, retry) | **Decorator** over the interface | The behaviour is specific to one method |

## Pipeline rules

- The service builds and runs the pipeline. The pipeline is an implementation detail of one use case.
- One context class per pipeline, typed, created by the service from the DTO. Handlers read and write only the context.
- One handler = one step = one class. A handler may stop the chain by throwing a business exception or by not calling the next handler.
- Handlers are stateless and receive dependencies through the constructor.
- The handler order is declared in one place and readable top to bottom.
- If the pipeline writes to several tables, the service wraps the whole run in one transaction.

## Strategy rules

- The interface is named after the job (`PaymentGateway`, `DiscountCalculator`), each class after the variant (`ClickPaymentGateway`).
- Selection lives in one resolver that maps an enum value to a strategy. No `switch` on the type anywhere else.
- Adding a variant means adding a class and one line in the resolver. Nothing else changes.

## Forbidden

- Patterns added "for flexibility" without a stated requirement.
- Singletons and static service locators in business code.
- Inheritance trees deeper than 2 levels for sharing code.
- God services. Past roughly 7 public methods or 300 lines, split by use case.
