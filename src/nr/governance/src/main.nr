use dep::aztec::macros::aztec;
pub mod types;

#[aztec]
contract Governance {
    use crate::types::member_proposal_note::MemberProposalNote;
    use crate::types::members_note::MembersNote;
    use crate::types::token_proposal_note::TokenProposalNote;
    use address_note::AddressNote;
    use aztec::context::PrivateContext;
    use aztec::keys::getters::get_public_keys;
    use aztec::{
        macros::{functions::{external, initializer}, storage::storage},
        note::{
            note_getter_options::NoteGetterOptions, note_interface::NoteProperties,
            note_viewer_options::NoteViewerOptions,
        },
        protocol::{address::AztecAddress, hash::poseidon2_hash, traits::Hash},
        state_vars::{Owned, PrivateMutable, PrivateSet},
        utils::comparison::Comparator,
    };
    use aztec::messages::message_delivery::MessageDelivery;
    use field_note::FieldNote;

    use members::Members;
    use treasury::Treasury;

    #[storage]
    struct Storage<Context> {
        //members: Owned<PrivateMutable<MembersNote, Context>, Context>,
        treasury: Owned<PrivateMutable<AddressNote, Context>, Context>,
        mem_contract: Owned<PrivateMutable<AddressNote, Context>, Context>,
        last_proposal_id: Owned<PrivateMutable<FieldNote, Context>, Context>,
        token_proposals: Owned<PrivateSet<TokenProposalNote, Context>, Context>,
        member_proposals: Owned<PrivateSet<MemberProposalNote, Context>, Context>,
    }

    /// Initialize the contract, with and admin.
    /// admin: Is the 0th index in the members list.
    /// last proposal id is initialized to 0 and incremented after each proposal.
    #[external("private")]
    #[initializer]
    fn constructor(admin: AztecAddress) {
        //assert(!admin.is_zero(), "invalid admin");
        let this_address = self.context.this_address();
        let count_note = FieldNote { value: 0 };

        self.storage.last_proposal_id.at(this_address).initialize(count_note).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[external("private")]
    fn add_mem_contract(members_addr: AztecAddress) {
        let this_address = self.context.this_address();
        let members_note = AddressNote { address: members_addr };

        self.storage.mem_contract.at(this_address).initialize(members_note).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[external("private")]
    fn add_treasury(treasury_addr: AztecAddress) {
        let this_address = self.context.this_address();
        let treasury_note = AddressNote { address: treasury_addr };

        self.storage.treasury.at(this_address).initialize(treasury_note).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[external("private")]
    fn create_member_proposal(add: bool, member: AztecAddress, threshold: u32) {
        _authorize(self.context, self.storage);

        let this_address = self.context.this_address();

        self
            .storage
            .last_proposal_id
            .at(this_address)
            .replace(|note| {
                let count = note.value;
                let proposal = MemberProposalNote::new(this_address, count, add, member, threshold);
                self.storage.member_proposals.at(this_address).insert(proposal).deliver(
                    MessageDelivery.ONCHAIN_CONSTRAINED,
                );
                FieldNote { value: count + 1 }
            })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("private")]
    fn create_token_proposal(
        token: AztecAddress,
        amount: u128,
        nft: bool,
        nft_token_id: Field,
        recipient: AztecAddress,
        threshold: u32,
    ) {
        _authorize(self.context, self.storage);

        let this_address = self.context.this_address();

        self
            .storage
            .last_proposal_id
            .at(this_address)
            .replace(|note| {
                let count = note.value;
                let proposal = TokenProposalNote::new(
                    count,
                    token,
                    amount,
                    nft,
                    nft_token_id,
                    recipient,
                    threshold,
                );
                self.storage.token_proposals.at(this_address).insert(proposal).deliver(
                    MessageDelivery.ONCHAIN_CONSTRAINED,
                );
                FieldNote { value: count + 1 }
            })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("private")]
    fn cast_vote(proposal_id: Field, choice: u32) {
        _authorize(self.context, self.storage);

        let this_address = self.context.this_address();

        // Find the proposal
        let options = NoteGetterOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let token_prop_notes = self.storage.token_proposals.at(this_address).pop_notes(options);

        if token_prop_notes.len() == 0 {
            let options = NoteGetterOptions::new().select(
                MemberProposalNote::properties().proposal_id,
                Comparator.EQ,
                proposal_id,
            );

            let member_prop_notes =
                self.storage.member_proposals.at(this_address).pop_notes(options);

            assert(member_prop_notes.len() == 1, "Proposal not found");

            let retrieved_note = member_prop_notes.get_unchecked(0);

            assert(!retrieved_note.final, "Proposal finalized");
            // Use the vote method to update tally
            let mut updated_proposal = retrieved_note.vote(choice);

            if updated_proposal.votes_for >= updated_proposal.threshold {
                updated_proposal.final = true;
            }
            if updated_proposal.votes_against >= updated_proposal.threshold {
                updated_proposal.final = true;
            }

            self.storage.member_proposals.at(this_address).insert(updated_proposal).deliver(
                MessageDelivery.ONCHAIN_CONSTRAINED,
            );
        } else {
            assert(token_prop_notes.len() == 1, "Proposal not found");

            let retrieved_note = token_prop_notes.get_unchecked(0);

            assert(!retrieved_note.final, "Proposal finalized");
            // Use the vote method to update tally
            let mut updated_proposal = retrieved_note.vote(choice);

            if updated_proposal.votes_for >= updated_proposal.threshold {
                updated_proposal.final = true;
            }
            if updated_proposal.votes_against >= updated_proposal.threshold {
                updated_proposal.final = true;
            }

            //if cmp.max(updated_proposal.votes_for, updated_proposal.votes_against) >= updated_proposal.threshold {
            //    updated_proposal.final = true;
            //}

            self.storage.token_proposals.at(this_address).insert(updated_proposal).deliver(
                MessageDelivery.ONCHAIN_CONSTRAINED,
            );
        }

        // Create nullifier to prevent double voting
        let msg_sender_npk_hash = get_public_keys(self.msg_sender()).npk_m.hash();
        let secret = self.context.request_nhk_app(msg_sender_npk_hash);
        let nullifier = poseidon2_hash([proposal_id, secret]);
        self.context.push_nullifier(nullifier);
    }

    #[external("private")]
    fn add_member(
        eligibility: AztecAddress,
        maxsupply: u32,
        supply: u32,
        lasthatid: u16,
        toggle: AztecAddress,
        config: u16,
        token_id: Field,
        proposal_id: Field,
    ) {
        _authorize(self.context, self.storage);

        let this_address = self.context.this_address();

        let mem_contract_note = self.storage.mem_contract.at(this_address).replace(|note| note);
        let mem_contract = mem_contract_note.get_note().address;

        let options = NoteGetterOptions::new().select(
            MemberProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes = self.storage.member_proposals.at(this_address).pop_notes(options);
        assert(notes.len() == 1, "Proposal not found");

        let retrieved_note = notes.get_unchecked(0);

        assert(retrieved_note.final, "Proposal not finalized");

        assert(retrieved_note.add, "Tis a remove proposal");

        let member = retrieved_note.member;

        Members::at(mem_contract)
            .add_member(eligibility, maxsupply, supply, lasthatid, toggle, config, token_id, member)
            .call(self.context);

        mem_contract_note.deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("private")]
    fn remove_member(proposal_id: Field) {
        _authorize(self.context, self.storage);

        let this_address = self.context.this_address();

        let mem_contract_note = self.storage.mem_contract.at(this_address).replace(|note| note);
        let mem_contract = mem_contract_note.get_note().address;

        let options = NoteGetterOptions::new().select(
            MemberProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes = self.storage.member_proposals.at(this_address).pop_notes(options);
        assert(notes.len() == 1, "Proposal not found");

        let retrieved_note = notes.get_unchecked(0);

        assert(retrieved_note.final, "Proposal not finalized");

        assert(!retrieved_note.add, "Tis an add proposal");

        let member = retrieved_note.member;

        Members::at(mem_contract).remove_member(member).call(self.context);

        mem_contract_note.deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    /// @notice Withdraws an amount from the treasury's private balance to the
    ///         recipient's private balance, if the proposal is finalized.
    /// @dev Can only be called by a member for now
    #[external("private")]
    fn withdraw(proposal_id: Field) {
        let this_address = self.context.this_address();

        _authorize(self.context, self.storage);

        let options = NoteGetterOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes = self.storage.token_proposals.at(this_address).pop_notes(options);
        assert(notes.len() == 1, "Proposal not found");

        let retrieved_note = notes.get_unchecked(0);

        assert(retrieved_note.final, "Proposal not finalized");

        let token = retrieved_note.token;
        let recipient = retrieved_note.recipient;

        let treasury_note = self.storage.treasury.at(this_address).replace(|note| note);

        let treasury = treasury_note.get_note().address;

        if retrieved_note.nft {
            let nft_token_id = retrieved_note.nft_token_id;
            Treasury::at(treasury).withdraw_nft(token, nft_token_id, recipient).call(self.context);
        } else {
            let amount = retrieved_note.amount;
            Treasury::at(treasury).withdraw(token, amount, recipient).call(self.context);
        }

        treasury_note.deliver(MessageDelivery.ONCHAIN_CONSTRAINED)
    }

    #[contract_library_method]
    fn _authorize(context: &mut PrivateContext, storage: Storage<&mut PrivateContext>) {
        let this_address = context.this_address();

        let mem_contract_note = storage.mem_contract.at(this_address).replace(|note| note);
        let mem_contract = mem_contract_note.get_note().address;

        Members::at(mem_contract).is_a_member(context.maybe_msg_sender().unwrap()).call(context);
        mem_contract_note.deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("utility")]
    unconstrained fn _view_current_id() -> pub Field {
        let note = self.storage.last_proposal_id.at(self.context.this_address()).view_note();
        note.value
    }

    #[external("utility")]
    unconstrained fn _view_mem_contract() -> pub AztecAddress {
        let note = self.storage.mem_contract.at(self.context.this_address()).view_note();
        note.address
    }

    #[external("utility")]
    unconstrained fn _view_treasury() -> pub AztecAddress {
        let note = self.storage.treasury.at(self.context.this_address()).view_note();
        note.address
    }

    #[external("utility")]
    unconstrained fn _view_member_proposal(proposal_id: Field) -> MemberProposalNote {
        let options = NoteViewerOptions::new().select(
            MemberProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes =
            self.storage.member_proposals.at(self.context.this_address()).view_notes(options);
        assert(notes.len() == 1, "Proposal not found");
        notes.get_unchecked(0)
    }

    #[external("utility")]
    unconstrained fn _view_token_proposal(proposal_id: Field) -> TokenProposalNote {
        let options = NoteViewerOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes =
            self.storage.token_proposals.at(self.context.this_address()).view_notes(options);
        assert(notes.len() == 1, "Proposal not found");
        notes.get_unchecked(0)
    }

}
