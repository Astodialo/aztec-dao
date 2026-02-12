use aztec::{
    context::private_context::PrivateContext,
    macros::notes::custom_note,
    note::note_interface::NoteHash,
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
}

impl NoteHash for AddressNote {
    fn compute_note_hash(
        self,
        owner: AztecAddress,
        storage_slot: Field,
        randomness: Field,
    ) -> Field {
        let secret = self.pack().concat([storage_slot, randomness, owner.to_field()]);
        poseidon2_hash_with_separator(secret, GENERATOR_INDEX__NOTE_HASH)
    }

    fn compute_nullifier(
        self,
        _context: &mut PrivateContext,
        owner: AztecAddress,
        note_hash_to_nullify: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, owner.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(
        self,
        owner: AztecAddress,
        note_hash_to_nullify: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, owner.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }
}

impl AddressNote {
    pub fn new(address: AztecAddress) -> Self {
        AddressNote { address }
    }
}
