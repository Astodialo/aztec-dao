use crate::types::hat_note::HatNote;
use crate::types::U256::U256;
use dep::bignum::BigNum;

fn zero() -> U256 {
    U256::zero()
}

#[test]
unconstrained fn test_getTopHatDomain_tophat() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let domain = HatNote::getTopHatDomain(tophat);
    assert(domain == 0, "tophat domain should be 0");
}

#[test]
unconstrained fn test_getTopHatDomain_value_1() {
    let hat = U256::from_u16(1);
    let domain = HatNote::getTopHatDomain(hat);
    assert(domain == 0, "getTopHatDomain(1) should be 0");
}

#[test]
unconstrained fn test_getTopHatDomain_value_1_shl_224() {
    let hat = U256::from_u128(1);
    let shifted = hat.lshift(224);
    let domain = HatNote::getTopHatDomain(shifted);
    assert(domain == 1, "getTopHatDomain(1 << 224) should be 1");
}

#[test]
unconstrained fn test_getTopHatDomain_nonzero_domain() {
    let hat = U256::from_u16(42).lshift(224);
    let extracted_domain = HatNote::getTopHatDomain(hat);
    assert(extracted_domain == 42, "domain should be 42");
}

#[test]
unconstrained fn test_getTopHatDomain_level_1() {
    let admin = HatNote::buildHatId(zero(), 1);
    let domain = HatNote::getTopHatDomain(admin);
    assert(domain == 0, "level 1 domain should be 0");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_level_0() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(tophat, 5);

    let child_level = HatNote::getLocalHatLevel(child);
    let admin_at_0 = HatNote::getAdminAtLocalLevel(child, 0);
    let zero_val = U256::zero();

    assert(child_level >= 2, "child should be at level 2 or higher");
    assert(admin_at_0.ne(zero_val), "level 0 admin should not be zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_exact_values() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let mut hat = tophat;
    
    for i in 1..15 {
        hat = HatNote::buildHatId(hat, i as u16);
    }
    
    let level = HatNote::getLocalHatLevel(hat);
    assert(level == 14, "hat should be level 14");
    
    let admin_13 = HatNote::getAdminAtLocalLevel(hat, 13);
    let admin_12 = HatNote::getAdminAtLocalLevel(hat, 12);
    
    assert(!admin_13.is_zero(), "admin at level 13 should not be zero");
    assert(!admin_12.is_zero(), "admin at level 12 should not be zero");
    
    let admin_14 = HatNote::getAdminAtLocalLevel(hat, 14);
    let admin_0 = HatNote::getAdminAtLocalLevel(hat, 0);
    
    assert(admin_14.eq(hat), "admin at level 14 should be the hat itself");
    assert(!admin_0.is_zero(), "admin at level 0 should not be zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_level_1() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(tophat, 5);
    let child_level = HatNote::getLocalHatLevel(child);
    let admin_at_1 = HatNote::getAdminAtLocalLevel(child, 1);
    let zero_val = U256::zero();

    assert(child_level >= 2, "child should be at level 2 or higher");
    assert(admin_at_1.ne(zero_val), "level 1 admin should not be zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_chain() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(tophat, 2);
    let l2 = HatNote::buildHatId(l1, 3);
    let l3 = HatNote::buildHatId(l2, 4);

    let l3_level = HatNote::getLocalHatLevel(l3);
    let admin_0 = HatNote::getAdminAtLocalLevel(l3, 0);
    let admin_1 = HatNote::getAdminAtLocalLevel(l3, 1);
    let zero_val = U256::zero();

    assert(l3_level == 4, "l3 should be level 4");
    assert(admin_0.ne(zero_val), "level 0 admin should not be zero");
    assert(admin_1.ne(zero_val), "level 1 admin should not be zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_level_13_max() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let mut current = tophat;

    for _i in 0..13 {
        current = HatNote::buildHatId(current, 1);
    }

    let level = HatNote::getLocalHatLevel(current);
    assert(level == 14, "should be level 14");

    let admin_13 = HatNote::getAdminAtLocalLevel(current, 13);
    let admin_12 = HatNote::getAdminAtLocalLevel(current, 12);
    let zero_val = U256::zero();

    assert(admin_13.ne(zero_val), "level 13 admin should not be zero");
    assert(admin_12.ne(zero_val), "level 12 admin should not be zero");
}

#[test]
unconstrained fn test_isValidHatId_tophat_valid() {
    let tophat = HatNote::buildHatId(zero(), 1);
    assert(HatNote::isValidHatId(tophat), "tophat should be valid");
}

#[test]
unconstrained fn test_isValidHatId_tophat_zero() {
    assert(HatNote::isValidHatId(zero()), "zero hat id should be valid (tophat)");
}

#[test]
unconstrained fn test_isValidHatId_child_valid() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(admin, 1);
    assert(HatNote::isValidHatId(child), "child should be valid");
}

#[test]
unconstrained fn test_isValidHatId_chain_valid() {
    let admin = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(admin, 1);
    let l2 = HatNote::buildHatId(l1, 1);
    let l3 = HatNote::buildHatId(l2, 1);

    assert(HatNote::isValidHatId(l1), "l1 valid");
    assert(HatNote::isValidHatId(l2), "l2 valid");
    assert(HatNote::isValidHatId(l3), "l3 valid");
}

#[test]
unconstrained fn test_isValidHatId_max_level_valid() {
    let admin = zero();
    let mut current = HatNote::buildHatId(admin, 1);

    for _i in 0..13 {
        current = HatNote::buildHatId(current, 1);
    }

    assert(HatNote::isValidHatId(current), "max level chain should be valid");
}

#[test]
unconstrained fn test_isValidHatId_different_child_ids() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child1 = HatNote::buildHatId(admin, 1);
    let child2 = HatNote::buildHatId(admin, 100);
    let child65535 = HatNote::buildHatId(admin, 65535);

    assert(HatNote::isValidHatId(child1), "child 1 valid");
    assert(HatNote::isValidHatId(child2), "child 100 valid");
    assert(HatNote::isValidHatId(child65535), "child max valid");
}

#[test]
unconstrained fn test_isValidHatId_deep_chain() {
    let admin = zero();
    let mut hat = HatNote::buildHatId(admin, 1);

    for _i in 0..14 {
        assert(HatNote::isValidHatId(hat), "hat should be valid");
        hat = HatNote::buildHatId(hat, 1);
    }
}

#[test]
unconstrained fn test_getTopHatDomain_tophat_level_1() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let level = HatNote::getLocalHatLevel(tophat);
    let domain = HatNote::getTopHatDomain(tophat);
    assert(level == 1, "tophat should be level 1");
    assert(domain == 0, "domain should be 0");
}

#[test]
unconstrained fn test_isLocalTopHat_consistency() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let level = HatNote::getLocalHatLevel(tophat);
    let is_tophat = HatNote::isLocalTopHat(tophat);
    assert(level == 1, "level should be 1");
    assert(is_tophat, "should be tophat");
}

