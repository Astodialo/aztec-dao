use dep::aztec::macros::aztec;
pub mod types;

#[aztec]
contract Governance {
    use crate::types::members_note::MembersNote;
    use crate::types::proposal_note::ProposalNote;
    use aztec::context;
    use aztec::keys::getters::get_public_keys;
    use aztec::{
        macros::{functions::{external, initializer}, storage::storage},
        note::{note_getter_options::NoteGetterOptions, note_interface::NoteProperties},
        protocol_types::{address::AztecAddress, hash::poseidon2_hash, traits::Hash},
        state_vars::{private_mutable::PrivateMutable, private_set::PrivateSet},
        utils::comparison::Comparator,
    };

    #[storage]
    struct Storage<Context> {
        members: PrivateMutable<MembersNote, Context>,
        proposals: PrivateSet<ProposalNote, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(admin: AztecAddress, name: str<31>, symbol: str<31>) {
        assert(!admin.is_zero(), "invalid admin");
        let mut members = [0; 10];
        members[0] = admin.inner;
        let members_note = MembersNote::new(context.this_address(), members);
        let _ = storage.members.initialize(members_note);
    }

    #[external("private")]
    fn cast_vote(proposal_id: Field, choice: u32) {
        // Check if caller is a member
        let members_note = storage.members.get_note();
        let msg_sender = context.msg_sender().unwrap();
        let mut is_member = false;

        // Check membership
        for i in 0..10 {
            if members_note.content.note.members[i] == msg_sender.inner {
                is_member = true;
            }
        }
        assert(is_member, "Not a member");

        let _ = storage.members.initialize(members_note.content.note);

        // Find the proposal
        let options = NoteGetterOptions::new()
            .select(ProposalNote::properties().proposal_id, Comparator.EQ, proposal_id)
            .set_limit(1);
        let notes = storage.proposals.get_notes(options);
        assert(notes.len() == 1, "Proposal not found");

        // Create nullifier to prevent double voting
        let msg_sender_npk_hash = get_public_keys(msg_sender).npk_m.hash();
        let secret = context.request_nsk_app(msg_sender_npk_hash);
        let nullifier = poseidon2_hash([proposal_id, secret]);
        context.push_nullifier(nullifier);

        // Update the proposal with the vote
        let retrieved_note = notes.get_unchecked(0);
        let proposal_note = retrieved_note.note;

        // Use the vote method to update tally
        let updated_proposal = proposal_note.vote(choice);

        // Remove old proposal and add updated one
        storage.proposals.remove(retrieved_note);
        let insertion = storage.proposals.insert(updated_proposal);
        insertion.emit(context.msg_sender().unwrap(), 0);
    }

}
