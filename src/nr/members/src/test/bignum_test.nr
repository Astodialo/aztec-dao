use crate::types::U256::U256;
use dep::bignum::BigNum;

#[test]
unconstrained fn test_from_u128_limb_order() {
    let val = U256::from_u128(0x1);
    let limbs = val.get_limbs();
    assert(limbs[0] == 1, "limb 0 should be 1");
    assert(limbs[1] == 0, "limb 1 should be 0");
    assert(limbs[2] == 0, "limb 2 should be 0");
}

#[test]
unconstrained fn test_lshift_by_0() {
    let val = U256::from_u128(0x123456789ABCDEF0);
    let shifted = val.lshift(0);
    assert(shifted.eq(val), "lshift by 0 should return same value");
}

#[test]
unconstrained fn test_lshift_by_128() {
    let val = U256::from_u128(0xDEADBEEF);
    let shifted = val.lshift(128);
    let limbs = shifted.get_limbs();
    assert(limbs[0] == 0, "limb 0 should be 0");
    assert(limbs[1] == 0xDEADBEEF, "limb 1 should have original value");
    assert(limbs[2] == 0, "limb 2 should be 0");
}

#[test]
unconstrained fn test_lshift_by_256() {
    let val = U256::from_u128(0xCAFE);
    let shifted = val.lshift(256);
    let limbs = shifted.get_limbs();
    assert(limbs[0] == 0, "limb 0 should be 0");
    assert(limbs[1] == 0, "limb 1 should be 0");
    assert(limbs[2] == 0xCAFE, "limb 2 should have original value");
}

#[test]
unconstrained fn test_rshift_by_0() {
    let val = U256::from_u128(0x123456789ABCDEF0);
    let shifted = val.rshift(0);
    assert(shifted.eq(val), "rshift by 0 should return same value");
}

#[test]
unconstrained fn test_rshift_by_128() {
    let limbs_in = [0xDEADBEEF as u128, 0xCAFEBABE as u128, 0x12345678 as u128];
    let val = U256::from_limbs(limbs_in);
    let shifted = val.rshift(128);
    let limbs_out = shifted.get_limbs();
    assert(limbs_out[0] == 0xCAFEBABE, "limb 0 should be old limb 0");
    assert(limbs_out[1] == 0x12345678, "limb 1 should be old limb 1");
    assert(limbs_out[2] == 0, "limb 2 should be 0");
}

#[test]
unconstrained fn test_rshift_lshift_roundtrip() {
    let limbs_in = [0xFFFFFFFF as u128, 0xDEADBEEF as u128, 0];
    let val = U256::from_limbs(limbs_in);
    let shifted_left = val.lshift(64);
    let roundtrip = shifted_left.rshift(64);
    assert(roundtrip.eq(val), "lshift then rshift should return original");
}

#[test]
unconstrained fn test_lshift_zero() {
    let val = U256::zero();
    let shifted = val.lshift(100);
    assert(shifted.is_zero(), "shifting zero should give zero");
}

#[test]
unconstrained fn test_rshift_zero() {
    let val = U256::zero();
    let shifted = val.rshift(100);
    assert(shifted.is_zero(), "shifting zero should give zero");
}