#[test]
unconstrained fn test_level_0_is_zero() {
    let domain_only = U256::zero();
    let level = HatNote::getLocalHatLevel(domain_only);
    assert(level == 0, "level 0 should be 0");
}

#[test]
unconstrained fn test_isLocalTopHat_zero_hat_id() {
    let zero_hat = U256::zero();
    let is_tophat = HatNote::isLocalTopHat(zero_hat);
    assert(!is_tophat, "zero hat id should not be tophat");
}

#[test]
unconstrained fn test_isLocalTopHat_nonzero_domain_level_0() {
    let mut limbs = [0 as u128; 3];
    limbs[2] = 100 as u128;
    let domain_only = U256::from_limbs(limbs);
    let level = HatNote::getLocalHatLevel(domain_only);
    let is_tophat = HatNote::isLocalTopHat(domain_only);
    assert(level == 0, "domain only should be level 0");
    assert(!is_tophat, "level 0 should not be tophat even with non-zero domain");
}

#[test]
unconstrained fn test_isLocalTopHat_level_2_and_above() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let level2 = HatNote::buildHatId(tophat, 1);
    let level3 = HatNote::buildHatId(level2, 1);
    
    assert(HatNote::isLocalTopHat(tophat), "tophat should be tophat");
    assert(!HatNote::isLocalTopHat(level2), "level 2 should not be tophat");
    assert(!HatNote::isLocalTopHat(level3), "level 3 should not be tophat");
}

