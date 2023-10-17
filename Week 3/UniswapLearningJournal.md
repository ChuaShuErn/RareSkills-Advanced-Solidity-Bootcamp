# Uniswap Journal

# x\*y=k

`X` and `Y` represent the quantities of two tokens in the `Liquidity Pool`. For easy visualization, lets imagine a Pool of Apples and Oranges.

`K`, also known as `The Invariant`, is the product of the quantities of the two tokens in the pool. This remains `constant` during a `trade`/`swap`.

The value of `K` can change when liquidity is added or removed.

**Price & Trade**:

The `x*y=k` formula ensures that as the quantity of Apples decreases due to a swap, the quantity of Oranges increases, ensuring that the product `k` is the same.

When depositing Apples to get Oranges, the quantity of Apples of the pool increases, making Apples more abundunt(cheaper). Oranges therefore becomes more scarce(expensive).

Solving for `Y` after adjusting `X` will give you the new quantity of Oranges/Apples after the swap.

Illustration:

Initial State: 10 apples \* 10 oranges = 100(k)

If someone wants to swap 5 apples for oranges, after adding 5 apples, we have:

New State : 15 apples \* y oranges = 100(k)

Solve for y = 100/15 = 6.66667

So the swapper received 10 - 6.6667 = 3.3333 oranges for their 5 apples.

# Low Liquidity Attacks

Also known as Rugpulls.

Due to the `X*Y=K` formula, the first few persons who makes a trade gets the most Apples for thier Oranges.

Assuming that a lot of marketing goes into Apples to create artificial demand, more and more people will trade in lots of Oranges for very few apples due to FOMO.

And when there is very few apples left, the first few persons then sells off all their Apples to get LOTS of Oranges, driving the price of apples down drastically.

# Accounting

##### How are balances and liquidity provision tracked within the protocol?

**Liqudity Tokens**

Liqudity is supplied by the Liquidity Provider who supplies BOTH tokens.

**Why both tokens?**

**Answer: Balanced Liquidity.**

To maintain the `X*Y=K`. In order to keep `k` intact, both tokens need to be provided at a certain ratio. If only one token was deposited, it would break the mechanism.

Here's a simple analogy: Imagine a traditional exchange where only sellers show up, and there are no buyers. The market wouldn't function. In the context of Uniswap, by depositing both tokens, liquidity providers are effectively ensuring that there are always both "buyers" and "sellers" available in the pool.

Balances

Accumulated Fees

Price Calculation and K-value Maintenance
