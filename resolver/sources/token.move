module resolver::token;

use std::u64;
use sui::coin::{Self, TreasuryCap};

public struct TOKEN has drop {}

fun init(witness: TOKEN, ctx: &mut TxContext) {
    let decimals = 9;
    let name = b"Mock Token";
    let symbol = b"MT";
    let description = b"This token is for testing and illustration only";
    let icon_url = option::none();

    let (mut treasury, metadata) = coin::create_currency(
        witness,
        decimals,
        symbol,
        name,
        description,
        icon_url,
        ctx,
    );
    let amount = u64::pow(10, 12);

    let c = coin::mint(&mut treasury, amount, ctx);
    transfer::public_transfer(c, ctx.sender());

    transfer::public_freeze_object(metadata);
    transfer::public_share_object(treasury);
}

// use the above shared treasury cap for minitng
public fun mint<CoinType: drop>(
    treasury: &mut TreasuryCap<CoinType>,
    amount: u64,
    target: address,
    ctx: &mut TxContext,
) {
    let c = coin::mint(treasury, amount, ctx);
    transfer::public_transfer(c, target);
}
