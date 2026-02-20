use aztec::{
    context::PrivateContext,
    macros::notes::custom_note,
    note::note_interface::NoteHash,
    protocol::{
        address::AztecAddress,
        constants::{DOM_SEP__NOTE_HASH, DOM_SEP__NOTE_NULLIFIER},
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Hash, Packable, Serialize, ToField},
    },
};

use crate::types::U256::U256;
use dep::bignum::BigNum;

#[derive(Eq, Serialize, Packable)]
#[custom_note]
pub struct HatNote {
    pub mem_contract: AztecAddress,
    pub eligibility: AztecAddress,
    pub maxSupply: u32,
    pub supply: u32,
    pub lastHatId: u16,
    pub toggle: AztecAddress,
    pub config: u16,
    pub token_id: Field,
    pub hatted: AztecAddress,
}

impl NoteHash for HatNote {
    fn compute_note_hash(
        self,
        owner: AztecAddress,
        storage_slot: Field,
        randomness: Field,
    ) -> Field {
        let input = self.pack().concat([storage_slot, randomness, owner.to_field()]);
        poseidon2_hash_with_separator(input, DOM_SEP__NOTE_HASH)
    }

    fn compute_nullifier(
        self,
        _context: &mut PrivateContext,
        owner: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_for_nullification, owner.to_field()],
            DOM_SEP__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(
        self,
        owner: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Option<Field> {
        Option::some(poseidon2_hash_with_separator(
            [note_hash_for_nullification, owner.to_field()],
            DOM_SEP__NOTE_NULLIFIER,
        ))
    }
}

impl HatNote {
    pub fn new(
        mem_contract: AztecAddress,
        eligibility: AztecAddress,
        maxSupply: u32,
        supply: u32,
        lastHatId: u16,
        toggle: AztecAddress,
        config: u16,
        token_id: Field,
        hatted: AztecAddress,
    ) -> Self {
        Self {
            mem_contract,
            eligibility,
            maxSupply,
            supply,
            lastHatId,
            toggle,
            config,
            token_id,
            hatted,
        }
    }

    pub fn get_token_id(self) -> Field {
        self.token_id
    }

    pub fn buildHatId(admin: U256, newHat: u16) -> U256 {
        let TOPHAT_ADDRESS_SPACE: u32 = 32;
        let LOWER_LEVEL_ADDRESS_SPACE: u32 = 16;
        let MAX_LEVELS: u32 = 14;

        let i0_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 0);
        let mask0 = U256::mask_lower(256 - i0_bits);
        let masked0 = admin.bitand(mask0);

        if masked0.is_zero() {
            let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 0);
            let newHat_shifted = U256::from_u16(newHat).lshift(shift);
            admin.bitor(newHat_shifted)
        } else {
            let i1_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 1);
            let mask1 = U256::mask_lower(256 - i1_bits);
            let masked1 = admin.bitand(mask1);

