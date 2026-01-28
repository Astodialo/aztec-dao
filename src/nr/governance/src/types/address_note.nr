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
pub struct AddressNote {
    pub address: AztecAddress,
    pub randomness: Field,
}

impl NoteHash for AddressNote {
    fn compute_note_hash(self, storage_slot: Field) -> Field {
        let secret = self.pack().concat([storage_slot]);
        poseidon2_hash_with_separator(secret, GENERATOR_INDEX__NOTE_HASH)
    }

    fn compute_nullifier(self, _: &mut PrivateContext, note_hash_to_nullify: Field) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, self.address.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(self, note_hash_to_nullify: Field) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, self.address.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }
}

impl AddressNote {
    pub fn new(address: AztecAddress) -> Self {
        // Safety: Using random() is safe here as it's for generating randomness for note uniqueness
        let randomness = unsafe { random() };
        AddressNote { address, randomness }
    }
}
