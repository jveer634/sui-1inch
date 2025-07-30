/// Module: bytes32
module contracts::bytes32;

/// Custom 'Bytes32' type: Must always contain exactly 32 bytes!
public struct Bytes32 has copy, drop, store {
    bytes: vector<u8>,
}

/// Ensures a vector is exactly 32 bytes to construct our custom type.
public fun to_bytes32(input: vector<u8>): Bytes32 {
    assert!(vector::length(&input) == 32, 0);
    Bytes32 { bytes: input }
}

public fun from_bytes32(self: &Bytes32): vector<u8> {
    self.bytes
}