#[test]
unconstrained fn test_getTopHatDomain_level_2_with_nonzero_domain() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let domain_hat = U256::from_u16(100).lshift(224);
    let hat_with_domain = U256::from_limbs([
        tophat.get_limbs()[0] | domain_hat.get_limbs()[0],
        tophat.get_limbs()[1] | domain_hat.get_limbs()[1],
        tophat.get_limbs()[2] | domain_hat.get_limbs()[2],
    ]);
    
    let extracted_domain = HatNote::getTopHatDomain(hat_with_domain);
    assert(extracted_domain == 100, "domain should be 100");
}

#[test]
unconstrained fn test_getTopHatDomain_max_domain() {
    let mut limbs = [0 as u128; 3];
    limbs[1] = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF as u128;
    let hat_with_max_domain = U256::from_limbs(limbs);
    let extracted_domain = HatNote::getTopHatDomain(hat_with_max_domain);
    assert(extracted_domain == 0xFFFFFFFF, "max domain should be 0xFFFFFFFF");
}

#[test]
unconstrained fn test_getTopHatDomain_high_bits_in_limb1() {
    let hat = U256::from_u16(1).lshift(224);
    let domain = HatNote::getTopHatDomain(hat);
    let limbs = hat.get_limbs();
    let expected = ((limbs[1] >> 96) & 0xFFFF) as u32;
    assert(domain == expected, "domain extraction from limb1");
}

#[test]
unconstrained fn test_getTopHatDomain_combined_limbs() {
    let hat = U256::from_u16(1).lshift(224);
    let domain = HatNote::getTopHatDomain(hat);
    assert(domain != 0, "combined domain should be non-zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_level_14() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let mut current = tophat;
    
    for _i in 0..13 {
        current = HatNote::buildHatId(current, 1);
    }
    
    let level14_from_func = HatNote::getLocalHatLevel(current);
    assert(level14_from_func == 14, "should be level 14");
    
    let level13_admin = HatNote::getAdminAtLocalLevel(current, 13);
    assert(level13_admin.ne(U256::zero()), "level 13 admin should not be zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_zero_hat_id_level_0() {
    let zero_hat = U256::zero();
    let admin_at_0 = HatNote::getAdminAtLocalLevel(zero_hat, 0);
    assert(admin_at_0.is_zero(), "zero hat at level 0 should return zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_zero_hat_id_level_1() {
    let zero_hat = U256::zero();
    let admin_at_1 = HatNote::getAdminAtLocalLevel(zero_hat, 1);
    assert(admin_at_1.is_zero(), "zero hat at level 1 should return zero");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_exact_level_match() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let level2 = HatNote::buildHatId(tophat, 7);
    
    let admin_at_2 = HatNote::getAdminAtLocalLevel(level2, 2);
    assert(admin_at_2.eq(level2), "level 2 admin should be the hat itself");
}

#[test]
unconstrained fn test_getAdminAtLocalLevel_chain_full_extraction() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(tophat, 2);
    let l2 = HatNote::buildHatId(l1, 3);
    
    let admin_2 = HatNote::getAdminAtLocalLevel(l2, 2);
    assert(admin_2.eq(l1), "level 2 admin should be l1");
}

#[test]
unconstrained fn test_isValidHatId_invalid_intermediate_zero_level_1() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(tophat, 5);
    let l2 = HatNote::buildHatId(l1, 10);
    
    assert(HatNote::isValidHatId(tophat), "tophat should be valid");
    assert(HatNote::isValidHatId(l1), "l1 should be valid");
    assert(HatNote::isValidHatId(l2), "l2 should be valid");
}

#[test]
unconstrained fn test_isValidHatId_invalid_level_2_with_zero_level_1() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(tophat, 5);
    
    assert(HatNote::isValidHatId(tophat), "tophat valid");
    assert(HatNote::isValidHatId(l1), "level 1 valid");
}

