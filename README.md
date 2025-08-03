# Sui <-> 1inch

The novice implementation of the Cross chain swap escrow framework to the sui blockchain network.

### What does the project contains ?

1. [contracts](./contracts/README.md) - the escrow framework of the protocol
2. [resolver](./resolver/READNE.md) - a sample resolver implementation
3. [lop](./lop/README.md) - a sample package which is supposed to hold the lop of the 1inch.

### How are they different from EVM ?

I have tried to mimic the entire architecture followed by the Cross-chain-swap contracts on the EVM as much as possible apart from the datatypes which I implemented according to the sui standard such as timelock is a wrapper around u256 rather than a direct u256 (as in solidiy) and also the timestamp on sui works on milliseconds with I divided with 1000 right when we are comparing so to keep the timelocks functionality same as Solidity contracts.

The major architectural change would be when the relayer is trying to deploy the Src Escrow because by nature Sui network doesn't allow pull architecture like ERC20 (approve and transferFrom). So, The change I had to do is make the user and resolver both sign the deployEscrow transaction and make the resolver pay for the transaction (Multisig are by default supported by the Sui network)

### Are they working ?

Right now, the contracts are only able to support the Sui chain swaps only and that is because the EVM doesn't support sui address and sui contracts can't hold EVM address. Even though I declare the EVM addresses as bytes on the Sui and somehow manage to fit the Sui address on solidity. the problem rises when
Scenario 1 - maker Sui address
On solidity - deploy Escrow

1. Can't verify signature
2. During cancel, transfer ERC20 to maker fails
   Scenario 2 - Maker EVM address - on success DSTASSEtT to maker - withdraw
3. Can't withdraw funds since transferring funds to maker (modified sui) address is not possible.

The cross - chain is only possible when
Immutables contains

1. maker src address
2. maker dst address
3. taker src address
4. taker src address

With that, we will have 2 address on both the ends to transfer assets seamlessly .
