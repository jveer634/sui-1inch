# Limit Order Protocol

This package is made to mimic the `OrderMixin` defined in the original 1inch EVM contracts. This package is designed just to define the types and the placeholder functions that are integrated in the EVM contract and it doesn't any logic

This package contracts 4 modules

-   [maker_traits](./sources/maker_traits.move) - contains the `MakerTraits` which is wrapper around a u256 to provide the maker flags provided by the 1inch contracts
-   [taker_traits](./sources/taker_traits.move) - contains the `TakerTraits` which is wrapper around a u256 to provide the taker flags provided by the 1inch contracts
-   [order_mixin](./sources/order_mixin.move) - contains the `Order` object which contains the details of the matched order.
-   [lop](./sources/lop.move) - contains the placeholder functions that is used to mimic the original lop of the 1inch contracts
