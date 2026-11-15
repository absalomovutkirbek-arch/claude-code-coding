<?php

declare(strict_types=1);

namespace app\core\http;

use app\core\data\Page;
use app\core\exceptions\ValidationException;
use Yii;
use yii\base\Action;
use yii\base\Model;

/**
 * Base class of every API action.
 *
 * An action only routes: validate input -> call one service method -> return a resource.
 */
abstract class ApiAction extends Action
{
    /**
     * Fills the form from the request body and validates it.
     *
     * @template T of Model
     * @param T $form
     * @return T
     * @throws ValidationException
     */
    protected function validateBody(Model $form): Model
    {
        return $this->validateForm($form, (array) Yii::$app->request->getBodyParams());
    }

    /**
     * Fills the form from the query string and validates it.
     *
     * @template T of Model
     * @param T $form
     * @return T
     * @throws ValidationException
     */
    protected function validateQuery(Model $form): Model
    {
        return $this->validateForm($form, Yii::$app->request->getQueryParams());
    }

    /**
     * ID of the authenticated user.
     */
    protected function actorId(): int
    {
        return (int) Yii::$app->user->getId();
    }

    /**
     * @param array<string, mixed> $meta
     * @return array{data: mixed, meta: array<string, mixed>}
     */
    protected function ok(mixed $data, array $meta = []): array
    {
        return ['data' => $data, 'meta' => (object) $meta];
    }

    /**
     * @return array{data: mixed, meta: array<string, mixed>}
     */
    protected function created(mixed $data): array
    {
        Yii::$app->response->setStatusCode(201);

        return $this->ok($data);
    }

    /**
     * @param callable(list<mixed>): array<int, mixed> $toCollection Resource::collection(...)
     * @return array{data: mixed, meta: array<string, mixed>}
     */
    protected function paginated(Page $page, callable $toCollection): array
    {
        return $this->ok($toCollection($page->items), [
            'page' => $page->page,
            'per_page' => $page->perPage,
            'total' => $page->total,
            'total_pages' => $page->totalPages(),
        ]);
    }

    protected function noContent(): void
    {
        Yii::$app->response->setStatusCode(204);
    }

    /**
     * @template T of Model
     * @param T $form
     * @param array<string, mixed> $data
     * @return T
     */
    private function validateForm(Model $form, array $data): Model
    {
        $form->load($data, '');

        if (!$form->validate()) {
            throw new ValidationException($form->getErrors());
        }

        return $form;
    }
}
