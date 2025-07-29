/// Module: timelocks
module contracts::timelocks;

use sui::clock::Clock;

public struct TimeLocks has copy, drop, store {
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

public(package) fun new(): TimeLocks {
    TimeLocks {
        deployed_at: 0, // timestamp when escrow starts (from Sui clock)
        src_withdrawal: 0,
        src_public_withdrawal: 0,
        src_cancellation: 0,
        src_public_cancellation: 0,
        dst_withdrawal: 0,
        dst_public_withdrawal: 0,
        dst_cancellation: 0,
    }
}

public fun get_unlock_time(t: &TimeLocks, delay: u32): u64 {
    t.deployed_at + (delay as u64)
}

public(package) fun only_after(time: u64, clock: &Clock) {
    assert!(time * 1000 >= clock.timestamp_ms(), 0)
}

public(package) fun only_before(time: u64, clock: &Clock) {
    assert!(time * 1000 <= clock.timestamp_ms(), 1)
}

public fun src_withdrawal(self: &TimeLocks): u64 {
    self.src_withdrawal
}

public fun src_public_withdrawal(self: &TimeLocks): u64 {
    self.src_public_withdrawal
}

public fun src_cancellation(self: &TimeLocks): u64 {
    self.src_cancellation
}

public fun src_public_cancellation(self: &TimeLocks): u64 {
    self.src_public_cancellation
}