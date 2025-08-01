/// Module: timelocks
module contracts::timelocks;

use contracts::base_escrow::CrossChainSwap;
use std::u256;
use sui::clock::Clock;

public enum Stage {
    SrcWithdrawal,
    SrcPublicWithdrawal,
    SrcCancellation,
    SrcPublicCancellation,
    DstWithdrawal,
    DstPublicWithdrawal,
    DstCancellation,
}

public struct TimeLocks has copy, drop, store {
    value: u256,
}

// Constants for deployed_at mask and offset
const DEPLOYED_AT_OFFSET: u8 = 224;
const U32_MASK: u256 = 0xFFFF_FFFF;

public(package) fun set_deployed_at(tl: u256, deployed_at: u64): TimeLocks {
    let deployed_mask = U32_MASK << DEPLOYED_AT_OFFSET;

    let cleared_val = tl & u256::bitwise_not(deployed_mask);

    // Insert new deployed_at shifted left by 224 bits
    let inserted_val = cleared_val | (deployed_at as u256 << DEPLOYED_AT_OFFSET);
    TimeLocks { value: inserted_val }
}

/// Get deployment timestamp stored in highest 32 bits as u64
fun get_deployed_at(t: &TimeLocks): u64 {
    (t.value >> DEPLOYED_AT_OFFSET) as u64
}

fun stage_to_u8(stage: Stage): u8 {
    match (stage) {
        Stage::SrcWithdrawal => 0,
        Stage::SrcPublicWithdrawal => 1,
        Stage::SrcCancellation => 2,
        Stage::SrcPublicCancellation => 3,
        Stage::DstWithdrawal => 4,
        Stage::DstPublicWithdrawal => 5,
        Stage::DstCancellation => 6,
    }
}

/// Get the timelock value for a given stage (as u64)
public fun get(t: &TimeLocks, stage: Stage): u64 {
    let offset = stage_to_u8(stage) * 32;
    // Extract the stage u32 value
    let stage_val = ((t.value >> offset) & U32_MASK) as u64;
    // Add deployed_at to get absolute timestamp
    stage_val + get_deployed_at(t)
}

public(package) fun rescue_delay<AccessToken: drop>(
    self: &TimeLocks,
    ccs: &CrossChainSwap<AccessToken>,
): u64 { self.get_deployed_at() + ccs.rescue_delay() * 1000 }

// GETTER FUNCTIONS
public fun get_unlock_time(t: &TimeLocks, delay: u32): u64 {
    t.get_deployed_at() + (delay as u64)
}

// INTERNAL FUNCTIONS
public(package) fun only_after(time: u64, clock: &Clock) {
    assert!(time * 1000 >= clock.timestamp_ms(), 0)
}

public(package) fun only_before(time: u64, clock: &Clock) {
    assert!(time * 1000 <= clock.timestamp_ms(), 1)
}

// ARGUMENT GETTERS
public fun src_withdrawal(self: &TimeLocks): u64 {
    self.get(Stage::SrcWithdrawal)
}

public fun src_public_withdrawal(self: &TimeLocks): u64 {
    self.get(Stage::SrcPublicWithdrawal)
}

public fun src_cancellation(self: &TimeLocks): u64 {
    self.get(Stage::SrcCancellation)
}

public fun src_public_cancellation(self: &TimeLocks): u64 {
    self.get(Stage::SrcPublicCancellation)
}

public fun dst_withdrawal(self: &TimeLocks): u64 {
    self.get(Stage::DstWithdrawal)
}

public fun dst_public_withdrawal(self: &TimeLocks): u64 {
    self.get(Stage::DstPublicWithdrawal)
}

public fun dst_cancellation(self: &TimeLocks): u64 {
    self.get(Stage::DstCancellation)
}

public fun dst_public_cancellation(self: &TimeLocks): u64 {
    self.get(Stage::DstCancellation)
}

public fun value(self: &TimeLocks): u256 {
    self.value
}
