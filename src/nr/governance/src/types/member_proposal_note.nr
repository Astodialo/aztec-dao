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
pub struct MemberProposalNote {
    pub gov_contract: AztecAddress,
    pub proposal_id: Field,
    pub add: bool,
    pub member: AztecAddress,
    pub final: bool,
    pub threshold: u32,
    pub votes_for: u32,
    pub votes_against: u32,
}

impl NoteHash for MemberProposalNote {
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
        _: &mut PrivateContext,
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

impl MemberProposalNote {
    pub fn new(
        gov_contract: AztecAddress,
        proposal_id: Field,
        add: bool,
        member: AztecAddress,
        threshold: u32,
    ) -> Self {
        MemberProposalNote {
            gov_contract,
            proposal_id,
            add,
            member,
            final: false,
            threshold,
            votes_for: 0,
            votes_against: 0,
        }
    }

    pub fn vote(self, choice: u32) -> Self {
        let (new_votes_for, new_votes_against) = if choice == 0 {
            (self.votes_for, self.votes_against + 1)
        } else if choice == 1 {
            (self.votes_for + 1, self.votes_against)
        } else {
            assert(false, "Invalid choice");
            (self.votes_for, self.votes_against)
        };

        MemberProposalNote {
            gov_contract: self.gov_contract,
            proposal_id: self.proposal_id,
            add: self.add,
            member: self.member,
            final: false,
            threshold: self.threshold,
            votes_for: new_votes_for,
            votes_against: new_votes_against,
        }
    }
}
