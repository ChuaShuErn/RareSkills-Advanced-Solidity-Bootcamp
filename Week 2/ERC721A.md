# ERC721A: Gas Optimization and Considerations

## How does ERC721A save gas?

_Packed Storage:_ ERC721A uses packed storage structures to save space. Instead of storing each property of a token in a separate storage slot, multiple properties are packed together into a single storage slot. This reduces the number of storage operations required, which in turn reduces gas usage.

_Example:_
In the provided code, the `\_packedOwnerships` array combines multiple pieces of information about the token, such as the owner's address, timestamps, and burned status. This reduces the amount of storage space and operations required compared to if each of these were stored separately.

_Use of Bitwise Operations:_ Bitwise operations are used extensively in ERC721A to manipulate packed data. Bitwise operations are computationally cheap and provide a method for efficiently accessing and modifying specific parts of packed data without affecting the rest.

_Example:_
When checking if a token is burned, instead of accessing a separate boolean value from storage, the implementation checks a specific bit in the packed data using the \_BITMASK_BURNED mask.

_Consecutive Minting with ERC2309:_ Instead of emitting individual Transfer events for each minted token, ERC721A uses the ConsecutiveTransfer event from ERC2309. This reduces the number of events emitted during bulk minting operations, thereby saving gas.

_Example:_
If you mint 100 tokens, instead of emitting 100 separate Transfer events, a single ConsecutiveTransfer event is emitted with a starting and ending token ID, indicating that all tokens between those two IDs were minted.

### Where does it add cost?

_Complexity:_ The added complexity in logic and bitwise operations might make some operations slightly more expensive in terms of gas. Each bitwise operation, while cheaper than storage operations, still consumes gas.

_Initialization Overhead:_ For certain operations, there's a need to check and potentially initialize adjacent slots (as observed in the \_burn function). This initialization, while ensuring correctness, adds some overhead.

_Safe Transfer Checks:_ The \_safeMint function checks if the recipient address is a smart contract and, if so, calls the onERC721Received function on it. This adds additional gas overhead, especially if done multiple times in a loop.

### Why shouldn’t ERC721A enumerable’s implementation be used on-chain?

_Storage Overhead:_ Keeping track of all token IDs for enumeration can be storage-intensive, especially as the total number of tokens grows.

_Gas Costs on Transfers:_ If tokens are stored in an array, transferring a token might require reordering the array, leading to increased gas costs.

_Implementation Complexity:_ Implementing enumeration can add complexity to the smart contract, making it harder to audit and increasing the potential for bugs.

_Scaling Concerns:_ As the number of tokens grows, operations that involve looping through all tokens (like checking balances of all holders) can become prohibitively expensive in terms of gas.
