import { bcs } from "@mysten/sui/bcs";

export const ImmutablesParams = bcs.struct("ImmutablesParams", {
    order_hash: bcs.byteVector(),
    hash_lock: bcs.byteVector(),
    safety_deposit: bcs.u256(),
    maker: bcs.u256(),
    taker: bcs.u256(),
    amount: bcs.u256(),
    timelocks: bcs.u256(),
});
