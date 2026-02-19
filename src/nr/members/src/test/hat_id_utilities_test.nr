use crate::types::bignum_extensions::U256;
use crate::types::hat_note::HatNote;

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
