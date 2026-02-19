use dep::bignum::{BigNum, derive_bignum, fields::U256::U256_PARAMS};

#[derive_bignum(3, 257, quote {U256_PARAMS})]
pub struct U256 {
    limbs: [u128; 3],
}

impl U256 {
    pub fn zero() -> Self {
        Self { limbs: [0, 0, 0] }
    }

    pub fn from_limbs(limbs: [u128; 3]) -> Self {
        Self { limbs }
    }

    pub fn from_u16(value: u16) -> Self {
        Self { limbs: [value as u128, 0, 0] }
    }

    pub fn from_u32(value: u32) -> Self {
        Self { limbs: [value as u128, 0, 0] }
    }

    pub fn from_u64(value: u64) -> Self {
        Self { limbs: [value as u128, 0, 0] }
    }

    pub fn from_u128(value: u128) -> Self {
        Self { limbs: [value, 0, 0] }
    }

    pub fn from_field(value: Field) -> Self {
        Self { limbs: [value as u128, 0, 0] }
    }

    //pub fn to_field(self) -> Field {
    //    let bignum = U256::from_limbs(self.limbs);
    //    bignum.to_field()
    //}

    pub fn is_zero(self) -> bool {
        (self.limbs[0] == 0) & (self.limbs[1] == 0) & (self.limbs[2] == 0)
    }

    pub fn eq(self, other: Self) -> bool {
        (self.limbs[0] == other.limbs[0])
            & (self.limbs[1] == other.limbs[1])
            & (self.limbs[2] == other.limbs[2])
    }

    pub fn ne(self, other: Self) -> bool {
        !self.eq(other)
    }

    pub fn lt(self, other: Self) -> bool {
        if self.limbs[2] != other.limbs[2] {
            self.limbs[2] < other.limbs[2]
        } else if self.limbs[1] != other.limbs[1] {
            self.limbs[1] < other.limbs[1]
        } else {
            self.limbs[0] < other.limbs[0]
        }
    }

    pub fn gt(self, other: Self) -> bool {
        other.lt(self)
    }

    pub fn from_u256(value: Field) -> Self {
        Self { limbs: [value as u128, 0, 0] }
    }

    pub fn to_field(self) -> Field {
        self.limbs[0] as Field
    }

    pub fn lshift(self, shift: u32) -> Self {
        let limb_bits: u32 = 128;
        
        let limb_shift = shift / limb_bits;
        let bit_shift = shift % limb_bits;
        
        let mut result = [0 as u128; 3];
        
        if shift == 0 {
            result = self.limbs;
        } else if bit_shift == 0 {
            for i in 0..3 {
                if i >= limb_shift {
                    result[i] = self.limbs[i - limb_shift];
                }
            }
        } else {
            for i in 0..3 {
                let mut val: u128 = 0;
                
                if i >= limb_shift {
                    val = self.limbs[i - limb_shift] << bit_shift as u128;
                }
                
                if i > 0 & (i > limb_shift) {
                    let shift_amount = (limb_bits - bit_shift) as u128;
                    let carry = self.limbs[i - limb_shift - 1] >> shift_amount;
                    val = val | carry;
                }
                
                result[i] = val;
            }
        }

        let bignum = U256::from_limbs(result);
        Self { limbs: bignum.limbs }
    }

    pub fn rshift(self, shift: u32) -> Self {
        let limb_bits: u32 = 128;
        
        let limb_shift = shift / limb_bits;
        let bit_shift = shift % limb_bits;
        
        let mut result = [0 as u128; 3];
        
        if shift == 0 {
            result = self.limbs;
        } else if bit_shift == 0 {
            for i in 0..3 {
                if i + limb_shift < 3 {
                    result[i] = self.limbs[i + limb_shift];
                }
            }
        } else {
            for i in 0..3 {
                let mut val: u128 = 0;
                
                if i + limb_shift < 3 {
                    val = self.limbs[i + limb_shift] >> bit_shift as u128;
                }
                
                if i + limb_shift + 1 < 3 {
                    let shift_amount = (limb_bits - bit_shift) as u128;
                    let carry = self.limbs[i + limb_shift + 1] << shift_amount;
                    val = val | carry;
                }
                
                result[i] = val;
            }
        }

        Self { limbs: result }
    }

    pub fn bitand(self, other: Self) -> Self {
        Self {
            limbs: [
                self.limbs[0] & other.limbs[0],
                self.limbs[1] & other.limbs[1],
                self.limbs[2] & other.limbs[2],
            ],
        }
    }

    pub fn bitor(self, other: Self) -> Self {
        Self {
            limbs: [
                self.limbs[0] | other.limbs[0],
                self.limbs[1] | other.limbs[1],
                self.limbs[2] | other.limbs[2],
            ],
        }
    }

    pub fn mask_lower(bits: u32) -> Self {
        if bits == 0 {
            Self::zero()
        } else if bits < 128 {
            let mask = (1 as u128 << bits as u128) - 1;
            Self { limbs: [mask, 0, 0] }
        } else if bits == 128 {
            let mask: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            Self { limbs: [mask, 0, 0] }
        } else if bits <= 256 {
            let lower_bits = bits - 128;
            let mask1: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask2 = if lower_bits == 0 {
                0
            } else {
                (1 as u128 << lower_bits as u128) - 1
            };
            Self { limbs: [mask1, mask2, 0] }
        } else if bits <= 384 {
            let lower_bits = bits - 256;
            let mask1: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask2: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask3 = if lower_bits == 0 {
                0
            } else {
                (1 as u128 << lower_bits as u128) - 1
            };
            Self { limbs: [mask1, mask2, mask3] }
        } else {
            Self {
                limbs: [
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                ],
            }
        }
    }

    pub fn mask_upper(bits: u32) -> Self {
        if bits == 0 {
            Self::zero()
        } else if bits <= 128 {
            let lower_zero_bits = 128 - bits;
            let mask = if lower_zero_bits == 0 {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF as u128
            } else {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << (lower_zero_bits as u128)
            };
            Self { limbs: [mask, 0, 0] }
        } else if bits <= 256 {
            let lower_zero_bits = 256 - bits;
            let mask1: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask2 = if lower_zero_bits == 0 {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF as u128
            } else {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << (lower_zero_bits as u128)
            };
            Self { limbs: [mask1, mask2, 0] }
        } else if bits <= 384 {
            let lower_zero_bits = 384 - bits;
            let mask1: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask2: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            let mask3 = if lower_zero_bits == 0 {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF as u128
            } else {
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << (lower_zero_bits as u128)
            };
            Self { limbs: [mask1, mask2, mask3] }
        } else {
            Self {
                limbs: [
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                ],
            }
        }
    }
}
