use crate::types::bignum_extensions::U256;
use crate::types::hat_note::HatNote;

fn zero() -> U256 {
    U256::zero()
}

#[test]
unconstrained fn test_lshift_208_result() {
    let one = U256::from_u16(1);
    let shifted = one.lshift(208);
    
    // Check level with mask_lower(224)
    let mask_224 = U256::mask_lower(224);
    let masked_224 = shifted.bitand(mask_224);
    let is_zero_224 = masked_224.is_zero();
    
    // Check level with mask_lower(208)
    let mask_208 = U256::mask_lower(208);
    let masked_208 = shifted.bitand(mask_208);
    let is_zero_208 = masked_208.is_zero();
    
    assert(!is_zero_224, "mask_lower(224) should NOT be zero");
    assert(is_zero_208, "mask_lower(208) should be zero");
}
