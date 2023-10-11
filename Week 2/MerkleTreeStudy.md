# My Findings and questions about the Merkle Tree

The airdrop deployer would have collected a predetermined list of addresses eligble for the airdrop.

1. He compiles the list of `addresses`, `index(?)` and `amount`
2. He sorts them, typically by `addresses`. The `openzeppelin` hash comparison method assumes that its been sorted
3. Hash each entry. Each of them will be considered a `hashed leaf`.
4. From your pre-sorted Hashed leaves, build the merkle tree, until we reach a single hash at the top, called the `merkle root`.
5. For each `hashed leaf`, we can generate a `merkle proof` (using the index or address (?))
6. Store the merkle root at the Smart Contract Header.

Outside the smart contract:

1. We have built the tree
2. Calculated a `merkle proof` for each address.

# Airdrop Understanding

In this exercise example, we will assume that those who are elgible for the airdop are given their `merkle proof` in advance by email.

And in order to claim their airdrop, they must provide that `merkle proof` and "registered" `address`.

An analogy I would use is that the `merkle proof` is a concert ticket, and your "registered" `address` is your ID Card. You need both
to attend the concert.

# BitMaps

Purpose:

We use Bitmaps to find out if a person has already claimed their airdrop

Rationale:
Storage Efficiency
