/// Module: resolver
module resolver::resolver;

use contracts::escrow_dst;
use contracts::escrow_src;
use contracts::immutables::ImmutablesParams;
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
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    _cap: &ResolverCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // deploy new source escrow
    escrow_src::new(immutables, coin, safety_deposit, clock, ctx);

    // implement taker traits
    // implement order mixin
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
