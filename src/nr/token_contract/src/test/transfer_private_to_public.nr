use crate::test::utils::{self, mint_amount};
use crate::Token;
use aztec::test::helpers::authwit as authwit_cheatcodes;

#[test]
unconstrained fn transfer_private_to_public_on_behalf_of_self() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (mut env, token_contract_address, owner, _) =
        utils::setup_and_mint_to_private_without_minter(false);

    let transfer_private_to_public_amount = mint_amount / (10 as u128);
    env.call_private(
        owner,
        Token::at(token_contract_address).transfer_private_to_public(
            owner,
            owner,
            transfer_private_to_public_amount,
            0,
        ),
    );
    utils::check_private_balance(
        env,
        token_contract_address,
        owner,
        mint_amount - transfer_private_to_public_amount,
    );
    utils::check_public_balance(
        env,
        token_contract_address,
        owner,
        transfer_private_to_public_amount,
    );
}

#[test]
unconstrained fn transfer_private_to_public_on_behalf_of_other() {
    let (mut env, token_contract_address, owner, recipient) =
        utils::setup_and_mint_to_private_without_minter(true);

    let transfer_private_to_public_amount = mint_amount / (10 as u128);
    let transfer_private_to_public_call_interface = Token::at(token_contract_address)
        .transfer_private_to_public(owner, recipient, transfer_private_to_public_amount, 0);
    authwit_cheatcodes::add_private_authwit_from_call(
        env,
        owner,
        recipient,
        transfer_private_to_public_call_interface,
    );
    // transfer_private_to_public tokens
    env.call_private(recipient, transfer_private_to_public_call_interface);
    utils::check_private_balance(
        env,
        token_contract_address,
        owner,
        mint_amount - transfer_private_to_public_amount,
    );
    utils::check_public_balance(
        env,
        token_contract_address,
        recipient,
        transfer_private_to_public_amount,
    );
}

#[test]
unconstrained fn transfer_private_to_public_multiple_notes_recursively() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (mut env, token_contract_address, owner, recipient, minter) =
        utils::setup_with_minter(true);

    let notes_amount = 1000 as u128;
    let notes_count = 12;
    let total_amount = notes_amount * notes_count;
    for _ in 0..notes_count {
        utils::mint_to_private(env, token_contract_address, owner, notes_amount, minter);
    }

    // Transfer tokens
    // Transfer will require 11 notes with change, which requires 2 recursive calls: 2 + 8 + 1
    let transfer_amount = total_amount - notes_amount - (1 as u128);
    let transfer_private_from_call_interface = Token::at(token_contract_address)
        .transfer_private_to_public(owner, recipient, transfer_amount, 0);
    env.call_private(owner, transfer_private_from_call_interface);

    // Check balances
    utils::check_private_balance(
        env,
        token_contract_address,
        owner,
        total_amount - transfer_amount,
    );
    utils::check_public_balance(env, token_contract_address, recipient, transfer_amount);
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn transfer_private_to_public_failure_more_than_balance() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (mut env, token_contract_address, owner, _) =
        utils::setup_and_mint_to_private_without_minter(false);

    let transfer_private_to_public_amount = mint_amount + (1 as u128);
    env.call_private(
        owner,
        Token::at(token_contract_address).transfer_private_to_public(
            owner,
            owner,
            transfer_private_to_public_amount,
            0,
        ),
    );
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn transfer_private_to_public_failure_on_behalf_of_other_more_than_balance() {
    let (mut env, token_contract_address, owner, recipient) =
        utils::setup_and_mint_to_private_without_minter(true);

    let transfer_private_to_public_amount = mint_amount + (1 as u128);
    let transfer_private_to_public_call_interface = Token::at(token_contract_address)
        .transfer_private_to_public(owner, recipient, transfer_private_to_public_amount, 0);
    authwit_cheatcodes::add_private_authwit_from_call(
        env,
        owner,
        recipient,
        transfer_private_to_public_call_interface,
    );
    // transfer_private_to_public tokens
    env.call_private(recipient, transfer_private_to_public_call_interface);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn transfer_private_to_public_failure_on_behalf_of_other_invalid_designated_caller() {
    let (mut env, token_contract_address, owner, recipient) =
        utils::setup_and_mint_to_private_without_minter(true);

    let transfer_private_to_public_amount = mint_amount + (1 as u128);
    let transfer_private_to_public_call_interface = Token::at(token_contract_address)
        .transfer_private_to_public(owner, recipient, transfer_private_to_public_amount, 0);
    authwit_cheatcodes::add_private_authwit_from_call(
        env,
        owner,
        owner,
        transfer_private_to_public_call_interface,
    );
    // transfer_private_to_public tokens
    env.call_private(recipient, transfer_private_to_public_call_interface);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn transfer_private_to_public_failure_on_behalf_of_other_no_approval() {
    let (mut env, token_contract_address, owner, recipient) =
        utils::setup_and_mint_to_private_without_minter(true);

    let transfer_private_to_public_amount = mint_amount + (1 as u128);
    let transfer_private_to_public_call_interface = Token::at(token_contract_address)
        .transfer_private_to_public(owner, recipient, transfer_private_to_public_amount, 0);
    // transfer_private_to_public tokens
    env.call_private(recipient, transfer_private_to_public_call_interface);
}
