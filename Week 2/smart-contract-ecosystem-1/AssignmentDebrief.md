# Smart Contract Ecosystem 1

We are trying to simulate a `Digital Art Economy`.

Imagine an artist who wants to monetize and incentivize engagement with their digital artwork.

# Mission Debrief

The artist releases digital art pieces as NFTs. These are limited edition, with only 20 available.
Regular fans can purchase these digital art pieces at standard prices.

Early supporters, patrons, or those who attended a virtual art event (whose addresses the artist collected) are part of a special group. Using the Merkle tree setup, these individuals can acquire the NFTs at a discounted rate. This rewards loyalty and early support.

Every time an NFT changes hands in the future (e.g., resold in a secondary market), the artist gets a 2.5% royalty, ensuring they benefit from the increasing value of their work.

_ERC20 as Gallery Tokens_:

Alongside the NFTs, the artist introduces a token system. These ERC20 tokens, called _Gallery Tokens_ can be used for _Staking_ in the _Musket Staking Platform_

_Staking for Engagement and Rewards_

Staking your NFTs, rewards stakers with Gallery Tokens

Users can withdraw 10 Gallery Tokens every 24 hours

Users can withdraw/unstake their NFT at any time

Musket Staking Platform must take possession of NFT, and only the user should be able to withdraw it

Musket Staking platform must follow Stake NFTs with safeTransfer from video

Make the funds from the NFT sale in the contract withdrawable by the owner, using Ownable2Step.
