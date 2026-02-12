use aztec::{
    macros::notes::note,
    protocol::traits::{Deserialize, Packable, Serialize},
};

#[derive(Eq, Serialize, Deserialize, Packable)]
#[note]
pub struct MembersNote {
    //pub gov_contract: AztecAddress,
    pub members: [Field; 10],
}


impl MembersNote {
    pub fn new(members: [Field; 10]) -> Self {
        MembersNote { members }
    }
}
