export class AetherVaultCalculator {
  public static convertToShares(assets: bigint, totalAssets: bigint, totalSupply: bigint): bigint {
    if (totalSupply === 0n || totalAssets === 0n) {
      return assets;
    }
    return (assets * totalSupply) / totalAssets;
  }

  public static convertToAssets(shares: bigint, totalAssets: bigint, totalSupply: bigint): bigint {
    if (totalSupply === 0n) {
      return shares;
    }
    return (shares * totalAssets) / totalSupply;
  }

  public static calculateYieldAccrued(
    initialDeposit: bigint,
    currentShares: bigint,
    totalAssets: bigint,
    totalSupply: bigint
  ): bigint {
    const currentValue = this.convertToAssets(currentShares, totalAssets, totalSupply);
    return currentValue > initialDeposit ? currentValue - initialDeposit : 0n;
  }
}
