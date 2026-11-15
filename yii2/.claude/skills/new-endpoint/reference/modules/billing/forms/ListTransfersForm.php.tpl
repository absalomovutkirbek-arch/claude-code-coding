<?php

declare(strict_types=1);

namespace app\modules\billing\forms;

use app\modules\billing\dto\TransferFilterDto;
use app\modules\billing\enums\TransferStatus;
use yii\base\Model;

/**
 * Query parameters of GET /v1/billing/transfers.
 */
final class ListTransfersForm extends Model
{
    /** @var string|null */
    public $status;
    /** @var int|string */
    public $page = 1;
    /** @var int|string */
    public $per_page = 20;

    public function rules(): array
    {
        return [
            ['status', 'in', 'range' => array_column(TransferStatus::cases(), 'value')],
            ['page', 'integer', 'min' => 1],
            ['per_page', 'integer', 'min' => 1, 'max' => 100],
        ];
    }

    public function toDto(int $actorId): TransferFilterDto
    {
        return new TransferFilterDto(
            initiatorId: $actorId,
            status: $this->status !== null ? TransferStatus::from($this->status) : null,
            page: (int) $this->page,
            perPage: (int) $this->per_page,
        );
    }
}
