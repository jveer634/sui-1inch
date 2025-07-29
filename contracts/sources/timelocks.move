/// Module: timelocks
module contracts::timelocks;

public struct TimeLocks has copy, drop, store {
    deployed_at: u64, // timestamp when escrow starts (from Sui clock)
    src_withdrawal: u32,
    src_public_withdrawal: u32,
    src_cancellation: u32,
    src_public_cancellation: u32,
    dst_withdrawal: u32,
    dst_public_withdrawal: u32,
    dst_cancellation: u32,
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
