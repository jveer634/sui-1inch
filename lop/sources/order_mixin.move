#[allow(unused_field)]
/// Module: OrderMixin

module lop::order_mixin;

use lop::maker_traits::MakerTraits;
use lop::taker_traits::TakerTraits;

public struct Order has drop {
    salt: u256,
    maker: address,
    receiver: address,
    maker_asset: address,
    taker_asset: address,
    making_amount: u256,
    taking_amount: u256,
    maker_traits: MakerTraits,
}

// events
public struct OrderFilled has copy, drop, store {
    order_hash: vector<u8>,
    remaining_amount: u256,
}

public struct OrderCancelled has copy, drop, store {
    order_hash: vector<u8>,
}

public fun fill_order_args(
    _order: Order,
    _signature: vector<u8>,
    _amount: u256,
    _taker_traits: TakerTraits,
    _args: vector<u8>,
    _ctx: &mut TxContext,
) {}

public fun order_hash(_self: &Order): vector<u8> {
    vector::empty()
}

public fun maker(self: &Order): address {
    self.maker
}

public fun receiver(self: &Order): address {
    self.receiver
}

public fun taking_amount(self: &Order): u256 {
    self.taking_amount
}

public fun making_amount(self: &Order): u256 {
    self.making_amount
}
