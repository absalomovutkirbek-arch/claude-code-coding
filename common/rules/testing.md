# Testing

## What must be tested

| Code | Test type | Minimum |
| --- | --- | --- |
| Service method | Unit, repositories and gateways mocked through their interfaces | Happy path + every business rule that can reject |
| Pipeline handler | Unit | What it changes in the context + when it stops the chain |
| Strategy | Unit, one test class per variant | Shared contract cases + variant-specific cases |
| Repository | Integration against a real test database | Non-trivial queries (filters, joins, locking). Trivial `findById` needs no test |
| Endpoint | Functional / API | One success case + one validation failure + one authorization failure |
| Bug fix | Whatever level reproduces it | A test that fails before the fix and passes after |

New or changed business code without tests is not finished.

## How

- Structure every test as Arrange / Act / Assert, separated by blank lines.
- One behaviour per test. The name states it: `test_cancel_fails_when_order_is_already_shipped`.
- Test behaviour through the public API of the class. Do not test private methods or assert on internal calls unless the call itself is the behaviour (an event was dispatched, a gateway was charged).
- Mock only what you own at a boundary: repository interfaces, gateways, clock, event dispatcher. Do not mock the class under test, DTOs or value objects.
- No real network, time or randomness in unit tests. Inject a clock and ID generator where the logic depends on them.
- Build test data with factories / builders that provide valid defaults, overriding only what the test is about.
- Tests are independent: no shared mutable state, no required order. Database tests run in a transaction that rolls back, or reset the schema.
- Assert on the specific exception type and error code, not only "an exception was thrown".

## When finishing a task

- Run the tests for the code you touched, then the full suite of the module if it is fast.
- Never delete, skip or weaken a failing test to get green. Fix the code, or stop and report why the test is wrong.
- Report what was run and the result. If tests could not be run, say so.
