use dep::aztec::{
    context::private_context::PrivateContext,
    keys::getters::{get_nsk_app, get_public_keys},
    macros::notes::custom_note,
    note::note_interface::NoteHash,
    protocol_types::{
        address::AztecAddress,
        constants::{GENERATOR_INDEX__NOTE_HASH, GENERATOR_INDEX__NOTE_NULLIFIER},
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Hash, Packable, Serialize, ToField},
    },
};

#[derive(Eq, Serialize, Deserialize, Packable)]
#[custom_note]
pub struct ProposalNote {
    // The ID of the proposal
    pub id: Field,
    // The Proposal tally, repressented by option ID and votes
    pub voters: [AztecAddress; 8],
}

impl NoteHash for ProposalNote {
    fn compute_note_hash(
        self,
        owner: AztecAddress,
        storage_slot: Field,
        randomness: Field,
    ) -> Field {
        let input = self.pack().concat([owner.to_field(), storage_slot, randomness]);
        poseidon2_hash_with_separator(input, GENERATOR_INDEX__NOTE_HASH)
    }

    fn compute_nullifier(
        self,
        context: &mut PrivateContext,
        _owner: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Field {
        let voter = context.msg_sender().unwrap();
        let is_voter = self.voters.any(|x| x == voter);
        assert(is_voter, "msg_sender is not a voter");

        let voter_npk_m = get_public_keys(context.msg_sender().unwrap()).npk_m;
        let voter_npk_m_hash = voter_npk_m.hash();
        let secret = context.request_nsk_app(voter_npk_m_hash);
        let input = self.pack().concat([secret, note_hash_for_nullification, self.id]);
        poseidon2_hash_with_separator(input, GENERATOR_INDEX__NOTE_NULLIFIER)
    }

    unconstrained fn compute_nullifier_unconstrained(
        self,
        voter: AztecAddress,
        note_hash_for_nullification: Field,
    ) -> Field {
        let is_voter = self.voters.any(|x| x == voter);
        assert(is_voter, "msg_sender is not a voter");

        let voter_npk_m = get_public_keys(voter).npk_m;
        let voter_npk_m_hash = voter_npk_m.hash();
        let secret = get_nsk_app(voter_npk_m_hash);
        let input = self.pack().concat([secret, note_hash_for_nullification, self.id]);
        poseidon2_hash_with_separator(input, GENERATOR_INDEX__NOTE_NULLIFIER)
    }
}
