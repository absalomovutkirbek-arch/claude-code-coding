<?php

declare(strict_types=1);

namespace app\core\http;

use yii\filters\auth\HttpBearerAuth;
use yii\filters\ContentNegotiator;
use yii\rest\Controller;
use yii\web\Response;

/**
 * Base controller of every API module.
 *
 * Child controllers contain no logic: they only map action IDs to Action classes
 * in actions() and declare allowed HTTP verbs in verbs().
 */
abstract class ApiController extends Controller
{
    /**
     * Action IDs that do not require authentication (login, public catalog, webhooks).
     *
     * @return string[]
     */
    protected function publicActions(): array
    {
        return [];
    }

    public function behaviors(): array
    {
        $behaviors = parent::behaviors();

        $behaviors['contentNegotiator'] = [
            'class' => ContentNegotiator::class,
            'formats' => ['application/json' => Response::FORMAT_JSON],
        ];
        $behaviors['authenticator'] = [
            'class' => HttpBearerAuth::class,
            'except' => $this->publicActions(),
        ];

        return $behaviors;
    }
}
