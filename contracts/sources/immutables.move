/// Module: immutables
module contracts::immutables;

use contracts::types::Bytes32;
use sui::balance::Balance;
use sui::bcs;
use sui::hash;

public struct Immutables<phantom T> has key, store {
    id: UID,
    orderHash: Bytes32,
    taker: address,
    maker: address,
    amount: u256,
    safety_deposit: u256,
    balance: Balance<T>,
    hashLock: Bytes32,
    // timelocks: Timelocks
}

// only visible inside the package
public(package) fun hash<T>(self: &Immutables<T>): vector<u8> {
    let bytes = bcs::to_bytes(self);
    hash::keccak256(&bytes)
}
