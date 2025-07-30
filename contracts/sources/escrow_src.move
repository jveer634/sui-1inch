/// Module: escrow_src
module contracts::escrow_src;

use contracts::base_escrow::CrossChainSwap;
use contracts::immutables::{Self, Immutables};
use contracts::timelocks;
use sui::clock::Clock;
use sui::coin::Coin;
use sui::sui::SUI;

public entry fun new<CoinType: drop>(
    maker: address,
    taker: address,
    order_hash: vector<u8>,
    amount: u64,
    hash_lock: vector<u8>,
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    timelock: u256,
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
        timelock,
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

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    immutables.withdraw_to(secret, ctx.sender(), ctx);
}

public entry fun withdraw_to<CoinType: drop>(
    secret: vector<u8>,
    target: address,
    immutables: &mut Immutables<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    immutables.withdraw_to(secret, target, ctx);
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
    timelocks::only_after(tl.src_public_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    immutables.withdraw_to(secret, ctx.sender(), ctx);
}

public entry fun cancel<CoinType: drop>(
    immutables: &mut Immutables<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_cancellation(), clock);

    immutables.cancel(ctx);
}

public entry fun public_cancel<CoinType: drop, AccessToken: drop>(
    immutables: &mut Immutables<CoinType>,
    config: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config.only_access_token_holder(coin);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_public_cancellation(), clock);

    immutables.cancel(ctx);
}
