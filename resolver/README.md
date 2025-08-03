# Resolver

A sample resolver contract that must be deployed by the relayers in order to interact with the Cross-chain-swap and lop protocol.

This package contains 2 modules

-   [resolver](./sources/resolver.move) - contains a sample resolver package.
-   [token](./sources/token.move) - contains a sample coin for the testing. This must be removed, if planning to deploy on production.

### NOTE

For the testing purpose, the onlyOwner access is removed, it can be implemented using the `ResolverCap` object which only the deploy will have and a `transfer_ownership` function must be implemented for that.
