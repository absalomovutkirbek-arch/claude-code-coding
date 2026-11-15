<?php

declare(strict_types=1);

namespace app\core\data;

/**
 * One page of a paginated result, returned by repositories.
 *
 * @template T
 */
final class Page
{
    /**
     * @param list<T> $items
     */
    public function __construct(
        public readonly array $items,
        public readonly int $total,
        public readonly int $page,
        public readonly int $perPage,
    ) {
    }

    public function totalPages(): int
    {
        return $this->perPage > 0 ? (int) ceil($this->total / $this->perPage) : 0;
    }
}
