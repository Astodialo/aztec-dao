use dep::aztec::macros::aztec;
pub mod types;

#[aztec]
pub contract Treasury {
    use crate::types::address_note::AddressNote;
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

    use nft::NFT;
    use token::Token;

    #[storage]
    struct Storage<Context> {
        gov: PrivateMutable<AddressNote, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(gov_addr: AztecAddress) {
        //assert(!admin.is_zero(), "invalid admin");
        let members_note = AddressNote::new(gov_addr);

        storage.gov.initialize(members_note).emit(
            context.this_address(),
            MessageDelivery.CONSTRAINED_ONCHAIN,
        );
    }

    #[contract_library_method]
    fn _authorized(context: &mut PrivateContext, storage: Storage<&mut PrivateContext>) {
        storage
            .gov
            .replace(|note| {
                let msg_sender = context.msg_sender().unwrap();
                assert(note.address == msg_sender, "Not authorized");
                note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN);
    }

    /// @notice Withdraws an amount from the treasury's private balance to the
    ///         recipient's private balance, if the proposal is finalized.
    /// @dev Can only be called by a member for now
    #[external("private")]
    fn withdraw(token: AztecAddress, amount: u128, recipient: AztecAddress) {
        _authorized(&mut context, storage);

        Token::at(token)
            .transfer_private_to_private(context.this_address(), recipient, amount, 0)
            .call(&mut context);
    }
    #[external("private")]
    fn withdraw_nft(nft: AztecAddress, token_id: Field, recipient: AztecAddress) {
        _authorized(&mut context, storage);

        NFT::at(nft)
            .transfer_private_to_private(context.this_address(), recipient, token_id, 0)
            .call(&mut context);
    }

    #[external("private")]
    fn update_gov(gov_addr: AztecAddress) {
        _authorized(&mut context, storage);
        storage
            .gov
            .replace(|note| {
                let new_note = AddressNote::new(gov_addr);

                new_note
            })
            .emit(context.this_address(), MessageDelivery.CONSTRAINED_ONCHAIN)
    }

    #[external("utility")]
    unconstrained fn _view_members() -> pub AztecAddress {
        let note = storage.gov.view_note();
        note.address
    }

}
