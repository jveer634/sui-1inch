/// Module: escrow_dst
module contracts::escrow_dst;

use contracts::base_escrow::CrossChainSwap;
use contracts::immutables::{Self, Immutables, ImmutablesParams};
use contracts::timelocks;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::sui::SUI;

public struct EscrowDst<phantom CoinType: drop> has key, store {
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

    transfer::share_object(EscrowDst {
        id: object::new(ctx),
        immutables,
        amount: coin.into_balance(),
        deposit: safety_deposit.into_balance(),
    })
}

#[allow(lint(self_transfer))]
fun withdraw_internal<CoinType: drop>(
    self: &mut EscrowDst<CoinType>,
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

public entry fun withdraw<CoinType: drop>(
    self: &mut EscrowDst<CoinType>,
    secret: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let taker = immutables.taker();
    let tl = *immutables.get_timelock();

    timelocks::only_after(tl.dst_withdrawal(), clock);
    timelocks::only_before(tl.dst_cancellation(), clock);

    self.withdraw_internal(secret, taker, ctx);
}

public entry fun public_withdraw<CoinType: drop, AccessToken: drop>(
    self: &mut EscrowDst<CoinType>,
    secret: vector<u8>,
    config: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    config.only_access_token_holder(coin);

    let immutables = &self.immutables;
    let tl = *immutables.get_timelock();

    timelocks::only_after(tl.dst_public_withdrawal(), clock);
    timelocks::only_before(tl.dst_cancellation(), clock);

    self.withdraw_internal(secret, ctx.sender(), ctx);
}

public entry fun cancel<CoinType: drop>(
    self: &mut EscrowDst<CoinType>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let immutables = &self.immutables;
    immutables.check_taker(ctx);

    let tl = *immutables.get_timelock();
    timelocks::only_after(tl.dst_cancellation(), clock);

    // coin to maker
    let coin = balance::withdraw_all(&mut self.amount).into_coin(ctx);
    transfer::public_transfer(
        coin,
        immutables.taker(),
    );
}
