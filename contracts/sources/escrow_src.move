/// Module: escrow_src
module contracts::escrow_src;

use contracts::immutables;
use sui::coin::Coin;
use sui::sui::SUI;

public entry fun new<CoinType: drop>(
    maker: address,
    taker: address,
    amount: u64,
    hash_lock: vector<u8>,
    safety_deposit: Coin<SUI>,
    coin: Coin<CoinType>,
    ctx: &mut TxContext,
) {
    immutables::new(taker, maker, amount, hash_lock, coin, safety_deposit, ctx);
}
