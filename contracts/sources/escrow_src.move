/// Module: escrow_src
module contracts::escrow_src;

use contracts::base_escrow::CrossChainSwap;
use contracts::immutables::{Self, Immutables, ImmutablesParams};
use contracts::timelocks;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::sui::SUI;

public struct EscrowSrc<phantom CoinType: drop> has key, store {
    id: UID,
    deposit: Balance<SUI>,
    amount: Balance<CoinType>,
    immutables: Immutables,
}

public fun new<CoinType: drop>(
    params: ImmutablesParams,
    coin: Coin<CoinType>,
    safety_deposit: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = immutables::new(
        params,
        clock,
        ctx,
    );

    transfer::share_object(EscrowSrc {
        id: object::new(ctx),
        immutables,
        amount: coin.into_balance(),
        deposit: safety_deposit.into_balance(),
    })
}

#[allow(lint(self_transfer))]
fun withdraw_internal<CoinType: drop>(
    self: &mut EscrowSrc<CoinType>,
    secret: vector<u8>,
    target: address,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_secret(secret);

    // safety deposit to caller
    let coin = balance::withdraw_all(&mut self.deposit).into_coin(ctx);
    transfer::public_transfer(
        coin,
        ctx.sender(),
    );

    // coin to target
    let coin = balance::withdraw_all(&mut self.amount).into_coin(ctx);
    transfer::public_transfer(
        coin,
        target,
    );
}

// todo: verify logic once
#[allow(lint(self_transfer))]
fun cancel_internal<CoinType: drop>(self: &mut EscrowSrc<CoinType>, ctx: &mut TxContext) {
    let immutables = &self.immutables;
    // safety deposit to caller
    let coin = balance::withdraw_all(&mut self.deposit).into_coin(ctx);
    transfer::public_transfer(
        coin,
        ctx.sender(),
    );

    // coin to maker
    let coin = balance::withdraw_all(&mut self.amount).into_coin(ctx);
    transfer::public_transfer(
        coin,
        immutables.maker(),
    );
}

public fun withdraw<CoinType: drop>(
    self: &mut EscrowSrc<CoinType>,
    secret: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    self.withdraw_internal(secret, ctx.sender(), ctx);
}

public entry fun withdraw_to<CoinType: drop>(
    self: &mut EscrowSrc<CoinType>,
    secret: vector<u8>,
    target: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    self.withdraw_internal(secret, target, ctx);
}

public entry fun public_withdraw<CoinType: drop, AccessToken: drop>(
    self: &mut EscrowSrc<CoinType>,
    secret: vector<u8>,
    config: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config.only_access_token_holder(coin);

    let immutables = &self.immutables;
    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_public_withdrawal(), clock);
    timelocks::only_before(tl.src_cancellation(), clock);

    self.withdraw_internal(secret, ctx.sender(), ctx);
}

public entry fun cancel<CoinType: drop>(
    self: &mut EscrowSrc<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_cancellation(), clock);

    self.cancel_internal(ctx);
}

public entry fun public_cancel<CoinType: drop, AccessToken: drop>(
    self: &mut EscrowSrc<CoinType>,
    config: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config.only_access_token_holder(coin);
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.src_public_cancellation(), clock);

    self.cancel_internal(ctx);
}
