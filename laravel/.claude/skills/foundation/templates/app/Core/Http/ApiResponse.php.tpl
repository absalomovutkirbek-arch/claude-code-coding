<?php

declare(strict_types=1);

namespace App\Core\Http;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\Response;

/**
 * The only place that builds success responses: `{"data": ..., "meta": {...}}`.
 */
final class ApiResponse
{
    /**
     * @param  array<string, mixed>  $meta
     */
    public static function ok(mixed $data, array $meta = [], int $status = 200): JsonResponse
    {
        if ($data instanceof JsonResource) {
            $data = $data->resolve();
        }

        return new JsonResponse(['data' => $data, 'meta' => (object) $meta], $status);
    }

    public static function created(mixed $data): JsonResponse
    {
        return self::ok($data, status: 201);
    }

    /**
     * @param  class-string<JsonResource>  $resource
     */
    public static function paginated(LengthAwarePaginator $page, string $resource): JsonResponse
    {
        return self::ok($resource::collection($page->items()), [
            'page' => $page->currentPage(),
            'per_page' => $page->perPage(),
            'total' => $page->total(),
            'total_pages' => $page->lastPage(),
        ]);
    }

    public static function noContent(): Response
    {
        return new Response(status: 204);
    }
}
