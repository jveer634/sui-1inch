/// Module: immutables
module contracts::immutables;

use contracts::bytes32::{Self, Bytes32};
use contracts::timelocks::{Self, TimeLocks};
use sui::address;
use sui::clock::Clock;
use sui::hash;

public struct ImmutablesParams has copy, drop, store {
    order_hash: vector<u8>,
    hash_lock: vector<u8>,
    safety_deposit: u256,
    maker: u256,
    taker: u256,
    amount: u256,
    timelocks: u256,
}

public struct Immutables has key, store {
    id: UID,
    order_hash: Bytes32,
    taker: address,
    maker: address,
    amount: u256,
    safety_deposit: u256,
    hash_lock: Bytes32,
    timelocks: TimeLocks,
}

// errors
const EInvalidCaller: u64 = 0;
const EInvalidSecret: u64 = 1;

public(package) fun new(params: ImmutablesParams, clock: &Clock, ctx: &mut TxContext): Immutables {
    let ImmutablesParams {
        order_hash,
        maker,
        taker,
        timelocks,
        safety_deposit,
        amount,
        hash_lock,
    } = params;

    Immutables {
        id: object::new(ctx),
        order_hash: bytes32::to_bytes32(order_hash),
        maker: address::from_u256(maker),
        taker: address::from_u256(taker),
        amount,
        safety_deposit,
        hash_lock: bytes32::to_bytes32(hash_lock),
        timelocks: timelocks::set_deployed_at(timelocks, clock.timestamp_ms() / 1000),
    }
}

public(package) fun params_new(
    order_hash: vector<u8>,
    hash_lock: vector<u8>,
    safety_deposit: u256,
    maker: u256,
    taker: u256,
    amount: u256,
    timelocks: u256,
): ImmutablesParams {
    ImmutablesParams {
        order_hash,
        hash_lock,
        safety_deposit,
        maker,
        taker,
        amount,
        timelocks,
    }
}

public(package) fun check_taker(self: &Immutables, ctx: &TxContext) {
    assert!(self.taker == ctx.sender(), EInvalidCaller);
}

public(package) fun check_secret(self: &Immutables, secret: vector<u8>) {
    let secret = bytes32::to_bytes32(hash::keccak256(&secret));
    assert!(self.hash_lock == secret, EInvalidSecret);
}

public(package) fun get_timelock(self: &Immutables): &TimeLocks {
    &self.timelocks
}

public fun taker(self: &Immutables): address {
    self.taker
}

public fun maker(self: &Immutables): address {
    self.maker
}

public fun hash_lock(self: &Immutables): vector<u8> {
    self.hash_lock.from_bytes32()
}

public fun timelocks(self: &Immutables): TimeLocks {
    self.timelocks
}
