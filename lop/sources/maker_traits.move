module lop::maker_traits;

/// Struct wrapper around u256 for type safety and code clarity
public struct MakerTraits has copy, drop, store {
    value: u256,
}

// High-bit flags (bit XXX: 0 = least significant, 255 = most significant)
const NO_PARTIAL_FILLS_FLAG: u256 = 1 << 255;
const ALLOW_MULTIPLE_FILLS_FLAG: u256 = 1 << 254;
const PRE_INTERACTION_CALL_FLAG: u256 = 1 << 252;
const POST_INTERACTION_CALL_FLAG: u256 = 1 << 251;
const NEED_CHECK_EPOCH_MANAGER_FLAG: u256 = 1 << 250;
const HAS_EXTENSION_FLAG: u256 = 1 << 249;
// const USE_PERMIT2_FLAG: u256 = 1 << 248;
// const UNWRAP_WETH_FLAG: u256 = 1 << 247;

// Offsets/masks for low 200 bits
const ALLOWED_SENDER_MASK: u256 = (1u256 << 80) - 1;
const EXPIRATION_OFFSET: u8 = 80;
const EXPIRATION_MASK: u256 = ((1u256 << 40) - 1);
const NONCE_OR_EPOCH_OFFSET: u8 = 120;
const NONCE_OR_EPOCH_MASK: u256 = ((1u256 << 40) - 1);
const SERIES_OFFSET: u8 = 160;
const SERIES_MASK: u256 = ((1u256 << 40) - 1);

/// Constructor to create a MakerTraits from a u256 value
public fun new(value: u256): MakerTraits {
    MakerTraits { value }
}

/// Expose access to the underlying u256 if ever needed
public fun value(self: &MakerTraits): u256 {
    self.value
}

// Flag checkers
public fun has_extension(self: &MakerTraits): bool {
    (self.value & HAS_EXTENSION_FLAG) != 0u256
}

public fun allow_partial_fills(self: &MakerTraits): bool {
    (self.value & NO_PARTIAL_FILLS_FLAG) == 0u256
}

public fun allow_multiple_fills(self: &MakerTraits): bool {
    (self.value & ALLOW_MULTIPLE_FILLS_FLAG) != 0u256
}

public fun need_pre_interaction_call(self: &MakerTraits): bool {
    (self.value & PRE_INTERACTION_CALL_FLAG) != 0u256
}

public fun need_post_interaction_call(self: &MakerTraits): bool {
    (self.value & POST_INTERACTION_CALL_FLAG) != 0u256
}

public fun need_check_epoch_manager(self: &MakerTraits): bool {
    (self.value & NEED_CHECK_EPOCH_MANAGER_FLAG) != 0u256
}

// note: permit2 is not available in sui
public fun use_permit2(_self: &MakerTraits): bool {
    // (self.value & USE_PERMIT2_FLAG) != 0u256
    false
}

// note: unwrapping eth is not supported in sui
public fun unwrap_weth(_self: &MakerTraits): bool {
    // (self.value & UNWRAP_WETH_FLAG) != 0u256
    false
}

// Extractors
public fun get_allowed_sender(self: &MakerTraits): u256 {
    self.value & ALLOWED_SENDER_MASK
}

public fun is_allowed_sender(self: &MakerTraits, sender: u256): bool {
    let allowed_sender = get_allowed_sender(self);
    allowed_sender == 0u256 || ((sender & ALLOWED_SENDER_MASK) == allowed_sender)
}

public fun get_expiration_time(self: &MakerTraits): u256 {
    (self.value >> EXPIRATION_OFFSET) & EXPIRATION_MASK
}

// Now must be passed in by the caller (Move does not have global timestamps)
public fun is_expired(self: &MakerTraits, now: u256): bool {
    let exp = get_expiration_time(self);
    exp != 0u256 && exp < now
}

public fun nonce_or_epoch(self: &MakerTraits): u256 {
    (self.value >> NONCE_OR_EPOCH_OFFSET) & NONCE_OR_EPOCH_MASK
}

public fun series(self: &MakerTraits): u256 {
    (self.value >> SERIES_OFFSET) & SERIES_MASK
}

// Composite logic
public fun use_bit_invalidator(self: &MakerTraits): bool {
    !allow_partial_fills(self) || !allow_multiple_fills(self)
}
