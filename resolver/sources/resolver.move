/// Module: resolver
module resolver::resolver;

use contracts::escrow_dst;
use contracts::escrow_src;
use contracts::immutables::ImmutablesParams;
use lop::order_mixin::{Self, Order};
use lop::taker_traits;
use sui::clock::Clock;
use sui::coin::{Self, Coin};
use sui::sui::SUI;

public struct ResolverCap has key {
    id: UID,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(
        ResolverCap {
            id: object::new(ctx),
        },
        ctx.sender(),
    )
}

public fun deploy_src<CoinType: drop>(
    immutables: ImmutablesParams,
    order: Order,
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    signature: vector<u8>,
    taker_traits: u256,
    args: vector<u8>,
    _cap: &ResolverCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // todo: fix this
    let amount = coin.value() as u256;

    // deploy new source escrow
    escrow_src::new(immutables, coin, safety_deposit, clock, ctx);

    // taker traits
    let taker_traits = taker_traits::new(taker_traits);
    order_mixin::fill_order_args(order, signature, amount, taker_traits, args, ctx);
}

public fun deploy_dst(
    params: ImmutablesParams,
    _src_cancellation_ts: u256,
    safety_deposit: Coin<SUI>,
    _cap: &ResolverCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let coin: Coin<SUI> = coin::zero(ctx);
    escrow_dst::new(params, coin, safety_deposit, clock, ctx);
}
