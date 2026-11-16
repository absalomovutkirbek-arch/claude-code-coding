/** User-facing text for the error codes of the billing API. */
export const transferErrorMessages: Record<string, string> = {
  insufficient_balance: 'There is not enough money in the source wallet.',
  currency_mismatch: 'Both wallets must be in the same currency.',
  forbidden: 'You can transfer only from your own wallet.',
  not_found: 'One of the wallets was not found.',
};
