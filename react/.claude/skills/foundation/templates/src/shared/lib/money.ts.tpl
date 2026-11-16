/**
 * Money travels and is stored as an integer in minor units (tiyin, cents). Never as a float.
 */

const DEFAULT_FRACTION_DIGITS = 2;

/**
 * Parses user input such as "1500" or "1500.5" into minor units without floating point maths.
 *
 * @returns `null` when the input is not a valid non-negative amount.
 */
export function toMinorUnits(input: string, fractionDigits = DEFAULT_FRACTION_DIGITS): number | null {
  const normalized = input.trim().replace(/\s/g, '').replace(',', '.');
  const match = new RegExp(`^(\\d+)(?:\\.(\\d{1,${fractionDigits}}))?$`).exec(normalized);
  if (match === null) {
    return null;
  }

  const whole = match[1];
  const fraction = (match[2] ?? '').padEnd(fractionDigits, '0');
  const minor = Number(whole + fraction);

  return Number.isSafeInteger(minor) ? minor : null;
}

export function formatMoney(
  minorUnits: number,
  currency: string,
  { locale, fractionDigits = DEFAULT_FRACTION_DIGITS }: { locale?: string; fractionDigits?: number } = {},
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(minorUnits / 10 ** fractionDigits);
}
