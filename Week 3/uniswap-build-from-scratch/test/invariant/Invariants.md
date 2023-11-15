# Invariant

Invariants are conditions that must always be true under a certain set of well-defined assumptions. For example, in an ERC20 contract, an invariant would be that the sum of all balances in the contract should equal the total supply.

# What are the invariants in Uniswap?

1. Constant Product Formula must be true after swap, add/remove liquidity (excluding fees?)

`x * y = k.`

In simpler terms, K is represented as the last snapshot of the product reserves.

2. Pool Shares.

The proportion of liquidity tokens held by any one provider should always accurately represent their share of the pool's total reserve

3. Total Supply of Liquidity tokens must be sum of all balances in the contract. In this example, 0xdead holds the minimum liquidity.

4. Price determination (?)
5. Reserve Ratios(?)
