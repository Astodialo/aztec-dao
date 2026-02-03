use aztec::{
    context::{PrivateContext, PublicContext},
    keys::getters::{get_nsk_app, get_public_keys},
    macros::notes::custom_note,
    messages::logs::note,
    note::note_interface::{NoteHash, NoteType},
    oracle::random::random,
    protocol_types::{
        address::AztecAddress,
        constants::{
            GENERATOR_INDEX__NOTE_HASH, GENERATOR_INDEX__NOTE_NULLIFIER,
            GENERATOR_INDEX__PARTIAL_NOTE_VALIDITY_COMMITMENT,
        },
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Hash, Packable, Serialize, ToField},
    },
};

// NFTNote supports partial notes, i.e. the ability to create an incomplete note in private, hiding certain values (the
// hatted, storage slot and randomness), and then completing the note in public with the ones missing (the token id).
// Partial notes are being actively developed and are not currently fully supported via macros, and so we rely on the
// #[custom_note] macro to implement it manually, resulting in some boilerplate. This is expected to be unnecessary once
// macro support is expanded.

// docs:start:nft_note
/// A private note representing a token id associated to an account.
#[derive(Eq, Serialize, Packable)]
#[custom_note]
pub struct HatNote {
    pub mem_contract: AztecAddress,
    // The ordering of these fields is important given that it must:
    //   a) match that of NFTPartialNotePrivateContent, and
    //   b) have the public field at the end
    // Correct ordering is checked by the tests in this module.

    // Module that rules on wearer eligibiliy and standing
    pub eligibility: AztecAddress,
    // The max number of hats with this id that can exist
    pub maxSupply: u32,
    // The number of this hat that currently exist
    pub supply: u32,
    // Indexes how many different child hats an admin has
    pub lastHatId: u16,
    // Module that sets the hat's status
    pub toggle: AztecAddress,

    // Holds status and other settings, with this bitwise schema:
    //
    //  0th bit  | `active` status; can be altered by toggle
    //  1        | `mutable` setting
    //  2 - 15   | unassigned
    pub config: u16,

    /// The ID of the token represented by this note.
    pub token_id: Field,
    /// The hatted of the note, i.e. the account whose nullifier secret key is required to compute the nullifier.
    pub hatted: AztecAddress,
}
// docs:end:nft_note

impl NoteHash for HatNote {
    fn compute_note_hash(
        self,
        owner: AztecAddress,
        storage_slot: Field,
        randomness: Field,
    ) -> Field {
        // You likely want to use all fields, including the passed-in mem_contract and randomness
        let input = self.pack().concat([storage_slot, randomness, owner.to_field()]);
        poseidon2_hash_with_separator(input, GENERATOR_INDEX__NOTE_HASH)
    }

    fn compute_nullifier(
        self,
        _context: &mut PrivateContext,
        owner: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_for_nullification, owner.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(
        self,
        owner: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_for_nullification, owner.to_field()],
            GENERATOR_INDEX__NOTE_NULLIFIER,
        )
    }
}
//impl NoteHash for HatNote {
//    fn compute_note_hash(self, storage_slot: Field) -> Field {
//        let secret = self.pack().concat([storage_slot]);
//        poseidon2_hash_with_separator(secret, GENERATOR_INDEX__NOTE_HASH)
//    }
//
//    fn compute_nullifier(self, _: &mut PrivateContext, note_hash_to_nullify: Field) -> Field {
//        poseidon2_hash_with_separator(
//            [note_hash_to_nullify, self.mem_contract.to_field()],
//            GENERATOR_INDEX__NOTE_NULLIFIER,
//       )
//  }
//
//   unconstrained fn compute_nullifier_unconstrained(self, note_hash_to_nullify: Field) -> Field {
//       poseidon2_hash_with_separator(
//          [note_hash_to_nullify, self.mem_contract.to_field()],
//            GENERATOR_INDEX__NOTE_NULLIFIER,
//        )
//    }
//}

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
}
