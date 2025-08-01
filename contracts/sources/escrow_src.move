/// Module: escrow_src
module contracts::escrow_src;

use contracts::base_escrow::CrossChainSwap;
use contracts::immutables::{Self, Immutables, ImmutablesParams};
use contracts::timelocks;
use lop::order_mixin::Order;
use sui::address;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::event;
use sui::sui::SUI;

public struct EscrowSrc<phantom CoinType: drop> has key, store {
    id: UID,
    deposit: Balance<SUI>,
    amount: Balance<CoinType>,
    immutables: Immutables,
}

public struct BalanceWrap has store {
    balance: Balance<SUI>,
    params: ImmutablesParams,
}

public struct DstImmutablesComplement has copy, drop, store {
    maker: address,
    amount: u256,
    token: u256,
    safety_deposit: u256,
    chain_id: u256,
}

// events
public struct SrcEscrowCreated has copy, drop, store {
    immutables: ImmutablesParams,
    dstImmutables: DstImmutablesComplement,
}

public fun balance_wrap(deposit: Coin<SUI>, params: ImmutablesParams): BalanceWrap {
    BalanceWrap {
        balance: deposit.into_balance(),
        params,
    }
}

public fun post_interaction<CoinType: drop>(
    order: Order,
    taker: u256,
    making_amount: u256,
    taking_amount: u256,
    extra_data: u256, // dstTokenAddress is stored in this
    coin: Coin<CoinType>,
    balance_wrap: BalanceWrap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // params.amount = amount or revert
    let BalanceWrap { balance, params } = balance_wrap;
    let immutables = immutables::new(
        params,
        clock,
        ctx,
    );
    let hash_lock = immutables.hash_lock();
    let timelocks = immutables.timelocks();

    transfer::share_object(EscrowSrc {
        id: object::new(ctx),
        immutables,
        amount: coin.into_balance(),
        deposit: balance,
    });

    let order_hash = order.order_hash();
    let maker = address::to_u256(order.maker());

    let params_copy = immutables::params_new(
        order_hash,
        hash_lock,
        10,
        maker,
        taker,
        making_amount,
        timelocks.value(),
    );
    event::emit(SrcEscrowCreated {
        immutables: params_copy,
        dstImmutables: DstImmutablesComplement {
            chain_id: 1,
            amount: taking_amount,
            maker: order.maker(),
            token: extra_data,
            safety_deposit: 10,
        },
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
