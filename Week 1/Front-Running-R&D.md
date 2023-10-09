# Some solutions against front running:

_Commit-Reveal Schemes or Submarine Sends_: This approach involves two phases. In the first phase, users send a hashed version of their transaction (the "commit" phase). In the second phase, they reveal the actual transaction details (the "reveal" phase). By spacing these two phases out, it becomes difficult for adversaries to act on the information in the commit phase.

This prevents people from knowing if a big transaction is in the mempool.

_Priority Gas Auctions (PGA)_: Instead of users directly paying for gas, they send their desired gas payments to the protocol. The protocol then batches transactions and submits them together, with the transaction order determined by the protocol.

_Batching Transactions_: Transactions are grouped together and processed in batches, reducing the opportunity for front-runners to slip their transactions in between others.

_Time-Weighted Average Prices (TWAP)_: By referencing a time-weighted average price, which averages the price over a given time frame, traders are less able to manipulate the price through a single, large trade.

# Let's try a simple Commit-Reveal Scheme for our Bonding Curve exercise

How this solution would work is that:

1. User will "lock in" a price (amount of collateral/eth) for a desired amount of Curve Tokens. This is called a "commitment". Users will transfer collateral/tokens to contract first.
2. The "locked-in price" would be hashed
3. After a pre-determined number of blocks, we would "reveal" the "commitment"
4. "Revealing" would mean that the contract will distribute the intended tokens/collateral

This is for maximum user simplicity -> Locking in collateral. then reveal to buy.
We will lock Collateral and Tokens