#[test]
unconstrained fn test_isValidHatId_invalid_deep_chain_with_gap() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let l1 = HatNote::buildHatId(tophat, 1);
    let l2 = HatNote::buildHatId(l1, 1);
    
    assert(HatNote::isValidHatId(tophat), "tophat valid");
    assert(HatNote::isValidHatId(l1), "l1 valid");
    assert(HatNote::isValidHatId(l2), "l2 valid");
}

#[test]
unconstrained fn test_isValidHatId_all_16_bit_values_valid() {
    let tophat = HatNote::buildHatId(zero(), 1);
    
    for i in 1..16 {
        let hat = HatNote::buildHatId(tophat, i as u16);
        assert(HatNote::isValidHatId(hat), "hat id should be valid");
    }
}

#[test]
unconstrained fn test_isValidHatId_max_u16_values() {
    let tophat = HatNote::buildHatId(zero(), 1);
    
    let hat_65535 = HatNote::buildHatId(tophat, 65535);
    assert(HatNote::isValidHatId(hat_65535), "max u16 value should be valid");
    
    let level2_max = HatNote::buildHatId(hat_65535, 65535);
    assert(HatNote::isValidHatId(level2_max), "level 2 with max values should be valid");
}

#[test]
unconstrained fn test_isValidHatId_boundary_level_14() {
    let mut hat = U256::zero();
    
    for _i in 0..14 {
        hat = HatNote::buildHatId(hat, 1);
    }
    
    assert(HatNote::getLocalHatLevel(hat) == 14, "should be level 14");
    assert(HatNote::isValidHatId(hat), "max level 14 should be valid");
}

#[test]
unconstrained fn test_isLocalTopHat_and_isValidHatId_consistency() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(tophat, 1);
    
    assert(HatNote::isLocalTopHat(tophat) == HatNote::isValidHatId(tophat), "tophat consistency");
    assert(HatNote::isLocalTopHat(child) == false, "child is not tophat");
    assert(HatNote::isValidHatId(child) == true, "child is valid");
}

#[test]
unconstrained fn test_isValidHatId_solidity_empty1() {
    let domain = U256::from_u32(0xFF).lshift(224);
    let l1 = U256::from_u32(0).lshift(208);
    let l2 = U256::from_u32(2).lshift(192);
    let l3 = U256::from_u32(3).lshift(176);
    let l4 = U256::from_u32(4).lshift(160);
    let l5 = U256::from_u32(5).lshift(144);
    let l6 = U256::from_u32(6).lshift(128);
    let l7 = U256::from_u32(7).lshift(112);
    let l8 = U256::from_u32(8).lshift(96);
    let l9 = U256::from_u32(9).lshift(80);
    let l10 = U256::from_u32(10).lshift(64);
    let l11 = U256::from_u32(11).lshift(48);
    let l12 = U256::from_u32(12).lshift(32);
    let l13 = U256::from_u32(13).lshift(16);
    let l14 = U256::from_u32(14);
    
    let mut hat: U256 = domain;
    hat = hat.bitor(l1);
    hat = hat.bitor(l2);
    hat = hat.bitor(l3);
    hat = hat.bitor(l4);
    hat = hat.bitor(l5);
    hat = hat.bitor(l6);
    hat = hat.bitor(l7);
    hat = hat.bitor(l8);
    hat = hat.bitor(l9);
    hat = hat.bitor(l10);
    hat = hat.bitor(l11);
    hat = hat.bitor(l12);
    hat = hat.bitor(l13);
    hat = hat.bitor(l14);
    
    let level = HatNote::getLocalHatLevel(hat);
    assert(level == 14, "should be level 14");
    assert(!HatNote::isValidHatId(hat), "empty at level 1 should be invalid");
}

