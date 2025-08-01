/// Module: resolver
module resolver::resolver;

use contracts::escrow_dst;
use contracts::escrow_src;
use contracts::immutables::ImmutablesParams;
use lop::order_mixin::Order;
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

// resolver cap is commented to allow anyone to test
public fun deploy_src<CoinType: drop>(
    immutables: ImmutablesParams,
    order: Order,
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    _signature: vector<u8>,
    // _cap: &ResolverCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // todo: fix this
    let _amount = coin.value() as u256;

    // deploy new source escrow - should give a hot potato
    let wrap = escrow_src::balance_wrap(safety_deposit, immutables);

    // lop fills the taker address - so hardcoding here
    let taker = 10;
    let extra_data = 1;
    let making_amount = order.making_amount();
    let taking_amount = order.taking_amount();

    escrow_src::post_interaction(
        order,
        taker,
        making_amount,
        taking_amount,
        extra_data,
        coin,
        wrap,
        clock,
        ctx,
    );
}

public fun deploy_dst(
    params: ImmutablesParams,
    _src_cancellation_ts: u256,
    safety_deposit: Coin<SUI>,
    // _cap: &ResolverCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let coin: Coin<SUI> = coin::zero(ctx);
    escrow_dst::new(params, coin, safety_deposit, clock, ctx);
}
