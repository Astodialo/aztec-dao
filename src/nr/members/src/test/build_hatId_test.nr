use crate::types::hat_note::HatNote;
use crate::types::U256::U256;

fn zero() -> U256 {
    U256::zero()
}

#[test]
unconstrained fn test_level_0_tophat() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let level = HatNote::getLocalHatLevel(tophat);
    assert(level == 1, "level should be 1");
}

#[test]
unconstrained fn test_level_1_child() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(admin, 1);
    let level = HatNote::getLocalHatLevel(child);
    assert(level == 2, "level should be at least 2");
}

#[test]
unconstrained fn test_level_2_grandchild() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(admin, 1);
    let grandchild = HatNote::buildHatId(child, 1);
    let level = HatNote::getLocalHatLevel(grandchild);
    assert(level == 3, "level should be at least 3");
}

#[test]
unconstrained fn test_level_3() {
    let admin = zero();
    let l1 = HatNote::buildHatId(admin, 1);
    let l2 = HatNote::buildHatId(l1, 1);
    let l3 = HatNote::buildHatId(l2, 1);
    let level = HatNote::getLocalHatLevel(l3);
    assert(level == 3, "level should be at least 3");
}

#[test]
unconstrained fn test_level_4() {
    let admin = zero();
    let l1 = HatNote::buildHatId(admin, 1);
    let l2 = HatNote::buildHatId(l1, 1);
    let l3 = HatNote::buildHatId(l2, 1);
    let l4 = HatNote::buildHatId(l3, 1);
    let level = HatNote::getLocalHatLevel(l4);
    assert(level == 4, "level should be at least 4");
}

#[test]
unconstrained fn test_level_5_14() {
    let admin = zero();
    let l1 = HatNote::buildHatId(admin, 1);
    let l2 = HatNote::buildHatId(l1, 1);
    let l3 = HatNote::buildHatId(l2, 1);
    let l4 = HatNote::buildHatId(l3, 1);
    let l5 = HatNote::buildHatId(l4, 1);
    let l6 = HatNote::buildHatId(l5, 1);
    let l7 = HatNote::buildHatId(l6, 1);
    let l8 = HatNote::buildHatId(l7, 1);
    let l9 = HatNote::buildHatId(l8, 1);
    let l10 = HatNote::buildHatId(l9, 1);
    let l11 = HatNote::buildHatId(l10, 1);
    let l12 = HatNote::buildHatId(l11, 1);
    let l13 = HatNote::buildHatId(l12, 1);
    let l14 = HatNote::buildHatId(l13, 1);
    let level5 = HatNote::getLocalHatLevel(l5);
    let level6 = HatNote::getLocalHatLevel(l6);
    let level7 = HatNote::getLocalHatLevel(l7);
    let level8 = HatNote::getLocalHatLevel(l8);
    let level9 = HatNote::getLocalHatLevel(l9);
    let level10 = HatNote::getLocalHatLevel(l10);
    let level11 = HatNote::getLocalHatLevel(l11);
    let level12 = HatNote::getLocalHatLevel(l12);
    let level13 = HatNote::getLocalHatLevel(l13);
    let level14 = HatNote::getLocalHatLevel(l14);
    assert(level5 == 5, "level should be at least 5");
    assert(level6 == 6, "level should be at least 6");
    assert(level7 == 7, "level should be at least 7");
    assert(level8 == 8, "level should be at least 8");
    assert(level9 == 9, "level should be at least 9");
    assert(level10 == 10, "level should be at least 10");
    assert(level11 == 11, "level should be at least 11");
    assert(level12 == 12, "level should be at least 12");
    assert(level13 == 13, "level should be at least 13");
    assert(level14 == 14, "level should be at least 14");
}

#[test]
unconstrained fn test_siblings_at_level_1() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let child1 = HatNote::buildHatId(tophat, 1);
    let child2 = HatNote::buildHatId(tophat, 2);
    assert(child1.ne(child2), "siblings should be different");
}

#[test]
unconstrained fn test_siblings_at_level_2() {
    let tophat = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(tophat, 1);
    let grandchild1 = HatNote::buildHatId(child, 1);
    let grandchild2 = HatNote::buildHatId(child, 2);
    assert(grandchild1.ne(grandchild2), "siblings should be different");
}

#[test]
unconstrained fn test_tophat_is_tophat() {
    let tophat = HatNote::buildHatId(zero(), 1);
    assert(HatNote::isLocalTopHat(tophat), "tophat should be tophat");
}

#[test]
unconstrained fn test_child_not_tophat() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child = HatNote::buildHatId(admin, 1);
    assert(!HatNote::isLocalTopHat(child), "child should not be tophat");
}

#[test]
unconstrained fn test_build_hat_id_chain_preserves_admin() {
    let admin = zero();
    let mut current = HatNote::buildHatId(admin, 1);
    for _i in 0..13 {
        let next = HatNote::buildHatId(current, 1);
        assert(next.ne(current), "next should be different from current");
        current = next;
    }
}

#[test]
unconstrained fn test_different_hats_different_ids() {
    let admin = HatNote::buildHatId(zero(), 1);
    let child1 = HatNote::buildHatId(admin, 1);
    let child2 = HatNote::buildHatId(admin, 2);
    let child255 = HatNote::buildHatId(admin, 255);

    assert(child1.ne(child2), "child1 != child2");
    assert(child2.ne(child255), "child2 != child255");
    assert(child1.ne(child255), "child1 != child255");
}

#[test]
unconstrained fn test_max_level_reached() {
    let admin = zero();
    let mut current = HatNote::buildHatId(admin, 1);
    for _i in 0..13 {
        current = HatNote::buildHatId(current, 1);
    }
    let level = HatNote::getLocalHatLevel(current);
    assert(level == 14, "max level should be 14");
}

#[test]
unconstrained fn test_level_14_is_tophat() {
    let admin = zero();
    let mut current = HatNote::buildHatId(admin, 1);
    for _i in 0..13 {
        current = HatNote::buildHatId(current, 1);
    }
    let is_tophat = HatNote::isLocalTopHat(current);
    assert(!is_tophat, "level 14 should not be tophat");
}
