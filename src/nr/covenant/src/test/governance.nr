use crate::Governance;
use dep::aztec::{oracle::call_private_function, test::helpers::test_environment::TestEnvironment};

// ============================================================================
// INITIALIZATION TESTS
// ============================================================================

// Test: Contract initialization
#[test]
unconstrained fn test_initializer() {
    let mut env = TestEnvironment::new();
    let admin = env.create_light_account();

    let initializer_call_interface = Governance::interface().constructor(admin);
    let contract_addr =
        env.deploy("Governance").with_private_initializer(admin, initializer_call_interface);

    let note_hashes = env.private_context_at(contract_addr, |context| context.note_hashes.len());
    // It shouldn't be 0
    assert_eq(note_hashes, 0);

    let prop = env.call_private(admin, Governance::at(contract_addr).create_proposal());
    let proposal = env.simulate_utility(Governance::at(contract_addr)._view_current_id());

    assert_eq(proposal, 0)
}
