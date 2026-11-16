import { describe, expect, it } from 'vitest';

import { formatMoney, toMinorUnits } from './money';

describe('toMinorUnits', () => {
  it.each([
    ['1500', 150000],
    ['1500.5', 150050],
    ['0.07', 7],
    [' 1 000,25 ', 100025],
  ])('parses %s', (input, expected) => {
    expect(toMinorUnits(input)).toBe(expected);
  });

  it.each(['', 'abc', '-5', '1.234', '1e3'])('rejects %s', (input) => {
    expect(toMinorUnits(input)).toBeNull();
  });

  it('has no floating point drift', () => {
    expect(toMinorUnits('0.29')).toBe(29);
    expect(toMinorUnits('1.15')).toBe(115);
  });
});

describe('formatMoney', () => {
  it('formats minor units in the given currency', () => {
    expect(formatMoney(150050, 'USD', { locale: 'en-US' })).toBe('$1,500.50');
  });
});
