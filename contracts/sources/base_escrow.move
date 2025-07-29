/// Module: base_escrow
#[allow(unused_field)]
module contracts::base_escrow;

use std::string::String;
use sui::coin::Coin;

public struct CrossChainSwap<phantom AccessToken> has key, store {
    id: UID,
    rescue_delay: u64,
}

public struct SetUp has key {
    id: UID,
}

// const ESCROW_IMMUTABLES_SIZE: u64 = 0x100;

// events
/// Emitted on Escrow Cancelled
public struct EscrowCancelled has copy, drop {}

/// Emitted when funds are rescued
/// @param amount of tokens rescued
/// @param type - type of cois rescued
public struct FundsRescued<phantom CoinType> has copy, drop {
    amount: u256,
}

public struct EscrowWithdrawal has copy, drop {
    secret: String,
}

// errors
const EInvalidCaller: u64 = 0;

fun init(ctx: &mut TxContext) {
    transfer::transfer(SetUp { id: object::new(ctx) }, ctx.sender());
}

public fun setup<AccessToken: drop>(delay: u64, s: SetUp, ctx: &mut TxContext) {
    let SetUp { id } = s;
    object::delete(id);

    transfer::share_object(CrossChainSwap<AccessToken> {
        id: object::new(ctx),
        rescue_delay: delay,
    });
}

public(package) fun only_access_token_holder<AccessToken: drop>(
    _: &CrossChainSwap<AccessToken>,
    coin: &Coin<AccessToken>,
) { assert!(coin.value() > 1, EInvalidCaller); }

public(package) fun rescue_delay<AccessToken: drop>(self: &CrossChainSwap<AccessToken>): u64 {
    self.rescue_delay
}
