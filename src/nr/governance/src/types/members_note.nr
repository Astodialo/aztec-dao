use aztec::{
    context::private_context::PrivateContext,
    macros::notes::custom_note,
    note::note_interface::NoteHash,
    oracle::random::random,
    protocol_types::{
        address::AztecAddress,
        constants::{GENERATOR_INDEX__NOTE_HASH, GENERATOR_INDEX__NOTE_NULLIFIER},
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Packable, Serialize, ToField},
    },
};

#[derive(Eq, Serialize, Deserialize, Packable)]
#[custom_note]
pub struct MembersNote {
    pub gov_contract: AztecAddress,
    pub members: [Field; 10],
    pub randomness: Field,
}

impl NoteHash for MembersNote {
    fn compute_note_hash(self, storage_slot: Field) -> Field {
        let secret = self.pack().concat([storage_slot]);
        poseidon2_hash_with_separator(secret, GENERATOR_INDEX__NOTE_HASH)
    }

    fn compute_nullifier(self, _: &mut PrivateContext, note_hash_to_nullify: Field) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, self.gov_contract.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(self, note_hash_to_nullify: Field) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, self.gov_contract.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }
}

impl MembersNote {
    pub fn new(gov_contract: AztecAddress, members: [Field; 10]) -> Self {
        // Safety: Using random() is safe here as it's for generating randomness for note uniqueness
        let randomness = unsafe { random() };
        MembersNote { gov_contract, members, randomness }
    }
}
