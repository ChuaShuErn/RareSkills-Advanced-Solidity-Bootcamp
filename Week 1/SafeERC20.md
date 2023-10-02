
# SafeERC20 - Why should we use it

### Not returning boolean
For tokens that follow the ERC20 standard,  executing `transfer` and `transferFrom` returns a boolean value.

`true` if success,`false` if a failure, and `revert`.

However, tokens like USDT (Tether) does not return any value.

SafeERC20 offers `safeTransfer` and `safeTransferFrom` as wrapper functions to the original ERC20 `transfer` and `transferFrom`

The `_callOptionalReturn` and `_callOptionalReturnBool` can be used depending on the developer outcome.

1. `_callOptionalReturn` -> Reverts if returned data was `false`
2. `_callOptionalReturnBool` -> returns false if transaction failed. To be used if developer wants the transaction to gracefully handle that failure.


### Double-spend allowance

Excerpt from medium article [here](https://medium.com/@deliriusz/ten-issues-with-erc20s-that-can-ruin-you-smart-contract-6c06c44948e0) 

If you think about setting an allowance for your tokens to a different address, you probably don’t see double spending vulnerability coming, but the issue may be really serious. Let’s go with an example describing possible attack vector:

Alice sets Bob’s allowance to 1000 of her tokens, but sends 1100 by mistake

Alice realizes her mistake, and sends another transaction with correct amount (1000 tokens)

Malicious Bob watched the mempool for new transactions, frontruns the second allowance and transfers to himself 1100 tokens Alice sent at first. So, he made it with 2100 tokens, and not 1000 as planned.

