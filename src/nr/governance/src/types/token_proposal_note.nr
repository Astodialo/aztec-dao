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
pub struct TokenProposalNote {
    pub gov_contract: AztecAddress,
    pub proposal_id: Field,
    pub token: AztecAddress,
    pub amount: u128,
    pub nft: bool,
    pub nft_token_id: Field,
    pub recipient: AztecAddress,
    pub final: bool,
    pub votes_for: Field,
    pub votes_against: Field,
    pub randomness: Field,
}

impl NoteHash for TokenProposalNote {
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

impl TokenProposalNote {
    pub fn new(
        gov_contract: AztecAddress,
        proposal_id: Field,
        token: AztecAddress,
        amount: u128,
        nft: bool,
        nft_token_id: Field,
        recipient: AztecAddress,
    ) -> Self {
        // Safety: Using random() is safe here as it's for generating randomness for note uniqueness
        let randomness = unsafe { random() };
        TokenProposalNote {
            gov_contract,
            proposal_id,
            token,
            amount,
            nft,
            nft_token_id,
            recipient,
            final: false,
            votes_for: 0,
            votes_against: 0,
            randomness,
        }
    }

    pub fn vote(self, choice: u32) -> Self {
        // Safety: Using random() is safe here as it's for generating randomness for note uniqueness
        let randomness = unsafe { random() };

        let (new_votes_for, new_votes_against) = if choice == 0 {
            (self.votes_for, self.votes_against + 1)
        } else if choice == 1 {
            (self.votes_for + 1, self.votes_against)
        } else {
            assert(false, "Invalid choice");
            (self.votes_for, self.votes_against)
        };

        TokenProposalNote {
            gov_contract: self.gov_contract,
            proposal_id: self.proposal_id,
            token: self.token,
            amount: self.amount,
            nft: self.nft,
            nft_token_id: self.nft_token_id,
            recipient: self.recipient,
            final: false,
            votes_for: new_votes_for,
            votes_against: new_votes_against,
            randomness,
        }
    }
}
