/// Module: escrow_dst
module contracts::escrow_dst;

use contracts::base_escrow::CrossChainSwap;
use contracts::immutables::{Self, Immutables};
use contracts::timelocks;
use sui::clock::Clock;
use sui::coin::Coin;
use sui::sui::SUI;

public entry fun new<CoinType: drop>(
    order_hash: vector<u8>,
    maker: address,
    taker: address,
    amount: u64,
    hash_lock: vector<u8>,
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    timelocks: u256,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    immutables::new(
        taker,
        order_hash,
        maker,
        amount,
        hash_lock,
        coin,
        safety_deposit,
        timelocks,
        clock,
        ctx,
    );
}

public entry fun withdraw<CoinType: drop>(
    secret: vector<u8>,
    immutables: &mut Immutables<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    immutables.check_taker(ctx);

    let taker = immutables.taker();
    let tl = *immutables.get_timelock();

    timelocks::only_after(tl.dst_withdrawal(), clock);
    timelocks::only_before(tl.dst_cancellation(), clock);

    immutables.withdraw_to(secret, taker, ctx);
}

public entry fun public_withdraw<CoinType: drop, AccessToken: drop>(
    secret: vector<u8>,
    immutables: &mut Immutables<CoinType>,
    config: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config.only_access_token_holder(coin);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.dst_public_withdrawal(), clock);
    timelocks::only_before(tl.dst_cancellation(), clock);

    immutables.withdraw_to(secret, ctx.sender(), ctx);
}

public entry fun cancel<CoinType: drop>(
    immutables: &mut Immutables<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.dst_cancellation(), clock);

    immutables.cancel(ctx);
}
