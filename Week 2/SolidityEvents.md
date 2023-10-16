# Events in Solidity

Here are the Ethereum client options:

- events

- events.allEvents

- getPastEvents

Each of these require specifying the smart contract address the querier wishes to examine, and returns a subset (or all) of the events a smart contract emitted according to the query parameters specified.

To summarize: Ethereum does not provide a mechanism to get all transactions for a smart contract, but it does provide a mechanism for getting all events from a smart contract.

# How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable?

It is generally best practice for events is to log them whenever a consequential state change happens.

Examples would be:

- Changing the owner of the contract
- Moving ether
- Conducting a trade

When a trade occurs, an event is emitted:

```sol
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
```

Platforms like OpenSea set up filters to monitor the logs of known NFT contracts. By filtering for Transfer events where the to address matches a given user's address, they can build a list of all NFTs transferred to that user. By further monitoring for Transfer events where the from address is the user's address, they can keep the list updated when the user transfers away an NFT.

# Explain how you would accomplish this if you were creating an NFT marketplace

1. Listening to Tranfer events.

2. Caching/Datbase Indexing. Whenever we connect with our wallet, we provide our public key. Had we cached the public key as an identifer for important information in Our NFT Marketplace cache, we can retrieve important information off-chain.
