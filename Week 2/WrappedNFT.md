# Openzeppelin Wrapped NFT

The Wrapped NFT (Non-Fungible Token) pattern is a design pattern in Ethereum smart contracts where one NFT (the underlying NFT) is "wrapped" or "encased" within another NFT (the wrapped NFT). This is accomplished by sending the original NFT to a smart contract, which then mints a new NFT to represent the original. The original NFT can be retrieved by "unwrapping" the new one, i.e., sending it back to the smart contract to burn it and get the original NFT back.

This pattern is useful for a number of reasons:

Upgrading Existing NFTs: If there's an existing NFT with specific properties or features that you'd like to augment without modifying the original contract, you can wrap it and add new features to the wrapper.

Interoperability: Some platforms or contracts might only accept a specific kind of NFT. Wrapping allows an NFT to be transformed into a form acceptable to these platforms.

Combining Features: Like in the provided code, the pattern can be combined with other features or extensions (like voting). By wrapping a basic NFT, you can essentially turn it into a governance token.

Layering Utilities: Sometimes, you might want to add utility to an NFT like lending, staking, or other DeFi primitives. Wrapping can help layer these utilities onto an existing NFT.

Here's a simple example based on the given code:

Depositing (Wrapping):
Suppose you have an ERC721 token with token ID 5. You can deposit this token into the ERC721Wrapper contract and get a wrapped version of it.

```sol
originalToken.approve(wrapperContractAddress, 5);
wrapperContract.depositFor(msg.sender, [5]);
```

Withdrawing (Unwrapping):
If you want to get your original token back, you can send the wrapped token back to the contract and retrieve the original.

```sol
wrapperContract.withdrawTo(msg.sender, [5]);
```

Recovering Mistakenly Sent NFTs:
If someone mistakenly sends an NFT to the wrapper contract without using the depositFor function, the \_recover function can be used to mint a wrapped token for that underlying NFT.

```sol
// Suppose tokenId 10 was mistakenly sent.
wrapperContract.\_recover(msg.sender, 10);
```

# Uses of Wrapped NFTs:

Governance: As mentioned, you can transform a basic NFT into a governance token. This means that owners of the wrapped NFT might be able to propose or vote on certain decisions in a system.

Marketplaces & Platforms: Some platforms might want to standardize the type of NFTs they accept, for easier management and integration. Users can wrap their diverse NFTs into a standard form that's recognized by the platform.

Liquidity & DeFi: Wrapped NFTs can be used in DeFi protocols, allowing for things like fractional ownership, staking, or liquidity provision based on the NFT's value.

Metadata and Trait Enhancements: Maybe the wrapped NFT carries additional metadata, animations, or other digital enhancements that the original doesn't.

Cross-Chain and Layer 2 Movements: Wrapped patterns can also facilitate the movement of NFTs across chains or onto Layer 2 solutions.

The value and trust in the wrapped NFT come from the assurance that you can always redeem it for the original. The wrapping contract must be secure and properly audited to ensure users can safely get their original NFTs back.
