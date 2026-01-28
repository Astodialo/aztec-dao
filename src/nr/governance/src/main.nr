use dep::aztec::macros::aztec;
pub mod types;

#[aztec]
contract Governance {
    use crate::types::address_note::AddressNote;
    use crate::types::field_note::FieldNote;
    use crate::types::members_note::MembersNote;
    use crate::types::token_proposal_note::TokenProposalNote;
    use aztec::context::{self, private_context::PrivateContext};
    use aztec::keys::getters::get_public_keys;
    use aztec::{
        macros::{functions::{external, initializer}, storage::storage},
        note::{
            note_getter_options::NoteGetterOptions, note_interface::NoteProperties,
            note_viewer_options::NoteViewerOptions,
        },
        protocol_types::{address::AztecAddress, hash::poseidon2_hash, traits::Hash},
        state_vars::{private_mutable::PrivateMutable, private_set::PrivateSet},
        utils::comparison::Comparator,
    };
    use aztec::messages::message_delivery::MessageDelivery;

    use std::ops::Div;
    use treasury::Treasury;

    #[storage]
    struct Storage<Context> {
        members: PrivateMutable<MembersNote, Context>,
        treasury: PrivateMutable<AddressNote, Context>,
        last_proposal_id: PrivateMutable<FieldNote, Context>,
        token_proposals: PrivateSet<TokenProposalNote, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(admin: AztecAddress) {
        //assert(!admin.is_zero(), "invalid admin");
        let mut members = [0; 10];
        members[0] = admin.inner;
        let members_note = MembersNote::new(context.this_address(), members);
        let count_note = FieldNote::new(0, context.this_address());

        storage.last_proposal_id.initialize(count_note).emit(
            context.this_address(),
            MessageDelivery.CONSTRAINED_ONCHAIN,
        );

        storage.members.initialize(members_note).emit(
            context.this_address(),
            MessageDelivery.CONSTRAINED_ONCHAIN,
        );
    }

    #[external("private")]
    fn add_treasury(treasury_addr: AztecAddress) {
        let treasury_note = AddressNote::new(treasury_addr);

        storage.treasury.initialize(treasury_note).emit(
            context.this_address(),
            MessageDelivery.CONSTRAINED_ONCHAIN,
        );
    }

    #[external("private")]
    fn create_proposal(
        token: AztecAddress,
        amount: u128,
        nft: bool,
        nft_token_id: Field,
        recipient: AztecAddress,
    ) {
        _authorized(&mut context, storage);

        storage
            .last_proposal_id
            .replace(|note| {
                let count = note.value();
                let proposal = TokenProposalNote::new(
                    context.this_address(),
                    count,
                    token,
                    amount,
                    nft,
                    nft_token_id,
                    recipient,
                );
                storage.token_proposals.insert(proposal).emit(
                    context.this_address(),
                    MessageDelivery.CONSTRAINED_ONCHAIN,
                );
                let new_count_note = FieldNote::new(count + 1, context.this_address());
                new_count_note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN);
    }

    #[external("private")]
    fn cast_vote(proposal_id: Field, choice: u32) {
        storage
            .members
            .replace(|note| {
                let msg_sender = context.msg_sender().unwrap();
                let mut is_member = false;
                let mut cur_members = 0;

                // Check membership
                for i in 0..10 {
                    if note.members[i] == msg_sender.inner {
                        is_member = true;
                    }
                    if note.members[i] != 0 {
                        cur_members += 1;
                    }
                }
                assert(is_member, "Not a member");

                // Find the proposal
                let options = NoteGetterOptions::new().select(
                    TokenProposalNote::properties().proposal_id,
                    Comparator.EQ,
                    proposal_id,
                );
                let notes = storage.token_proposals.pop_notes(options);
                assert(notes.len() == 1, "Proposal not found");

                // Update the proposal with the vote
                let retrieved_note = notes.get_unchecked(0);

                // Use the vote method to update tally
                let mut updated_proposal = retrieved_note.vote(choice);

                let voters = updated_proposal.votes_for + updated_proposal.votes_against;
                let threshold = if cur_members == 1 {
                    1
                } else {
                    cur_members.div(voters) + 1
                };

                if voters as u32 >= threshold as u32 {
                    updated_proposal.final = true;
                }

                // Remove old proposal and add updated one
                storage.token_proposals.insert(updated_proposal).emit(
                    context.this_address(),
                    MessageDelivery.CONSTRAINED_ONCHAIN,
                );

                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN);

        // Create nullifier to prevent double voting
        let msg_sender_npk_hash = get_public_keys(context.msg_sender().unwrap()).npk_m.hash();
        let secret = context.request_nsk_app(msg_sender_npk_hash);
        let nullifier = poseidon2_hash([proposal_id, secret]);
        context.push_nullifier(nullifier);
    }

    #[external("private")]
    fn finalize_proposal(proposal_id: Field) {
        storage
            .members
            .replace(|mut note| {
                let msg_sender = context.msg_sender().unwrap();
                // msg_sender is admin
                assert(msg_sender.inner == note.members[0], "Not admin");
                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN);

        // Find the proposal
        let options = NoteGetterOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );

        let notes = storage.token_proposals.pop_notes(options);
        assert(notes.len() == 1, "Proposal not found");
    }

    #[external("private")]
    fn add_member(address: AztecAddress) {
        storage
            .members
            .replace(|mut note| {
                let msg_sender = context.msg_sender().unwrap();
                let mut is_member = false;

                let mut empty_slot_index = 11;

                // Check membership
                for i in 0..10 {
                    if note.members[i] == msg_sender.inner {
                        is_member = true;
                    }
                    if note.members[i] == 0 {
                        if empty_slot_index == 11 {
                            empty_slot_index = i;
                        }
                    }
                }

                assert(is_member, "Not a member");
                assert(empty_slot_index != 11, "Members array is full");

                note.members[empty_slot_index] = address.inner;
                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN)
    }

    #[external("private")]
    fn remove_member(address: AztecAddress) {
        storage
            .members
            .replace(|mut note| {
                let msg_sender = context.msg_sender().unwrap();
                // msg_sender is admin
                assert(msg_sender.inner == note.members[0], "Not admin");

                let mut replaced = false;
                for i in 0..10 {
                    if note.members[i] == address.inner {
                        note.members[i] = 0;
                        replaced = true;
                    }

                    if replaced {
                        note.members[i - 1] = note.members[i];
                        note.members[i] = 0;
                    }
                }
                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN)
    }

    /// @notice Withdraws an amount from the treasury's private balance to the
    ///         recipient's private balance, if the proposal is finalized.
    /// @dev Can only be called by a member for now
    #[external("private")]
    fn withdraw(proposal_id: Field) {
        _authorized(&mut context, storage);

        let options = NoteGetterOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes = storage.token_proposals.pop_notes(options);
        assert(notes.len() == 1, "Proposal not found");

        let retrieved_note = notes.get_unchecked(0);

        assert(retrieved_note.final, "Proposal not finalized");

        let token = retrieved_note.token;
        let recipient = retrieved_note.recipient;

        let treasury_note = storage.treasury.replace(|note| note);

        let treasury = treasury_note.content.note.address;

        if retrieved_note.nft {
            let nft_token_id = retrieved_note.nft_token_id;
            Treasury::at(treasury).withdraw_nft(token, nft_token_id, recipient).call(&mut context);
        } else {
            let amount = retrieved_note.amount;
            Treasury::at(treasury).withdraw(token, amount, recipient).call(&mut context);
        }

        treasury_note.emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN)
    }

    #[contract_library_method]
    fn _authorized(context: &mut PrivateContext, storage: Storage<&mut PrivateContext>) {
        storage
            .members
            .replace(|note| {
                let msg_sender = context.msg_sender().unwrap();
                let mut is_member = false;

                // Check membership
                for i in 0..10 {
                    if note.members[i] == msg_sender.inner {
                        is_member = true;
                    }
                }
                assert(is_member, "Not a member");
                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN);
    }

    #[external("utility")]
    unconstrained fn _view_current_id() -> pub Field {
        let note = storage.last_proposal_id.view_note();
        note.value()
    }

    #[external("utility")]
    unconstrained fn _view_members() -> pub [Field; 10] {
        let note = storage.members.view_note();
        note.members
    }

    #[external("utility")]
    unconstrained fn _view_proposal(proposal_id: Field) -> TokenProposalNote {
        let options = NoteViewerOptions::new().select(
            TokenProposalNote::properties().proposal_id,
            Comparator.EQ,
            proposal_id,
        );
        let notes = storage.token_proposals.view_notes(options);
        assert(notes.len() == 1, "Proposal not found");
        notes.get_unchecked(0)
    }

}
