# Contracts - Escrow Package

This package holds the escrow framework used by the cross-chain-swap in the 1inch protocol.

## List of contracts

1. [base_escrow](./sources/base_escrow.move) - A configuration package which is used to define the common properties such as `AccessToken` and `rescue_dekay`,
2. [escrow_dst](./sources/escrow_dst.move) - A destination escrow module that will be used to deploy the `EscrowDst` object which is the clone of the EscrowDst on the original contracts.
3. [escrow_src](./sources/escrow_src.move) - A destination escrow module that will be used to deploy the `EscrowSrc` object which is the clone of the EscrowSrc contract on the original contracts.
4. [timelocks](./sources/timelocks.move) - Timelocks is a special object used by the 1inch to store different timestamps of the order in a single uint256 variables.
5. [immuttables](./sources/lib/immutables.move) - Immutables module contains the immutable struct used by the 1inch which hosts the maker, taker, amount and other immutable data for the swap.
6. [bytes32](./sources/lib/bytes32.move) - A custom type on the bytes vector to emulate the bytes 32 type. Since sui only have u8 vector and not bytes32

## Deploy

To deploy and setup the contracts, once the package is published, the deployer must call the [setup](./sources/base_escrow.move#L41) function to set the access token and the rescue delay period.

### Escrow Src

The deployment of escrow follows a `Hot Potato` pattern of sui contracts. Which in simple terms means that an action is split into 2 functions and upon calling the first function we will receive an object which doesn't support drop and key features and which makes user to call the second function to destory the potato object return by the first function or else the transaction won't be executed. And user can't call the second function without having the potato object from the first function.

This pattern ensures that the user has definetly call both the functions and also in order.

To deploy the Escrow source, the resolver must first call the `balance_wrap` function with the safety deposit amount which will return the `BalanceWrap` hot potato type object to them which then will be consumed by the `postInteraction` function.

The reason behind this design choice is to mimic the `CREATE2` pattern followed in the original contracts.
