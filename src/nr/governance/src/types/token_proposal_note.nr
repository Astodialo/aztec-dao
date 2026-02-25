use aztec::{
    context::PrivateContext,
    macros::notes::custom_note,
    note::note_interface::NoteHash,
    protocol::{
        address::AztecAddress,
        constants::{DOM_SEP__NOTE_HASH, DOM_SEP__NOTE_NULLIFIER},
        hash::poseidon2_hash_with_separator,
        traits::{Deserialize, Packable, Serialize, ToField},
    },
};

#[derive(Eq, Serialize, Deserialize, Packable)]
#[custom_note]
pub struct TokenProposalNote {
    //pub gov_contract: AztecAddress,
    pub proposal_id: Field,
    pub token: AztecAddress,
    pub amount: u128,
    pub nft_token_id: Field,
    pub recipient: AztecAddress,
    pub final: bool,
    pub threshold: u32,
    pub votes_for: u32,
    pub votes_against: u32,
}

impl NoteHash for TokenProposalNote {
    fn compute_note_hash(
        self,
        owner: AztecAddress,
        storage_slot: Field,
        randomness: Field,
    ) -> Field {
        let secret = self.pack().concat([storage_slot, randomness, owner.to_field()]);
        poseidon2_hash_with_separator(secret, DOM_SEP__NOTE_HASH)
    }

    fn compute_nullifier(
        self,
        _: &mut PrivateContext,
        owner: AztecAddress,
        note_hash_to_nullify: Field,
    ) -> Field {
        poseidon2_hash_with_separator(
            [note_hash_to_nullify, owner.to_field()],
            DOM_SEP__NOTE_NULLIFIER,
        )
    }

    unconstrained fn compute_nullifier_unconstrained(
        self,
        owner: AztecAddress,
        note_hash_to_nullify: Field,
    ) -> Option<Field> {
        Option::some(poseidon2_hash_with_separator(
            [note_hash_to_nullify, owner.to_field()],
            DOM_SEP__NOTE_NULLIFIER,
        ))
    }
}

impl TokenProposalNote {
    pub fn new(
        //gov_contract: AztecAddress,
        proposal_id: Field,
        token: AztecAddress,
        amount: u128,
        nft_token_id: Field,
        recipient: AztecAddress,
        threshold: u32,
    ) -> Self {
        TokenProposalNote {
            //  gov_contract,
            proposal_id,
            token,
            amount,
            nft_token_id,
            recipient,
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

        TokenProposalNote {
            //gov_contract: self.gov_contract,
            proposal_id: self.proposal_id,
            token: self.token,
            amount: self.amount,
            nft_token_id: self.nft_token_id,
            recipient: self.recipient,
            final: false,
            threshold: self.threshold,
            votes_for: new_votes_for,
            votes_against: new_votes_against,
        }
    }
}
