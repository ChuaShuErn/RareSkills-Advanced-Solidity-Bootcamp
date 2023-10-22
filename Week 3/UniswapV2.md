# Uniswap

x\*y = k:

Definition: This is the fundamental invariant of Uniswap V2 (and V1). For a given liquidity pool with token X and token Y, the product of their quantities (x for X and y for Y) always equals a constant value, k.

Value `k` can change when liquidity is added or removed but remains constant during swaps.

Implication: When you swap tokens, this invariant ensures that as the supply of one token decreases in the pool, the other increases, such that k remains constant. This also implicitly sets the price for a token in terms of the other.

For easy visualization, let's imagine a Liquidity Pool of apples and oranges

Initial State: 10 apples \* 10 oranges = 100(k)

If someone wants to swap 5 apples for oranges, after adding 5 apples, we have:

New State : 15 apples \* y oranges = 100(k)

Solve for y = 100/15 = 6.66667

So the swapper received 10 - 6.6667 = 3.3333 oranges for their 5 apples.

2. Inflation Attack / Low Liquidity Attack:
   Definition: In an inflation attack, a malicious actor inflates the supply of their own token and then uses it to drain legitimate assets from a liquidity pool.

Scenario: Consider a malicious token where the attacker can mint unlimited amounts. If a pool is created with this token, the attacker can inflate its supply, trade it for the other legitimate token in the pool, and drain the pool of the legitimate token.

Example:
Let's imagine a pool with FAKE/ETH. An attacker mints a large amount of FAKE tokens and then swaps them for ETH in the pool. Given the x\*y = k formula, the pool will try to maintain the invariant, allowing the attacker to extract significant ETH for almost worthless FAKE tokens.

3. Accounting:
   Uniswap V2 uses a unique way to keep track of liquidity. Rather than accounting for individual contributions, liquidity providers receive LP (liquidity provider) tokens. The LP token acts as a claim on the pool's assets.

Example:

```sol
function addLiquidity(uint daiAmount, uint ethAmount) public {
uint liquidityMinted = ...; // Calculate LP tokens to mint based on the amounts
dai.transferFrom(msg.sender, address(this), daiAmount);
weth.transferFrom(msg.sender, address(this), ethAmount);
lpToken.mint(msg.sender, liquidityMinted);
}
```

4. Uniswap’s Architecture:
   Uniswap V2's architecture can be broken down into several key components:

Factory Contract: This contract is responsible for creating individual pair contracts for each token pair. Each time a new pair is needed, the factory spawns a new one.
Pair Contracts: Each pair contract holds the reserves of the two tokens and implements the core swapping and liquidity provision logic.
Router Contract: Facilitates more complex operations like adding/removing liquidity, swapping tokens, and ensuring interactions are smooth. It often interacts with multiple pair contracts to complete a user's request.
LP Tokens: When liquidity is provided to a pair, the provider receives LP tokens in proportion to their share of the pool. These tokens can later be redeemed to retrieve the underlying liquidity.
Price Oracles: Uniswap V2 introduced on-chain price oracles that leverage the x\*y = k invariant to provide cumulative price data, which can be used to calculate a TWAP (time-weighted average price).
Example:

```sol
// Factory Contract
function createPair(address tokenA, address tokenB) external returns (address pair) {
require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
...
pair = address(new Pair());
...
}


// Pair Contract
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
...
(uint112 \_reserve0, uint112 \_reserve1, ...) = getReserves();
require(amount0Out < \_reserve0 && amount1Out < \_reserve1, "UniswapV2: INSUFFICIENT_LIQUIDITY");
...
}
```

These examples are oversimplified and only meant to provide a basic understanding. The actual Uniswap V2 code involves more checks, optimizations, and additional logic.

# Impermanent Loss

Impermanent loss is a decentralized finance (DeFi) phenomenon that occurs when an automated market maker’s (AMMs) algorithmically driven token rebalancing formula creates a divergence between the price of an asset within a liquidity pool and the price of that asset outside of the liquidity pool.
