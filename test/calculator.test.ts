import { describe, it, expect } from 'vitest';
import { AetherVaultCalculator } from '../src/calculator.js';

describe('AetherVaultCalculator', () => {
  it('handles 1:1 initial deposit when supply is 0', () => {
    const assets = 1_000_000n;
    const shares = AetherVaultCalculator.convertToShares(assets, 0n, 0n);
    expect(shares).toBe(assets);
  });

  it('accrues value per share when vault generates yield', () => {
    // Initial: 1000 assets, 1000 shares
    // Strategy generates 200 assets profit -> totalAssets = 1200
    const userShares = 500n;
    const assetsValue = AetherVaultCalculator.convertToAssets(userShares, 1200n, 1000n);
    expect(assetsValue).toBe(600n);

    const yieldAccrued = AetherVaultCalculator.calculateYieldAccrued(500n, userShares, 1200n, 1000n);
    expect(yieldAccrued).toBe(100n);
  });
});
