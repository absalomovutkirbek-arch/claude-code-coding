---
paths:
  - "tests/**/*.php"
---

# Yii2: testing

Follow `common/testing.md` for what to test. This file covers how in Yii2.

- Runner: Codeception (`vendor/bin/codecept run unit`, `vendor/bin/codecept run api`) unless "Project facts" in `CLAUDE.md` names another.
- Unit tests mirror the module tree: `tests/unit/modules/<module>/<Class>Test.php`, namespace `tests\unit\modules\<module>`.
- Method names: `test_<behaviour>_<condition>` in `snake_case`.

## Service tests

```php
protected function setUp(): void
{
    $this->wallets = $this->createMock(WalletRepositoryInterface::class);
    $this->transfers = $this->createMock(TransferRepositoryInterface::class);
    $this->events = $this->createMock(EventDispatcherInterface::class);

    $transaction = $this->createStub(TransactionManagerInterface::class);
    $transaction->method('run')->willReturnCallback(static fn (callable $callback): mixed => $callback());

    $this->service = new TransferService($this->wallets, $this->transfers, $transaction, $this->events);
}
```

- Construct the service with `new` and mocked interfaces. Do not resolve it from the container.
- The transaction manager is a stub that just runs the callback.
- Mocked `save()` assigns an ID when the code under test reads it afterwards: `->willReturnCallback(static function (Transfer $t): void { $t->id = 77; })`.
- Build models with a private helper using `setAttributes([...], false)`.
- ActiveRecord reads the table schema even in unit tests, so the unit suite needs the test database with migrations applied. No rows are read or written in service tests.
- Assert the specific exception class, and that nothing was saved or dispatched on failure (`expects($this->never())`).

The complete example is `.claude/skills/new-endpoint/reference/tests/unit/modules/billing/TransferServiceTest.php.tpl`.

## Repository and API tests

- Repository tests run against the real test database inside a transaction that is rolled back. Test filters, pagination, locking queries and constraint translation.
- API tests send real HTTP-shaped requests and assert status code, `data` / `error.code` and the database effect. Minimum per endpoint: success, validation failure (422 `validation_failed`), unauthenticated (401) or forbidden (403).
