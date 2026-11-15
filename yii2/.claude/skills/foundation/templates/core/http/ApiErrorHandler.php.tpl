<?php

declare(strict_types=1);

namespace app\core\http;

use app\core\exceptions\ConflictException;
use app\core\exceptions\DomainException;
use app\core\exceptions\ForbiddenException;
use app\core\exceptions\NotFoundException;
use Throwable;
use Yii;
use yii\web\ErrorHandler;
use yii\web\HttpException;
use yii\web\Response;

/**
 * The single place where exceptions become HTTP responses.
 *
 * Renders every failure as `{"error": {"code", "message", "details"}}`.
 */
final class ApiErrorHandler extends ErrorHandler
{
    private const HTTP_CODES = [
        400 => 'bad_request',
        401 => 'unauthorized',
        403 => 'forbidden',
        404 => 'not_found',
        405 => 'method_not_allowed',
        409 => 'conflict',
        415 => 'unsupported_media_type',
        422 => 'unprocessable_entity',
        429 => 'too_many_requests',
    ];

    public function logException($exception): void
    {
        if ($exception instanceof DomainException) {
            // Expected outcome, not an application error.
            Yii::info($exception->errorCode() . ': ' . $exception->getMessage(), $exception::class);

            return;
        }

        parent::logException($exception);
    }

    protected function renderException($exception): void
    {
        $response = Yii::$app->has('response') ? Yii::$app->getResponse() : new Response();
        $response->isSent = false;
        $response->stream = null;
        $response->content = null;
        $response->format = Response::FORMAT_JSON;

        [$status, $error] = $this->toError($exception);

        $response->setStatusCode($status);
        $response->data = ['error' => $error];
        $response->send();
    }

    /**
     * @return array{0: int, 1: array<string, mixed>}
     */
    private function toError(Throwable $exception): array
    {
        if ($exception instanceof DomainException) {
            $error = ['code' => $exception->errorCode(), 'message' => $exception->getMessage()];
            if ($exception->details() !== []) {
                $error['details'] = $exception->details();
            }

            return [$this->statusOf($exception), $error];
        }

        if ($exception instanceof HttpException) {
            $status = $exception->statusCode;

            return [$status, ['code' => self::HTTP_CODES[$status] ?? 'http_error', 'message' => $exception->getMessage()]];
        }

        $error = ['code' => 'internal_error', 'message' => 'Internal server error.'];
        if (YII_DEBUG) {
            $error['details'] = [
                'type' => $exception::class,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile() . ':' . $exception->getLine(),
                'trace' => explode("\n", $exception->getTraceAsString()),
            ];
        }

        return [500, $error];
    }

    private function statusOf(DomainException $exception): int
    {
        return match (true) {
            $exception instanceof NotFoundException => 404,
            $exception instanceof ForbiddenException => 403,
            $exception instanceof ConflictException => 409,
            default => 422,
        };
    }
}
