---
paths:
  - "tests/**/*.php"
---

# Laravel: testing

Follow `common/testing.md` for what to test. This file covers how in Laravel.

- Runner: PHPUnit through `php artisan test` (Pest when "Project facts" in `CLAUDE.md` says so).
- Tests mirror the module tree: `tests/Unit/Modules/<Module>/<Class>Test.php` and `tests/Feature/Modules/<Module>/<Entity>ApiTest.php`.
- Method names: `test_<behaviour>_<condition>` in `snake_case`.

## Service tests (unit)

```php
protected function setUp(): void
{
    parent::setUp();

    $this->wallets = $this->createMock(WalletRepositoryInterface::class);
    $this->transfers = $this->createMock(TransferRepositoryInterface::class);
    $this->events = $this->createMock(Dispatcher::class);

    $transaction = new class implements TransactionManagerInterface
    {
        public function run(callable $callback): mixed
        {
            return $callback();
        }
    };

    $this->service = new TransferService($this->wallets, $this->transfers, $transaction, $this->events);
}
```

- Extend `PHPUnit\Framework\TestCase`, not `Tests\TestCase`. A service test boots no framework and touches no database. If it cannot be written that way, the service depends on a facade or a query and must be fixed.
- Construct the service with `new` and mocked interfaces.
- The transaction manager is a stub that just runs the callback.
- Mocked `save()` assigns an ID when the code under test reads it afterwards: `->willReturnCallback(static function (Transfer $t): void { $t->id = 77; })`.
- Build models with a private helper: `new Wallet` plus explicit attribute assignment. Never `factory()->create()` in unit tests.
- Assert the specific exception class, and that nothing was saved or dispatched on failure (`expects($this->never())`).

The complete example is `.claude/skills/new-endpoint/reference/tests/Unit/Modules/Billing/TransferServiceTest.php.tpl`.

## Endpoint tests (feature)

- Extend `Tests\TestCase` with `RefreshDatabase`. The test database is PostgreSQL, never SQLite: schemas, `CHECK` constraints and row locks must behave as in production. `phpunit.xml` sets `DB_CONNECTION=pgsql`, a dedicated `DB_DATABASE` and `DB_SEARCH_PATH` with every module schema.
- Authenticate with `$this->actingAs($user, 'sanctum')`. Send JSON with `postJson()` / `getJson()`.
- Assert status code, `data` / `error.code` with `assertJsonPath()`, and the database effect with `assertDatabaseHas('billing.wallets', [...])`.
- Minimum per endpoint: success, validation failure (422 `validation_failed`), unauthenticated (401), each rejecting business rule with its error code, and that a rejected request changed nothing.
- Fake only the edges: `Event::fake([...])`, `Queue::fake()`, `Http::fake()`. Never mock the service or repository in a feature test.

The complete example is `.claude/skills/new-endpoint/reference/tests/Feature/Modules/Billing/TransferApiTest.php.tpl`.

## Repository tests

- Run against the real test database with `RefreshDatabase`. Test filters, pagination, locking queries and constraint translation. Simple `findById` / `save` are covered by the feature tests.
