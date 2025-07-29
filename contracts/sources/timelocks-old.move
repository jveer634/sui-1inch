/// Module: timelocks_old
module contracts::timelocks_old;

use contracts::base_escrow::CrossChainSwap;
use sui::clock::Clock;

public struct Timelocks has copy, drop, store {
    deployed_at: u64, // timestamp when escrow starts (from Sui clock)
    src_withdrawal: u64,
    src_public_withdrawal: u64,
    src_cancellation: u64,
    src_public_cancellation: u64,
    dst_withdrawal: u64,
    dst_public_withdrawal: u64,
    dst_cancellation: u64,
}

public enum Stage {
    SrcWithdrawal,
    SrcPublicWithdrawal,
    SrcCancellation,
    SrcPublicCancellation,
    DstWithdrawal,
    DstPublicWithdrawal,
    DstCancellation,
}

// const EInvalidTime: u64 = 3;

public(package) fun new(deployed_at: u64): Timelocks {
    Timelocks {
        deployed_at,
        src_withdrawal: 0,
        src_public_withdrawal: 0,
        src_cancellation: 0,
        src_public_cancellation: 0,
        dst_withdrawal: 0,
        dst_public_withdrawal: 0,
        dst_cancellation: 0,
    }
}

public(package) fun rescue_delay<AccessToken: drop>(
    self: &Timelocks,
    ccs: &CrossChainSwap<AccessToken>,
): u64 { self.deployed_at + ccs.rescue_delay() * 1000 }

// GETTER FUNCTIONS
public fun get_unlock_time(t: &Timelocks, delay: u32): u64 {
    t.deployed_at + (delay as u64)
}

// INTERNAL FUNCTIONS
public(package) fun only_after(time: u64, clock: &Clock) {
    assert!(time * 1000 >= clock.timestamp_ms(), 0)
}

public(package) fun only_before(time: u64, clock: &Clock) {
    assert!(time * 1000 <= clock.timestamp_ms(), 1)
}

// ARGUMENT GETTERS
public fun src_withdrawal(self: &Timelocks): u64 {
    self.src_withdrawal
}

public fun src_public_withdrawal(self: &Timelocks): u64 {
    self.src_public_withdrawal
}

public fun src_cancellation(self: &Timelocks): u64 {
    self.src_cancellation
}

public fun src_public_cancellation(self: &Timelocks): u64 {
    self.src_public_cancellation
}

public fun dst_withdrawal(self: &Timelocks): u64 {
    self.dst_withdrawal
}

public fun dst_public_withdrawal(self: &Timelocks): u64 {
    self.dst_public_withdrawal
}

public fun dst_cancellation(self: &Timelocks): u64 {
    self.src_cancellation
}

public fun dst_public_cancellation(self: &Timelocks): u64 {
    self.src_public_cancellation
}
