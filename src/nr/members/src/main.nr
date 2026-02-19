pub mod types;
mod test;

use aztec::macros::aztec;

#[aztec]
pub contract Members {
    // aztec library
    use aztec::{
        authwit::auth::{
            assert_current_call_valid_authwit, assert_current_call_valid_authwit_public,
        },
        context::{PrivateContext, PublicContext},
        macros::{functions::{external, initializer, internal, view}, storage::storage},
        messages::message_delivery::MessageDelivery,
        note::{
            constants::MAX_NOTES_PER_PAGE, note_getter_options::NoteGetterOptions,
            note_interface::NoteProperties, note_viewer_options::NoteViewerOptions,
        },
        protocol::{
            address::AztecAddress,
            constants::CONTRACT_INSTANCE_REGISTRY_CONTRACT_ADDRESS,
            contract_class_id::ContractClassId,
            traits::{FromField, ToField},
        },
        state_vars::{
            Map, Owned, PrivateMutable, PrivateSet, PublicImmutable, PublicMutable,
        },
        utils::comparison::Comparator,
    };
    // compression library
    use compressed_string::FieldCompressedString;
    // contract instance registry
    use contract_instance_registry::ContractInstanceRegistry;
    // note structs
    use address_note::AddressNote;
    use crate::types::hat_note::HatNote;

    /// @param symbol The symbol of the NFT
    /// @param name The name of the NFT
    /// @param private_nfts A map from address to a private set of NFTNotes owned by that address
    /// @param nft_exists A map from token ID to a boolean indicating if the NFT exists
    /// @param public_hatteds A map from token ID to the public owner of the NFT
    /// @param minter The address that can mint
    #[storage]
    struct Storage<Context> {
        gov: Owned<PrivateMutable<AddressNote, Context>, Context>,
        members: Owned<PrivateSet<HatNote, Context>, Context>,
    }

    #[external("private")]
    #[initializer]
    fn constructor(
        gov_addr: AztecAddress,
        eligibility: AztecAddress,
        maxSupply: u32,
        supply: u32,
        lastHatId: u16,
        toggle: AztecAddress,
        config: u16,
        token_id: Field,
        hatted: AztecAddress,
    ) {
        let this_address = self.context.this_address();

        let gov_note = AddressNote { address: gov_addr };

        self.storage.gov.at(this_address).initialize(gov_note).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );

        let member = HatNote::new(
            this_address,
            eligibility,
            maxSupply,
            supply,
            lastHatId,
            toggle,
            config,
            token_id,
            hatted,
        );

        self.storage.members.at(this_address).insert(member).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[contract_library_method]
    fn _validate(context: &mut PrivateContext, storage: Storage<&mut PrivateContext>) {
        let this_address = context.this_address();

        storage
            .gov
            .at(this_address)
            .replace(|note| {
                let msg_sender = context.maybe_msg_sender().unwrap();
                assert(note.address == msg_sender, "Not authorized");
                note
            })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("private")]
    fn is_a_member(member: AztecAddress) {
        let this_address = self.context.this_address();

        _validate(self.context, self.storage);

        let options =
            NoteGetterOptions::new().select(HatNote::properties().hatted, Comparator.EQ, member);

        let member_note = self.storage.members.at(this_address).pop_notes(options);

        assert(member_note.len() == 1, "Not a member");

        let retrieved_note = member_note.get_unchecked(0);

        self.storage.members.at(this_address).insert(retrieved_note).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[external("private")]
    fn add_member(
        eligibility: AztecAddress,
        maxSupply: u32,
        supply: u32,
        lastHatId: u16,
        toggle: AztecAddress,
        config: u16,
        token_id: Field,
        hatted: AztecAddress,
    ) {
        //_validate(&mut context, storage);

        let this_address = self.context.this_address();

        let member = HatNote::new(
            this_address,
            eligibility,
            maxSupply,
            supply,
            lastHatId,
            toggle,
            config,
            token_id,
            hatted,
        );

        self.storage.members.at(this_address).insert(member).deliver(
            MessageDelivery.ONCHAIN_CONSTRAINED,
        );
    }

    #[external("private")]
    fn remove_member(member: AztecAddress) {
        let this_address = self.context.this_address();
        _validate(self.context, self.storage);

        let options =
            NoteGetterOptions::new().select(HatNote::properties().hatted, Comparator.EQ, member);

        let member_note = self.storage.members.at(this_address).pop_notes(options);

        assert(member_note.len() == 1, "Not a member");
    }

    #[external("utility")]
    unconstrained fn _view_gov() -> pub AztecAddress {
        let note = self.storage.gov.at(self.context.this_address()).view_note();
        note.address
    }

    #[external("utility")]
    unconstrained fn _view_member(member: AztecAddress) -> HatNote {
        let options =
            NoteViewerOptions::new().select(HatNote::properties().hatted, Comparator.EQ, member);
        let notes = self.storage.members.at(self.context.this_address()).view_notes(options);
        assert(notes.len() == 1, "Member not found");
        notes.get_unchecked(0)
    }

    #[external("utility")]
    unconstrained fn view_all_members() -> BoundedVec<HatNote, MAX_NOTES_PER_PAGE> {
        let notes = self.storage.members.at(self.context.this_address()).view_notes(
            NoteViewerOptions::new(),
        );
        notes
    }

}
