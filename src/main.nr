mod notes;
use dep::aztec::macros::aztec;

#[aztec]
pub contract PrivateVoting {
    use crate::notes::ProposalNote;
    use dep::aztec::{
        keys::getters::get_public_keys,
        macros::{functions::{external, initializer, internal}, storage::storage},
    };
    use dep::aztec::protocol_types::{
        address::AztecAddress,
        hash::poseidon2_hash,
        traits::{Hash, ToField},
    };
    use dep::aztec::state_vars::{Map, private_set::PrivateSet, PublicImmutable, PublicMutable};

    #[storage]
    struct Storage<Context> {
        proposals: PrivateSet<ProposalNote, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(admin: AztecAddress) {}
}
