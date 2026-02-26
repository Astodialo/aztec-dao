# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
yarn ccc              # Full build: clean → compile → codegen
yarn test             # All tests (Noir + TypeScript, sandbox auto-managed)
yarn test:nr          # Noir unit tests only
yarn test:js          # TypeScript integration tests only
yarn lint:prettier    # Format code
yarn benchmark        # Performance benchmarking
```

Individual steps: `yarn clean`, `yarn compile`, `yarn codegen`

## Aztec Version

This project uses **Aztec v4.0.0-devnet.2-patch.1**. Noir contracts use dependencies from this tag.

## Architecture

Privacy-preserving DAO governance system with 5 interdependent Noir contracts:

```
┌─────────────────┐
│   GOVERNANCE    │  Central orchestration - proposals, voting, member management
│   (main.nr)     │  Storage: members[10], treasury addr, proposal counters
└────────┬────────┘
         │ calls
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌─────────┐
│TREASURY │ │ MEMBERS │  HATs protocol integration
│ (fund   │ │ (roles/ │  Storage: HatNote per member
│ custody)│ │ registry│
└────┬────┘ └─────────┘
     │ transfers
┌────┴────┐
▼         ▼
┌─────────┐ ┌─────────┐
│  TOKEN  │ │   NFT   │  Private token/NFT transfers
└─────────┘ └─────────┘
```

**Contract Locations:** `src/nr/{governance,treasury,members,token_contract,nft_contract}/`

## Key Patterns

**Storage:** All state is private (PrivateMutable, PrivateSet). Note types: MembersNote, MemberProposalNote, TokenProposalNote, AddressNote, FieldNote.

**Standard Note Imports:** Use packages instead of custom implementations:

```noir
use address_note::AddressNote;
use field_note::FieldNote;
// Construct with struct literals: AddressNote { address: x }, FieldNote { value: x }
```

**Access Control:** `_validate()` library method enforces member/governance-only access.

**Proposal Flow:** create\_\*\_proposal → cast_vote (with nullifier) → finalize → execute (withdraw/add_member)

**Cross-Contract Calls:** `ContractName::at(address).function().call(context)`

**Message Delivery:** Use `MessageDelivery.ONCHAIN_CONSTRAINED` for on-chain finality.

## Noir/Aztec Specifics

- `#[external("private")]` - private function
- `#[external("utility")]` - unconstrained read-only view function
- `#[contract_library_method]` - reusable internal function
- `context.maybe_msg_sender().unwrap()` - get sender in library methods
- `self.msg_sender()` - get sender in contract methods

## Project Structure

- `src/nr/` - Noir smart contracts
- `src/ts/` - TypeScript tests (covenant.test.ts) and utilities (utils.ts)
- `src/artifacts/` - Generated TypeScript bindings (from `yarn codegen`)
- `benchmarks/` - Performance benchmarking
- `target/` - Compiled Noir artifacts

## Commit Style

Uses Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, etc.
