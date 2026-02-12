use aztec::{
    context::private_context::PrivateContext,
    macros::notes::note,
    note::note_interface::NoteHash,
    protocol_types::{
        address::AztecAddress,
        constants::{GENERATOR_INDEX__NOTE_HASH, GENERATOR_INDEX__NOTE_NULLIFIER},
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Packable, Serialize, ToField},
    },
};

#[derive(Eq, Serialize, Deserialize, Packable)]
#[note]
pub struct MembersNote {
    //pub gov_contract: AztecAddress,
    pub members: [Field; 10],
}


impl MembersNote {
    pub fn new(members: [Field; 10]) -> Self {
        MembersNote { members }
    }
}
