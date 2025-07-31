/// Module: taker_traits
module lop::taker_traits;

/// Wrapper struct around u256 for TakerTraits
public struct TakerTraits has copy, drop, store {
    value: u256,
}

// High-bit flags (bit 255 = highest bit)
const MAKER_AMOUNT_FLAG: u256 = 1 << 255;
// const UNWRAP_WETH_FLAG: u256 = 1 << 254;
const SKIP_ORDER_PERMIT_FLAG: u256 = 1 << 253;
const USE_PERMIT2_FLAG: u256 = 1 << 252;
const ARGS_HAS_TARGET: u256 = 1 << 251;

// Offsets and masks (length fields are 24 bits wide)
const ARGS_EXTENSION_LENGTH_OFFSET: u8 = 224;
const ARGS_EXTENSION_LENGTH_MASK: u256 = (1 << 24) - 1; // 0xffffff

const ARGS_INTERACTION_LENGTH_OFFSET: u8 = 200;
const ARGS_INTERACTION_LENGTH_MASK: u256 = (1 << 24) - 1; // 0xffffff

// Threshold mask for lower 185 bits (bits 0 through 184)
// Hex mask taken from Solidity, convert to decimal:
// 0x000000000000000000ffffffffffffffffffffffffffffffffffffffffffffff
// In Move, build by shifting (2^185)-1 = (1 << 185) - 1
const AMOUNT_MASK: u256 = (1 << 185) - 1;

/// Constructor
public fun new(value: u256): TakerTraits {
    TakerTraits { value }
}

/// Expose raw value
public fun value(self: &TakerTraits): u256 {
    self.value
}

// Flag checkers

public fun args_has_target(self: &TakerTraits): bool {
    (self.value & ARGS_HAS_TARGET) != 0u256
}

public fun args_extension_length(self: &TakerTraits): u256 {
    (self.value >> ARGS_EXTENSION_LENGTH_OFFSET) & ARGS_EXTENSION_LENGTH_MASK
}

public fun args_interaction_length(self: &TakerTraits): u256 {
    (self.value >> ARGS_INTERACTION_LENGTH_OFFSET) & ARGS_INTERACTION_LENGTH_MASK
}

public fun is_making_amount(self: &TakerTraits): bool {
    (self.value & MAKER_AMOUNT_FLAG) != 0u256
}

// note: unwrapping is not an option in sui
public fun unwrap_weth(_self: &TakerTraits): bool {
    false
    // (self.value & UNWRAP_WETH_FLAG) != 0u256
}

public fun skip_maker_permit(self: &TakerTraits): bool {
    (self.value & SKIP_ORDER_PERMIT_FLAG) != 0u256
}

public fun use_permit2(self: &TakerTraits): bool {
    (self.value & USE_PERMIT2_FLAG) != 0u256
}

/// Returns the threshold amount (max amount taker agrees to give)
public fun threshold(self: &TakerTraits): u256 {
    self.value & AMOUNT_MASK
}