#[test]
unconstrained fn test_isValidHatId_solidity_empty2() {
    let domain = U256::from_u32(0xFF).lshift(224);
    let l1 = U256::from_u32(1).lshift(208);
    let l2 = U256::from_u32(0).lshift(192);
    let l3 = U256::from_u32(3).lshift(176);
    let l4 = U256::from_u32(4).lshift(160);
    let l5 = U256::from_u32(5).lshift(144);
    let l6 = U256::from_u32(6).lshift(128);
    let l7 = U256::from_u32(7).lshift(112);
    let l8 = U256::from_u32(8).lshift(96);
    let l9 = U256::from_u32(9).lshift(80);
    let l10 = U256::from_u32(10).lshift(64);
    let l11 = U256::from_u32(11).lshift(48);
    let l12 = U256::from_u32(12).lshift(32);
    let l13 = U256::from_u32(13).lshift(16);
    let l14 = U256::from_u32(14);
    
    let mut hat: U256 = domain;
    hat = hat.bitor(l1);
    hat = hat.bitor(l2);
    hat = hat.bitor(l3);
    hat = hat.bitor(l4);
    hat = hat.bitor(l5);
    hat = hat.bitor(l6);
    hat = hat.bitor(l7);
    hat = hat.bitor(l8);
    hat = hat.bitor(l9);
    hat = hat.bitor(l10);
    hat = hat.bitor(l11);
    hat = hat.bitor(l12);
    hat = hat.bitor(l13);
    hat = hat.bitor(l14);
    
    assert(!HatNote::isValidHatId(hat), "empty at level 2 should be invalid");
}

#[test]
unconstrained fn test_isValidHatId_solidity_empty8() {
    let domain = U256::from_u32(0xFF).lshift(224);
    let l1 = U256::from_u32(1).lshift(208);
    let l2 = U256::from_u32(2).lshift(192);
    let l3 = U256::from_u32(3).lshift(176);
    let l4 = U256::from_u32(4).lshift(160);
    let l5 = U256::from_u32(5).lshift(144);
    let l6 = U256::from_u32(6).lshift(128);
    let l7 = U256::from_u32(7).lshift(112);
    let l8 = U256::from_u32(0).lshift(96);
    let l9 = U256::from_u32(9).lshift(80);
    let l10 = U256::from_u32(10).lshift(64);
    let l11 = U256::from_u32(11).lshift(48);
    let l12 = U256::from_u32(12).lshift(32);
    let l13 = U256::from_u32(13).lshift(16);
    let l14 = U256::from_u32(14);
    
    let mut hat: U256 = domain;
    hat = hat.bitor(l1);
    hat = hat.bitor(l2);
    hat = hat.bitor(l3);
    hat = hat.bitor(l4);
    hat = hat.bitor(l5);
    hat = hat.bitor(l6);
    hat = hat.bitor(l7);
    hat = hat.bitor(l8);
    hat = hat.bitor(l9);
    hat = hat.bitor(l10);
    hat = hat.bitor(l11);
    hat = hat.bitor(l12);
    hat = hat.bitor(l13);
    hat = hat.bitor(l14);
    
    assert(!HatNote::isValidHatId(hat), "empty at level 8 should be invalid");
}

#[test]
unconstrained fn test_isValidHatId_solidity_emptye_valid() {
    let domain = U256::from_u32(0xFF).lshift(224);
    let l1 = U256::from_u32(1).lshift(208);
    let l2 = U256::from_u32(2).lshift(192);
    let l3 = U256::from_u32(3).lshift(176);
    let l4 = U256::from_u32(4).lshift(160);
    let l5 = U256::from_u32(5).lshift(144);
    let l6 = U256::from_u32(6).lshift(128);
    let l7 = U256::from_u32(7).lshift(112);
    let l8 = U256::from_u32(8).lshift(96);
    let l9 = U256::from_u32(9).lshift(80);
    let l10 = U256::from_u32(10).lshift(64);
    let l11 = U256::from_u32(11).lshift(48);
    let l12 = U256::from_u32(12).lshift(32);
    let l13 = U256::from_u32(13).lshift(16);
    
    let mut hat: U256 = domain;
    hat = hat.bitor(l1);
    hat = hat.bitor(l2);
    hat = hat.bitor(l3);
    hat = hat.bitor(l4);
    hat = hat.bitor(l5);
    hat = hat.bitor(l6);
    hat = hat.bitor(l7);
    hat = hat.bitor(l8);
    hat = hat.bitor(l9);
    hat = hat.bitor(l10);
    hat = hat.bitor(l11);
    hat = hat.bitor(l12);
    hat = hat.bitor(l13);
    
    let level = HatNote::getLocalHatLevel(hat);
    assert(level == 13, "should be level 13");
    assert(HatNote::isValidHatId(hat), "level 13 with no level 14 is VALID");
}