            if masked1.is_zero() {
                let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 1);
                let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                admin.bitor(newHat_shifted)
            } else {
                let i2_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 2);
                let mask2 = U256::mask_lower(256 - i2_bits);
                let masked2 = admin.bitand(mask2);

                if masked2.is_zero() {
                    let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 2);
                    let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                    admin.bitor(newHat_shifted)
                } else {
                    let i3_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 3);
                    let mask3 = U256::mask_lower(256 - i3_bits);
                    let masked3 = admin.bitand(mask3);

                    if masked3.is_zero() {
                        let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 3);
                        let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                        admin.bitor(newHat_shifted)
                    } else {
                        let i4_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 4);
                        let mask4 = U256::mask_lower(256 - i4_bits);
                        let masked4 = admin.bitand(mask4);

                        if masked4.is_zero() {
                            let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 4);
                            let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                            admin.bitor(newHat_shifted)
                        } else {
                            let i5_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 5);
                            let mask5 = U256::mask_lower(256 - i5_bits);
                            let masked5 = admin.bitand(mask5);

                            if masked5.is_zero() {
                                let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 5);
                                let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                admin.bitor(newHat_shifted)
                            } else {
                                let i6_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 6);
                                let mask6 = U256::mask_lower(256 - i6_bits);
                                let masked6 = admin.bitand(mask6);

                                if masked6.is_zero() {
                                    let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 6);
                                    let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                    admin.bitor(newHat_shifted)
                                } else {
                                    let i7_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 7);
                                    let mask7 = U256::mask_lower(256 - i7_bits);
                                    let masked7 = admin.bitand(mask7);

                                    if masked7.is_zero() {
                                        let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 7);
                                        let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                        admin.bitor(newHat_shifted)
                                    } else {
                                        let i8_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 8);
                                        let mask8 = U256::mask_lower(256 - i8_bits);
                                        let masked8 = admin.bitand(mask8);

                                        if masked8.is_zero() {
                                            let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 8);
                                            let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                            admin.bitor(newHat_shifted)
                                        } else {
                                            let i9_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 9);
                                            let mask9 = U256::mask_lower(256 - i9_bits);
                                            let masked9 = admin.bitand(mask9);

                                            if masked9.is_zero() {
                                                let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 9);
                                                let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                                admin.bitor(newHat_shifted)
                                            } else {
                                                let i10_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 10);
                                                let mask10 = U256::mask_lower(256 - i10_bits);
                                                let masked10 = admin.bitand(mask10);

                                                if masked10.is_zero() {
                                                    let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 10);
                                                    let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                                    admin.bitor(newHat_shifted)
                                                } else {
                                                    let i11_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 11);
                                                    let mask11 = U256::mask_lower(256 - i11_bits);
                                                    let masked11 = admin.bitand(mask11);

                                                    if masked11.is_zero() {
                                                        let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 11);
                                                        let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                                        admin.bitor(newHat_shifted)
                                                    } else {
                                                        let i12_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 12);
                                                        let mask12 = U256::mask_lower(256 - i12_bits);
                                                        let masked12 = admin.bitand(mask12);

                                                        if masked12.is_zero() {
                                                            let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 12);
                                                            let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                                            admin.bitor(newHat_shifted)
                                                        } else {
                                                            let i13_bits = TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * 13);
                                                            let mask13 = U256::mask_lower(256 - i13_bits);
                                                            let masked13 = admin.bitand(mask13);

                                                            if masked13.is_zero() {
                                                                let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - 13);
                                                                let newHat_shifted = U256::from_u16(newHat).lshift(shift);
                                                                admin.bitor(newHat_shifted)
                                                            } else {
                                                                admin
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn getLocalHatLevel(hatId: U256) -> u32 {
        let level0_mask = U256::mask_lower(224);
        let masked0 = hatId.bitand(level0_mask);
        if masked0.is_zero() {
            0
        } else {
            let level1_mask = U256::mask_lower(208);
            let masked1 = hatId.bitand(level1_mask);
            if masked1.is_zero() {
                1
            } else {
                let level2_mask = U256::mask_lower(192);
                let masked2 = hatId.bitand(level2_mask);
                if masked2.is_zero() {
                    2
                } else {
                    let level3_mask = U256::mask_lower(176);
                    let masked3 = hatId.bitand(level3_mask);
                    if masked3.is_zero() {
                        3
                    } else {
                        let level4_mask = U256::mask_lower(160);
                        let masked4 = hatId.bitand(level4_mask);
                        if masked4.is_zero() {
                            4
                        } else {
                            let level5_mask = U256::mask_lower(144);
                            let masked5 = hatId.bitand(level5_mask);
                            if masked5.is_zero() {
                                5
                            } else {
                                let level6_mask = U256::mask_lower(128);
                                let masked6 = hatId.bitand(level6_mask);
                                if masked6.is_zero() {
                                    6
                                } else {
                                    let level7_mask = U256::mask_lower(112);
                                    let masked7 = hatId.bitand(level7_mask);
                                    if masked7.is_zero() {
                                        7
                                    } else {
                                        let level8_mask = U256::mask_lower(96);
                                        let masked8 = hatId.bitand(level8_mask);
                                        if masked8.is_zero() {
                                            8
                                        } else {
                                            let level9_mask = U256::mask_lower(80);
                                            let masked9 = hatId.bitand(level9_mask);
                                            if masked9.is_zero() {
                                                9
                                            } else {
                                                let level10_mask = U256::mask_lower(64);
                                                let masked10 = hatId.bitand(level10_mask);
                                                if masked10.is_zero() {
                                                    10
                                                } else {
                                                    let level11_mask = U256::mask_lower(48);
                                                    let masked11 = hatId.bitand(level11_mask);
                                                    if masked11.is_zero() {
                                                        11
                                                    } else {
                                                        let level12_mask = U256::mask_lower(32);
                                                        let masked12 = hatId.bitand(level12_mask);
                                                        if masked12.is_zero() {
                                                            12
                                                        } else {
                                                            let level13_mask = U256::mask_lower(16);
                                                            let masked13 = hatId.bitand(level13_mask);
                                                            if masked13.is_zero() {
                                                                13
                                                            } else {
                                                                14
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn isLocalTopHat(hatId: U256) -> bool {
        let is_zero = hatId.is_zero();
        let level = HatNote::getLocalHatLevel(hatId);
        (level == 1) & !is_zero
    }

    pub fn getTopHatDomain(hatId: U256) -> u32 {
        let limbs = hatId.get_limbs();
        let domain = ((limbs[1] >> 96) as u32);
        domain
    }

    pub fn getAdminAtLocalLevel(hatId: U256, level: u32) -> U256 {
        let LOWER_LEVEL_ADDRESS_SPACE: u32 = 16;
        let MAX_LEVELS: u32 = 14;
        let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - level);
        let mask = U256::mask_upper(shift);
        hatId.bitand(mask)
    }

    pub fn isValidHatId(hatId: U256) -> bool {
        let LOWER_LEVEL_ADDRESS_SPACE: u32 = 16;
        let MAX_LEVELS: u32 = 14;

        if HatNote::isLocalTopHat(hatId) {
            true
        } else {
            let level = HatNote::getLocalHatLevel(hatId);

            let mut valid = true;
            for i in 1..level {
                let shift = LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - i);
                let truncated = hatId.rshift(shift);
                let lowest_16_bits = truncated.get_limbs()[0] & 0xFFFF;
                if lowest_16_bits == 0 {
                    valid = false;
                }
            }

            valid
        }
    }
}
