<?php

declare(strict_types=1);

namespace App\Core\Http;

use App\Core\Exceptions\ConflictException;
use App\Core\Exceptions\DomainException;
use App\Core\Exceptions\ForbiddenException;
use App\Core\Exceptions\NotFoundException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Throwable;

/**
 * The single place where exceptions become HTTP responses.
 *
 * Renders every API failure as `{"error": {"code", "message", "details"}}`.
 *
 * Laravel 11+: in bootstrap/app.php
 *     ->withExceptions(fn (Exceptions $exceptions) => ApiExceptionRenderer::register($exceptions))
 * Laravel 10: in App\Exceptions\Handler::register()
 *     $this->renderable(ApiExceptionRenderer::render(...)); and add DomainException to $dontReport.
 */
final class ApiExceptionRenderer
{
    private const HTTP_CODES = [
        400 => 'bad_request',
        401 => 'unauthorized',
        403 => 'forbidden',
        404 => 'not_found',
        405 => 'method_not_allowed',
        409 => 'conflict',
        415 => 'unsupported_media_type',
        419 => 'session_expired',
        422 => 'unprocessable_entity',
        429 => 'too_many_requests',
        503 => 'service_unavailable',
    ];

    public static function register(Exceptions $exceptions): void
    {
        // Expected outcomes, not application errors.
        $exceptions->dontReport(DomainException::class);

        $exceptions->render(self::render(...));
    }

    /**
     * Returns null for non-API requests so that Laravel renders its usual HTML pages.
     */
    public static function render(Throwable $exception, Request $request): ?JsonResponse
    {
        if (! $request->is('api/*') && ! $request->expectsJson()) {
            return null;
        }

        [$status, $error] = self::toError($exception);

        return new JsonResponse(['error' => $error], $status);
    }

    /**
     * @return array{0: int, 1: array<string, mixed>}
     */
    private static function toError(Throwable $exception): array
    {
        if ($exception instanceof DomainException) {
            $error = ['code' => $exception->errorCode(), 'message' => $exception->getMessage()];
            if ($exception->details() !== []) {
                $error['details'] = $exception->details();
            }

            return [self::statusOf($exception), $error];
        }

        if ($exception instanceof ValidationException) {
            return [422, [
                'code' => 'validation_failed',
                'message' => 'The given data is invalid.',
                'details' => $exception->errors(),
            ]];
        }

        if ($exception instanceof AuthenticationException) {
            return [401, ['code' => 'unauthorized', 'message' => 'Authentication is required.']];
        }

        if ($exception instanceof HttpExceptionInterface) {
            $status = $exception->getStatusCode();
            $code = self::HTTP_CODES[$status] ?? 'http_error';

            return [$status, [
                'code' => $code,
                'message' => $exception->getMessage() !== '' ? $exception->getMessage() : ucfirst(str_replace('_', ' ', $code)).'.',
            ]];
        }

        $error = ['code' => 'internal_error', 'message' => 'Internal server error.'];
        if (config('app.debug') === true) {
            $error['details'] = [
                'type' => $exception::class,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile().':'.$exception->getLine(),
            ];
        }

        return [500, $error];
    }

    private static function statusOf(DomainException $exception): int
    {
        return match (true) {
            $exception instanceof NotFoundException => 404,
            $exception instanceof ForbiddenException => 403,
            $exception instanceof ConflictException => 409,
            default => 422,
        };
    }
}
