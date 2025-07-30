/// Module: immutables
module contracts::immutables;

use contracts::bytes32::{Self, Bytes32};
use contracts::timelocks::{Self, TimeLocks};
use sui::balance::Balance;
use sui::bcs;
use sui::clock::Clock;
use sui::coin::{Self, Coin};
use sui::hash;
use sui::sui::SUI;

public struct Immutables<phantom T: drop> has key, store {
    id: UID,
    order_hash: Bytes32,
    taker: address,
    maker: address,
    amount: u64,
    safety_deposit: Balance<SUI>,
    balance: Balance<T>,
    hash_lock: Bytes32,
    timelocks: TimeLocks,
}

// errors
const EInvalidCaller: u64 = 0;
const EInvalidSecret: u64 = 1;

public(package) fun hash<CoinType: drop>(self: &Immutables<CoinType>): vector<u8> {
    let bytes = bcs::to_bytes(self);
    hash::keccak256(&bytes)
}

public(package) fun new<CoinType: drop>(
    taker: address,
    order_hash: vector<u8>,
    maker: address,
    amount: u64,
    hash_lock: vector<u8>,
    coin: Coin<CoinType>,
    safety_deposit: Coin<SUI>,
    timelocks: u256,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    transfer::share_object(Immutables<CoinType> {
        id: object::new(ctx),
        order_hash: bytes32::to_bytes32(order_hash),
        maker,
        taker,
        amount,
        safety_deposit: safety_deposit.into_balance(),
        balance: coin.into_balance(),
        hash_lock: bytes32::to_bytes32(hash_lock),
        timelocks: timelocks::set_deployed_at(timelocks, clock.timestamp_ms() / 1000),
    })
}

public(package) fun check_taker<CoinType: drop>(self: &Immutables<CoinType>, ctx: &TxContext) {
    assert!(self.taker == ctx.sender(), EInvalidCaller);
}

public(package) fun check_secret<CoinType: drop>(self: &Immutables<CoinType>, secret: vector<u8>) {
    let secret = bytes32::to_bytes32(secret);
    assert!(self.hash_lock == secret, EInvalidSecret);
}

#[allow(lint(self_transfer))]
public(package) fun withdraw_to<CoinType: drop>(
    immutables: &mut Immutables<CoinType>,
    secret: vector<u8>,
    target: address,
    ctx: &mut TxContext,
) {
    immutables.check_secret(secret);
    transfer::public_transfer(
        coin::take(&mut immutables.balance, immutables.amount, ctx),
        target,
    );

    let value = immutables.safety_deposit.value();

    transfer::public_transfer(
        coin::take(&mut immutables.safety_deposit, value, ctx),
        ctx.sender(),
    );
}

#[allow(lint(self_transfer))]
public(package) fun cancel<CoinType: drop>(self: &mut Immutables<CoinType>, ctx: &mut TxContext) {
    transfer::public_transfer(
        coin::take(&mut self.balance, self.amount, ctx),
        self.maker,
    );

    let value = self.safety_deposit.value();

    transfer::public_transfer(
        coin::take(&mut self.safety_deposit, value, ctx),
        ctx.sender(),
    );
}

public(package) fun get_timelock<CoinType: drop>(self: &Immutables<CoinType>): &TimeLocks {
    &self.timelocks
}

public fun taker<CoinType: drop>(self: &Immutables<CoinType>): address {
    self.taker
}

public fun maker<CoinType: drop>(self: &Immutables<CoinType>): address {
    self.maker
}
